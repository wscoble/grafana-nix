{ lib, pkgs }:

rec {
  # Build Kubernetes manifests
  buildManifests = { namespace ? "grafana-stack", components, ... }@args:
    let
      # Extract component configs
      grafanaConfig = components.grafanaConfig;
      prometheusConfig = components.prometheusConfig;
      lokiConfig = components.lokiConfig;
      tempoConfig = components.tempoConfig;

      # Generate manifests
      manifests = {
        # Namespace
        namespace = {
          apiVersion = "v1";
          kind = "Namespace";
          metadata = {
            name = namespace;
          };
        };

        # Grafana
        grafana-deployment = {
          apiVersion = "apps/v1";
          kind = "Deployment";
          metadata = {
            name = "grafana";
            namespace = namespace;
          };
          spec = {
            replicas = 1;
            selector.matchLabels = { app = "grafana"; };
            template = {
              metadata.labels = { app = "grafana"; };
              spec = {
                containers = [{
                  name = "grafana";
                  image = "grafana-nix/grafana:latest";
                  ports = [{ containerPort = grafanaConfig.port; }];
                  env = [
                    { name = "GF_SECURITY_ADMIN_PASSWORD"; value = grafanaConfig.adminPassword; }
                  ];
                  volumeMounts = [{
                    name = "grafana-storage";
                    mountPath = "/var/lib/grafana";
                  }];
                }];
                volumes = [{
                  name = "grafana-storage";
                  emptyDir = { };
                }];
              };
            };
          };
        };

        grafana-service = {
          apiVersion = "v1";
          kind = "Service";
          metadata = {
            name = "grafana";
            namespace = namespace;
          };
          spec = {
            selector = { app = "grafana"; };
            ports = [{
              port = grafanaConfig.port;
              targetPort = grafanaConfig.port;
            }];
            type = "ClusterIP";
          };
        };

        # Prometheus
        prometheus-deployment = {
          apiVersion = "apps/v1";
          kind = "Deployment";
          metadata = {
            name = "prometheus";
            namespace = namespace;
          };
          spec = {
            replicas = 1;
            selector.matchLabels = { app = "prometheus"; };
            template = {
              metadata.labels = { app = "prometheus"; };
              spec = {
                containers = [{
                  name = "prometheus";
                  image = "grafana-nix/prometheus:latest";
                  ports = [{ containerPort = prometheusConfig.port; }];
                  args = [
                    "--config.file=/etc/prometheus/prometheus.yml"
                    "--storage.tsdb.path=/prometheus"
                    "--storage.tsdb.retention.time=${prometheusConfig.retention}"
                    "--web.listen-address=:${toString prometheusConfig.port}"
                  ];
                  volumeMounts = [{
                    name = "prometheus-storage";
                    mountPath = "/prometheus";
                  }];
                }];
                volumes = [{
                  name = "prometheus-storage";
                  emptyDir = { };
                }];
              };
            };
          };
        };

        prometheus-service = {
          apiVersion = "v1";
          kind = "Service";
          metadata = {
            name = "prometheus";
            namespace = namespace;
          };
          spec = {
            selector = { app = "prometheus"; };
            ports = [{
              port = prometheusConfig.port;
              targetPort = prometheusConfig.port;
            }];
            type = "ClusterIP";
          };
        };

        # Loki
        loki-deployment = {
          apiVersion = "apps/v1";
          kind = "Deployment";
          metadata = {
            name = "loki";
            namespace = namespace;
          };
          spec = {
            replicas = 1;
            selector.matchLabels = { app = "loki"; };
            template = {
              metadata.labels = { app = "loki"; };
              spec = {
                containers = [{
                  name = "loki";
                  image = "grafana-nix/loki:latest";
                  ports = [{ containerPort = lokiConfig.port; }];
                  volumeMounts = [{
                    name = "loki-storage";
                    mountPath = "/tmp/loki";
                  }];
                }];
                volumes = [{
                  name = "loki-storage";
                  emptyDir = { };
                }];
              };
            };
          };
        };

        loki-service = {
          apiVersion = "v1";
          kind = "Service";
          metadata = {
            name = "loki";
            namespace = namespace;
          };
          spec = {
            selector = { app = "loki"; };
            ports = [{
              port = lokiConfig.port;
              targetPort = lokiConfig.port;
            }];
            type = "ClusterIP";
          };
        };

        # Tempo
        tempo-deployment = {
          apiVersion = "apps/v1";
          kind = "Deployment";
          metadata = {
            name = "tempo";
            namespace = namespace;
          };
          spec = {
            replicas = 1;
            selector.matchLabels = { app = "tempo"; };
            template = {
              metadata.labels = { app = "tempo"; };
              spec = {
                containers = [{
                  name = "tempo";
                  image = "grafana-nix/tempo:latest";
                  ports = [
                    { containerPort = tempoConfig.port; }
                    { containerPort = 4317; } # OTLP gRPC
                    { containerPort = 4318; } # OTLP HTTP
                    { containerPort = 14268; } # Jaeger HTTP
                  ];
                  volumeMounts = [{
                    name = "tempo-storage";
                    mountPath = "/tmp/tempo";
                  }];
                }];
                volumes = [{
                  name = "tempo-storage";
                  emptyDir = { };
                }];
              };
            };
          };
        };

        tempo-service = {
          apiVersion = "v1";
          kind = "Service";
          metadata = {
            name = "tempo";
            namespace = namespace;
          };
          spec = {
            selector = { app = "tempo"; };
            ports = [
              {
                name = "http";
                port = tempoConfig.port;
                targetPort = tempoConfig.port;
              }
              {
                name = "otlp-grpc";
                port = 4317;
                targetPort = 4317;
              }
              {
                name = "otlp-http";
                port = 4318;
                targetPort = 4318;
              }
              {
                name = "jaeger-http";
                port = 14268;
                targetPort = 14268;
              }
            ];
            type = "ClusterIP";
          };
        };

        # Ingress (optional)
        grafana-ingress = {
          apiVersion = "networking.k8s.io/v1";
          kind = "Ingress";
          metadata = {
            name = "grafana";
            namespace = namespace;
            annotations = {
              "nginx.ingress.kubernetes.io/rewrite-target" = "/";
            };
          };
          spec = {
            rules = [{
              host = "grafana.local";
              http.paths = [{
                path = "/";
                pathType = "Prefix";
                backend.service = {
                  name = "grafana";
                  port.number = grafanaConfig.port;
                };
              }];
            }];
          };
        };
      };

      # Convert manifests to YAML files
      manifestFiles = lib.mapAttrs
        (name: manifest: pkgs.writeText "${name}.yaml" (lib.generators.toYAML { } manifest))
        manifests;

    in
    pkgs.runCommand "kubernetes-manifests" { } ''
      mkdir -p $out/manifests $out/bin

      # Copy manifest files
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList
        (name: file: "cp ${file} $out/manifests/${name}.yaml")
        manifestFiles)}

      # Create combined manifest
      cat $out/manifests/*.yaml > $out/all-manifests.yaml

      # Create helper scripts
      cat > $out/bin/k8s-apply <<'EOF'
      #!/usr/bin/env bash
      set -euo pipefail

      MANIFESTS_DIR="$(dirname "$0")/../manifests"

      echo "🚀 Deploying Grafana Stack to Kubernetes..."

      # Apply manifests
      ${pkgs.kubectl}/bin/kubectl apply -f "$MANIFESTS_DIR/"

      echo ""
      echo "✅ Deployment complete!"
      echo ""
      echo "📋 Check status:"
      echo "  kubectl get pods -n ${namespace}"
      echo "  kubectl get services -n ${namespace}"
      echo ""
      echo "🔗 Access (after port-forward):"
      echo "  kubectl port-forward -n ${namespace} svc/grafana ${toString grafanaConfig.port}:${toString grafanaConfig.port}"
      echo "  kubectl port-forward -n ${namespace} svc/prometheus ${toString prometheusConfig.port}:${toString prometheusConfig.port}"
      EOF

      cat > $out/bin/k8s-delete <<'EOF'
      #!/usr/bin/env bash
      MANIFESTS_DIR="$(dirname "$0")/../manifests"
      echo "🗑️  Removing Grafana Stack from Kubernetes..."
      ${pkgs.kubectl}/bin/kubectl delete -f "$MANIFESTS_DIR/" || true
      EOF

      cat > $out/bin/k8s-status <<'EOF'
      #!/usr/bin/env bash
      echo "📊 Grafana Stack Status:"
      ${pkgs.kubectl}/bin/kubectl get all -n ${namespace}
      EOF

      chmod +x $out/bin/*
    '';

  # Build Helm chart
  buildHelmChart = { name, version ? "1.0.0", description, values ? { }, ... }@args:
    pkgs.runCommand "helm-chart-${name}" { } ''
      mkdir -p $out/${name}/{templates,charts}

      # Chart.yaml
      cat > $out/${name}/Chart.yaml <<EOF
      apiVersion: v2
      name: ${name}
      description: ${description}
      version: ${version}
      appVersion: ${version}
      EOF

      # values.yaml
      cat > $out/${name}/values.yaml <<EOF
      ${lib.generators.toYAML { } values}
      EOF

      # Templates would go in templates/
      echo "# Helm templates go here" > $out/${name}/templates/.gitkeep
    '';
}
