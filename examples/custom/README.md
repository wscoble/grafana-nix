# ⚙️ Custom Configuration Example

This example demonstrates how to customize every aspect of the Grafana stack using Nix expressions.

## Features

- **Custom passwords and themes**
- **Multiple data sources**
- **Custom dashboards**
- **Alert rules**
- **Enhanced monitoring** with node-exporter
- **Development tools** for testing

## Quick Start

```bash
cd examples/custom
nix run .
```

## Configuration Highlights

### Grafana Customization

```nix
grafana = {
  adminPassword = "secure-password-change-me";
  theme = "dark";
  datasources = [ /* multiple sources */ ];
  dashboards = [ ./dashboards/system-overview.json ];
};
```

### Prometheus with Custom Scraping

```nix
prometheus = {
  retention = "30d";
  scrapeConfigs = [
    {
      job_name = "node-exporter";
      static_configs = [{ targets = [ "localhost:9100" ]; }];
    }
  ];
  alertingRules = [ ./alerts/critical.yml ];
};
```

### Loki Log Aggregation

```nix
loki = {
  retentionPeriod = "744h"; # 31 days
  schemaConfig = { /* custom schema */ };
};
```

### Tempo Distributed Tracing

```nix
tempo = {
  retentionDuration = "240h"; # 10 days
  distributor.receivers = {
    jaeger = { /* Jaeger support */ };
    otlp = { /* OpenTelemetry support */ };
  };
};
```

## Creating Custom Dashboards

1. **Create dashboard JSON**:
   ```bash
   mkdir dashboards
   # Export from Grafana UI or create manually
   ```

2. **Reference in flake.nix**:
   ```nix
   grafana.dashboards = [ ./dashboards/my-dashboard.json ];
   ```

3. **Rebuild and restart**:
   ```bash
   nix run .
   ```

## Adding Alert Rules

1. **Create Prometheus alert rules**:
   ```yaml
   # alerts/critical.yml
   groups:
     - name: critical
       rules:
         - alert: HighCPUUsage
           expr: cpu_usage > 80
           for: 5m
   ```

2. **Reference in configuration**:
   ```nix
   prometheus.alertingRules = [ ./alerts/critical.yml ];
   ```

## Development Workflow

```bash
# Enter enhanced development shell
nix develop

# Available tools:
prometheus --help        # Prometheus CLI
grafana-cli --help       # Grafana management
node_exporter           # System metrics
k6 run test.js          # Load testing
curl | jq               # API testing
```

## Testing Your Configuration

### Health Checks

```bash
# Check all services are up
curl http://localhost:9090/-/healthy    # Prometheus
curl http://localhost:3100/ready        # Loki
curl http://localhost:3200/ready        # Tempo

# Check Grafana datasources
curl -u admin:secure-password-change-me \
  http://localhost:3000/api/datasources
```

### Sample Queries

```bash
# Prometheus metrics
curl "http://localhost:9090/api/v1/query?query=up"

# Loki logs (if any)
curl "http://localhost:3100/loki/api/v1/query?query={job=\"grafana\"}"
```

## Next Steps

- **Deploy with [Docker](../docker/)**
- **Scale with [Kubernetes](../kubernetes/)**
- **Add custom exporters** for your applications
- **Create alerting channels** (Slack, email, etc.)

## Configuration Reference

See the [module documentation](../../docs/modules/) for all available options:

- [Grafana options](../../docs/modules/grafana.md)
- [Prometheus options](../../docs/modules/prometheus.md)
- [Loki options](../../docs/modules/loki.md)
- [Tempo options](../../docs/modules/tempo.md)