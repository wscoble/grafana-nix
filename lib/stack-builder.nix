{ lib, pkgs, generators, docker, kubernetes }:

{
  # Grafana configuration
  grafana ? { }
, # Prometheus configuration
  prometheus ? { }
, # Loki configuration
  loki ? { }
, # Tempo configuration
  tempo ? { }
, # Alloy configuration
  alloy ? { }
, # Global configuration
  global ? { }
, ...
}@args:

let
  # Environment variable support for Flox integration
  envConfig =
    let
      getEnvOr = var: default:
        let val = builtins.getEnv var;
        in if val == "" then default else val;

      getEnvPortOr = var: default:
        let val = builtins.getEnv var;
        in if val == "" then default else builtins.fromJSON val;
    in
    {
      grafana = {
        port = getEnvPortOr "GRAFANA_PORT" 3000;
        adminPassword = getEnvOr "GRAFANA_ADMIN_PASSWORD" "admin";
        dataDir = getEnvOr "GRAFANA_DATA_DIR" "/tmp/grafana";
      };
      prometheus = {
        port = getEnvPortOr "PROMETHEUS_PORT" 9090;
        retention = getEnvOr "PROMETHEUS_RETENTION" "30d";
        dataDir = getEnvOr "PROMETHEUS_DATA_DIR" "/tmp/prometheus";
      };
      loki = {
        port = getEnvPortOr "LOKI_PORT" 3100;
        retentionPeriod = getEnvOr "LOKI_RETENTION" "744h";
        dataDir = getEnvOr "LOKI_DATA_DIR" "/tmp/loki";
      };
      tempo = {
        port = getEnvPortOr "TEMPO_PORT" 3200;
        retentionDuration = getEnvOr "TEMPO_RETENTION" "240h";
        dataDir = getEnvOr "TEMPO_DATA_DIR" "/tmp/tempo";
      };
      alloy = {
        port = getEnvPortOr "ALLOY_PORT" 12345;
        scrapeInterval = getEnvOr "ALLOY_SCRAPE_INTERVAL" "15s";
        dataDir = getEnvOr "ALLOY_DATA_DIR" "/tmp/alloy";
      };
    };

  # Default configurations with opinionated settings
  defaultGrafana = {
    port = envConfig.grafana.port;
    adminPassword = envConfig.grafana.adminPassword;
    theme = "dark";
    datasources = [
      {
        name = "Prometheus";
        type = "prometheus";
        url = "http://localhost:${toString envConfig.prometheus.port}";
        isDefault = true;
      }
      {
        name = "Loki";
        type = "loki";
        url = "http://localhost:${toString envConfig.loki.port}";
      }
      {
        name = "Tempo";
        type = "tempo";
        url = "http://localhost:${toString envConfig.tempo.port}";
      }
    ];
  };

  defaultPrometheus = {
    port = envConfig.prometheus.port;
    retention = envConfig.prometheus.retention;
    scrapeConfigs = [
      {
        job_name = "prometheus";
        static_configs = [{ targets = [ "localhost:${toString envConfig.prometheus.port}" ]; }];
        metrics_path = "/metrics";
      }
      {
        job_name = "grafana";
        static_configs = [{ targets = [ "localhost:${toString envConfig.grafana.port}" ]; }];
        metrics_path = "/metrics";
      }
      {
        job_name = "alloy";
        static_configs = [{ targets = [ "localhost:${toString envConfig.alloy.port}" ]; }];
        metrics_path = "/metrics";
      }
    ];
  };

  defaultLoki = {
    port = envConfig.loki.port;
    retentionPeriod = envConfig.loki.retentionPeriod;
  };

  defaultTempo = {
    port = envConfig.tempo.port;
    retentionDuration = envConfig.tempo.retentionDuration;
  };

  defaultAlloy = {
    port = envConfig.alloy.port;
    scrapeInterval = envConfig.alloy.scrapeInterval;
    prometheusUrl = "http://localhost:${toString envConfig.prometheus.port}";
    lokiUrl = "http://localhost:${toString envConfig.loki.port}";
    tempoUrl = "http://localhost:${toString envConfig.tempo.port}";
    logPaths = [ "/var/log/*.log" "/tmp/grafana/*.log" "/tmp/prometheus/*.log" ];
  };

  # Merge user config with defaults
  grafanaConfig = lib.recursiveUpdate defaultGrafana grafana;
  prometheusConfig = lib.recursiveUpdate defaultPrometheus prometheus;
  lokiConfig = lib.recursiveUpdate defaultLoki loki;
  tempoConfig = lib.recursiveUpdate defaultTempo tempo;
  alloyConfig = lib.recursiveUpdate defaultAlloy (args.alloy or { });

  # Generate configurations
  grafanaCfg = generators.grafanaConfig grafanaConfig;
  prometheusCfg = generators.prometheusConfig prometheusConfig;
  lokiCfg = generators.lokiConfig lokiConfig;
  tempoCfg = generators.tempoConfig tempoConfig;
  alloyCfg = generators.alloyConfig alloyConfig;

  # Individual packages
  grafanaPackage = pkgs.grafana.overrideAttrs (old: {
    buildInputs = (old.buildInputs or [ ]) ++ grafanaConfig.plugins or [ ];
  });

  prometheusPackage = pkgs.prometheus;
  lokiPackage = pkgs.grafana-loki;
  tempoPackage = pkgs.tempo;
  alloyPackage = pkgs.grafana-alloy;

  # Runtime directories
  runtimeDir = pkgs.runCommand "grafana-stack-runtime" { } ''
    mkdir -p $out/{grafana,prometheus,loki,tempo,alloy,bin}

    # Grafana
    cp ${grafanaCfg.configFile} $out/grafana/grafana.ini
    ${lib.optionalString (grafanaCfg.datasources != [ ] || grafanaCfg.dashboards != [ ]) ''
      cp -r ${grafanaCfg.provisioningDir}/* $out/grafana/
    ''}

    # Prometheus
    cp ${prometheusCfg.configFile} $out/prometheus/prometheus.yml

    # Loki
    cp ${lokiCfg.configFile} $out/loki/loki.yml

    # Tempo
    cp ${tempoCfg.configFile} $out/tempo/tempo.yml

    # Alloy
    cp ${alloyCfg.configFile} $out/alloy/alloy.alloy

    # Create launcher script
    cat > $out/bin/grafana-stack <<'EOF'
    #!/usr/bin/env bash
    set -euo pipefail

    RUNTIME_DIR="$1"
    # Support Flox environment variables for data directory
    DATA_DIR="''${2:-''${GRAFANA_DATA_DIR:-''${OBSERVABILITY_DATA_DIR:-$PWD/data}}}"

    # Create data directories
    mkdir -p "$DATA_DIR"/{grafana,prometheus,loki,tempo,alloy}

    # Function to check if port is available (cross-platform)
    check_port() {
      local port=$1
      local service=$2
      local port_in_use=false

      # Try different port checking methods in order of preference
      if command -v ss >/dev/null 2>&1; then
        # Modern Linux systems use ss
        if ss -tuln 2>/dev/null | grep -q ":$port "; then
          port_in_use=true
        fi
      elif command -v netstat >/dev/null 2>&1; then
        # Fallback to netstat (macOS, older Linux)
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
          port_in_use=true
        fi
      elif command -v lsof >/dev/null 2>&1; then
        # Alternative fallback using lsof
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
          port_in_use=true
        fi
      else
        # Last resort: try to bind to the port
        if ! timeout 1 bash -c "</dev/tcp/localhost/$port" 2>/dev/null; then
          # Port appears to be free (connection failed)
          return 0
        else
          port_in_use=true
        fi
      fi

      if [ "$port_in_use" = true ]; then
        echo "❌ Port $port is already in use (needed for $service)"
        echo "💡 Try: killall $service || pkill -f $service"
        echo "💡 Or set environment variable: ''${service^^}_PORT=\$((port + 1000))"
        return 1
      fi
      return 0
    }

    echo "🚀 Starting Grafana Stack..."
    echo "📁 Data directory: $DATA_DIR"
    echo "⚙️  Runtime config: $RUNTIME_DIR"
    echo ""
    echo "💡 To clean up data later: rm -rf \"$DATA_DIR\""

    # Use environment variables for ports (Flox-compatible)
    PROMETHEUS_PORT=''${PROMETHEUS_PORT:-${toString prometheusConfig.port}}
    LOKI_PORT=''${LOKI_PORT:-${toString lokiConfig.port}}
    TEMPO_PORT=''${TEMPO_PORT:-${toString tempoConfig.port}}
    ALLOY_PORT=''${ALLOY_PORT:-${toString alloyConfig.port}}
    GRAFANA_PORT=''${GRAFANA_PORT:-${toString grafanaConfig.port}}

    # Check for port conflicts
    echo "🔍 Checking ports..."
    check_port $PROMETHEUS_PORT "prometheus" || exit 1
    check_port $LOKI_PORT "loki" || exit 1
    check_port $TEMPO_PORT "tempo" || exit 1
    check_port $ALLOY_PORT "alloy" || exit 1
    check_port $GRAFANA_PORT "grafana" || exit 1

    # Start services in background

    echo "Starting Prometheus on port $PROMETHEUS_PORT..."
    ${prometheusPackage}/bin/prometheus \
      --config.file="$RUNTIME_DIR/prometheus/prometheus.yml" \
      --storage.tsdb.path="$DATA_DIR/prometheus" \
      --web.listen-address=":$PROMETHEUS_PORT" \
      --storage.tsdb.retention.time=${prometheusCfg.retention} &
    PROMETHEUS_PID=$!

    echo "Starting Loki on port $LOKI_PORT..."
    ${lokiPackage}/bin/loki \
      -config.file="$RUNTIME_DIR/loki/loki.yml" &
    LOKI_PID=$!

    echo "Starting Tempo on port $TEMPO_PORT..."
    ${tempoPackage}/bin/tempo \
      -config.file="$RUNTIME_DIR/tempo/tempo.yml" &
    TEMPO_PID=$!

    echo "Starting Alloy on port $ALLOY_PORT..."
    ${alloyPackage}/bin/alloy run \
      --config.file="$RUNTIME_DIR/alloy/alloy.alloy" \
      --server.http.listen-addr="0.0.0.0:$ALLOY_PORT" \
      --storage.path="$DATA_DIR/alloy" &
    ALLOY_PID=$!

    echo "Starting Grafana on port $GRAFANA_PORT..."
    ${grafanaPackage}/bin/grafana-server \
      --config="$RUNTIME_DIR/grafana/grafana.ini" \
      --homepath="${grafanaPackage}/share/grafana" \
      ${lib.optionalString (grafanaCfg.datasources != [ ] || grafanaCfg.dashboards != [ ]) ''
        --paths-provisioning="$RUNTIME_DIR/grafana" \
      ''} &
    GRAFANA_PID=$!

    # Wait for services to start
    sleep 5

    echo ""
    echo "✅ Grafana Stack is running!"
    echo ""
    echo "📊 Access points:"
    echo "  Grafana:    http://localhost:$GRAFANA_PORT (admin/${grafanaConfig.adminPassword})"
    echo "  Prometheus: http://localhost:$PROMETHEUS_PORT"
    echo "  Loki:       http://localhost:$LOKI_PORT"
    echo "  Tempo:      http://localhost:$TEMPO_PORT"
    echo "  Alloy:      http://localhost:$ALLOY_PORT"
    echo ""
    echo "🛑 Press Ctrl+C to stop all services"

    # Cleanup on exit
    cleanup() {
      echo ""
      echo "🛑 Stopping services..."
      kill $PROMETHEUS_PID $LOKI_PID $TEMPO_PID $ALLOY_PID $GRAFANA_PID 2>/dev/null || true
      wait
      echo "✅ All services stopped"
    }
    trap cleanup EXIT INT TERM

    # Wait for all background processes
    wait
    EOF

    chmod +x $out/bin/grafana-stack
  '';

  # Main stack package
  stackPackage = pkgs.runCommand "grafana-stack"
    {
      meta = {
        description = "Complete Grafana observability stack";
        homepage = "https://github.com/wscoble/grafana-nix";
      };
    } ''
    mkdir -p $out/bin

    # Create wrapper script
    cat > $out/bin/grafana-stack <<'EOF'
    #!/usr/bin/env bash
    exec ${runtimeDir}/bin/grafana-stack ${runtimeDir} "''${@}"
    EOF

    chmod +x $out/bin/grafana-stack

    # Symlink individual components
    ln -s ${grafanaPackage}/bin/grafana-server $out/bin/
    ln -s ${prometheusPackage}/bin/prometheus $out/bin/
    ln -s ${lokiPackage}/bin/loki $out/bin/
    ln -s ${tempoPackage}/bin/tempo $out/bin/
    ln -s ${alloyPackage}/bin/alloy $out/bin/
  '';

in
{
  # Main outputs
  grafana-stack = stackPackage;

  # Individual components
  grafana = grafanaPackage;
  prometheus = prometheusPackage;
  loki = lokiPackage;
  tempo = tempoPackage;
  alloy = alloyPackage;

  # Docker images
  grafana-image = docker.buildImage {
    name = "grafana-nix/grafana";
    tag = "latest";
    copyToRoot = [ grafanaPackage runtimeDir ];
    config = {
      Cmd = [ "${grafanaPackage}/bin/grafana-server" "--config" "${runtimeDir}/grafana/grafana.ini" ];
      ExposedPorts = { "${toString grafanaConfig.port}/tcp" = { }; };
    };
  };

  prometheus-image = docker.buildImage {
    name = "grafana-nix/prometheus";
    tag = "latest";
    copyToRoot = [ prometheusPackage runtimeDir ];
    config = {
      Cmd = [ "${prometheusPackage}/bin/prometheus" "--config.file" "${runtimeDir}/prometheus/prometheus.yml" ];
      ExposedPorts = { "${toString prometheusConfig.port}/tcp" = { }; };
    };
  };

  loki-image = docker.buildImage {
    name = "grafana-nix/loki";
    tag = "latest";
    copyToRoot = [ lokiPackage runtimeDir ];
    config = {
      Cmd = [ "${lokiPackage}/bin/loki" "-config.file" "${runtimeDir}/loki/loki.yml" ];
      ExposedPorts = { "${toString lokiConfig.port}/tcp" = { }; };
    };
  };

  tempo-image = docker.buildImage {
    name = "grafana-nix/tempo";
    tag = "latest";
    copyToRoot = [ tempoPackage runtimeDir ];
    config = {
      Cmd = [ "${tempoPackage}/bin/tempo" "-config.file" "${runtimeDir}/tempo/tempo.yml" ];
      ExposedPorts = { "${toString tempoConfig.port}/tcp" = { }; };
    };
  };

  alloy-image = docker.buildImage {
    name = "grafana-nix/alloy";
    tag = "latest";
    copyToRoot = [ alloyPackage runtimeDir ];
    config = {
      Cmd = [ "${alloyPackage}/bin/alloy" "run" "--config.file" "${runtimeDir}/alloy/alloy.alloy" ];
      ExposedPorts = { "${toString alloyConfig.port}/tcp" = { }; };
    };
  };

  # Docker Compose
  docker-compose = docker.buildCompose {
    version = "3.8";
    services = {
      grafana = {
        image = "grafana-nix/grafana:latest";
        ports = [ "${toString grafanaConfig.port}:${toString grafanaConfig.port}" ];
        depends_on = [ "prometheus" "loki" "tempo" ];
      };
      prometheus = {
        image = "grafana-nix/prometheus:latest";
        ports = [ "${toString prometheusConfig.port}:${toString prometheusConfig.port}" ];
      };
      loki = {
        image = "grafana-nix/loki:latest";
        ports = [ "${toString lokiConfig.port}:${toString lokiConfig.port}" ];
      };
      tempo = {
        image = "grafana-nix/tempo:latest";
        ports = [ "${toString tempoConfig.port}:${toString tempoConfig.port}" ];
      };
      alloy = {
        image = "grafana-nix/alloy:latest";
        ports = [ "${toString alloyConfig.port}:${toString alloyConfig.port}" ];
        depends_on = [ "prometheus" "loki" "tempo" ];
      };
    };
  };

  # Kubernetes manifests
  kubernetes-manifests = kubernetes.buildManifests {
    namespace = "grafana-stack";
    components = {
      inherit grafanaConfig prometheusConfig lokiConfig tempoConfig alloyConfig;
    };
  };

  # Configuration for inspection
  config = {
    inherit grafanaConfig prometheusConfig lokiConfig tempoConfig alloyConfig;
    runtime = runtimeDir;
  };
}
