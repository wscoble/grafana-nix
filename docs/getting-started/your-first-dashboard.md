# 📊 Your First Dashboard

Let's create your first custom dashboard in Grafana using the Nix stack you just set up. This tutorial assumes you've completed the [Installation Guide](./installation.md).

## What We'll Build

By the end of this guide, you'll have:
- A custom dashboard showing system metrics
- Understanding of how metrics flow through the stack
- Your first Nix configuration modification

## Step 1: Access Grafana

1. **Start the stack** (if not already running):
   ```bash
   nix run "https://flakehub.com/f/wscoble/grafana-nix"
   ```

2. **Open Grafana**: http://localhost:3000
3. **Login**: admin/admin (change password when prompted)

## Step 2: Explore Pre-configured Data Sources

Our Nix stack automatically configures data sources for you:

1. **Navigate** to Configuration → Data Sources
2. **Observe** these pre-configured sources:
   - **Prometheus**: Metrics from http://localhost:9090
   - **Loki**: Logs from http://localhost:3100
   - **Tempo**: Traces from http://localhost:3200

> 💡 **Nix Magic**: These data sources were configured declaratively in our Nix code, not through the UI!

## Step 3: Create Your First Dashboard

### Using the UI (Quick Start)

1. **Click** the "+" icon → Dashboard
2. **Add** a new panel
3. **Select** Prometheus as the data source
4. **Enter** this query:
   ```promql
   up
   ```
5. **Set** the title to "Service Status"
6. **Save** the panel

### The Nix Way (Recommended)

Let's create a dashboard using Nix configuration:

1. **Create** a local copy of the flake:
   ```bash
   git clone https://github.com/wscoble/grafana-nix
   cd grafana-nix
   ```

2. **Create** a dashboard file `dashboards/system-overview.json`:
   ```json
   {
     "dashboard": {
       "title": "System Overview",
       "panels": [
         {
           "title": "CPU Usage",
           "type": "stat",
           "targets": [
             {
               "expr": "100 - (avg(irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
               "legendFormat": "CPU %"
             }
           ]
         },
         {
           "title": "Memory Usage",
           "type": "stat",
           "targets": [
             {
               "expr": "(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100",
               "legendFormat": "Memory %"
             }
           ]
         }
       ]
     }
   }
   ```

3. **Add** the dashboard to your Nix configuration in `flake.nix`:
   ```nix
   {
     # ... existing configuration
     grafana.dashboards = [
       ./dashboards/system-overview.json
     ];
   }
   ```

4. **Rebuild** the stack:
   ```bash
   nix run .
   ```

## Step 4: Understanding the Data Flow

Here's how metrics flow through your Nix-managed stack:

```mermaid
graph LR
    A[Your System] --> B[Node Exporter]
    B --> C[Prometheus]
    C --> D[Grafana]
    D --> E[Your Dashboard]
```

1. **Node Exporter** collects system metrics
2. **Prometheus** scrapes and stores metrics
3. **Grafana** queries Prometheus
4. **Your Dashboard** visualizes the data

## Step 5: Adding Custom Metrics

Let's add a simple custom metric:

### Create a Custom Exporter

1. **Create** `exporters/simple-exporter.py`:
   ```python
   #!/usr/bin/env python3
   import time
   import random
   from prometheus_client import start_http_server, Gauge

   # Create a metric
   RANDOM_VALUE = Gauge('my_random_value', 'A random value for demonstration')

   def generate_metrics():
       while True:
           RANDOM_VALUE.set(random.random() * 100)
           time.sleep(10)

   if __name__ == '__main__':
       start_http_server(8000)
       generate_metrics()
   ```

2. **Add** it to your Nix configuration:
   ```nix
   {
     # Add to your flake.nix
     prometheus.scrapeConfigs = [
       {
         job_name = "custom-exporter";
         static_configs = [
           { targets = [ "localhost:8000" ]; }
         ];
       }
     ];
   }
   ```

3. **Run** your custom exporter:
   ```bash
   nix develop
   python exporters/simple-exporter.py &
   ```

4. **Rebuild** the stack to pick up the new scrape config:
   ```bash
   nix run .
   ```

### Create a Panel for Your Metric

1. **Open** Grafana
2. **Edit** your dashboard
3. **Add** a new panel with query: `my_random_value`
4. **Watch** your custom metric appear!

## Step 6: Dashboard as Code

This is where Nix truly shines. Your entire dashboard is now:
- **Version controlled**: Track changes with git
- **Reproducible**: Same dashboard everywhere
- **Composable**: Easy to share and extend

### Advanced Dashboard Configuration

```nix
# In your flake.nix
{
  grafana = {
    dashboards = [
      {
        title = "Production Overview";
        panels = [
          {
            title = "Request Rate";
            type = "graph";
            targets = [{
              expr = "rate(http_requests_total[5m])";
              legendFormat = "{{method}} {{status}}";
            }];
          }
          {
            title = "Error Rate";
            type = "stat";
            targets = [{
              expr = "rate(http_requests_total{status=~\"5..\"}[5m])";
            }];
            alert = {
              condition = "IS ABOVE 0.01";
              frequency = "10s";
            };
          }
        ];
      }
    ];
  };
}
```

## Step 7: Next Steps

🎉 **Congratulations!** You've created your first dashboard with Nix and Grafana.

### Immediate next steps:
- **[Configure Alerts](./alerts.md)** - Get notified when things go wrong
- **[Add Log Visualization](./logs.md)** - Explore Loki integration
- **[Distributed Tracing](./tracing.md)** - Understand request flows

### Advanced topics:
- **[Custom Prometheus Rules](../advanced/prometheus-rules.md)**
- **[Multi-environment Deployment](../advanced/multi-env.md)**
- **[Scaling Your Stack](../advanced/scaling.md)**

## Understanding What Makes This Special

Traditional dashboard creation involves:
1. Manual UI clicks
2. Configuration drift between environments
3. Difficult backup and restoration
4. No version control

**With Nix**, your dashboards are:
- **Declarative**: Defined in code
- **Reproducible**: Same everywhere
- **Version controlled**: Full git history
- **Composable**: Easy to share and modify

This is infrastructure as code taken to its logical conclusion!

## Troubleshooting

### Dashboard doesn't appear
- Check Grafana logs: `journalctl -f -u grafana`
- Verify JSON syntax: `nix flake check`

### Metrics not showing
- Check Prometheus targets: http://localhost:9090/targets
- Verify scrape config: `cat /nix/store/.../prometheus.yml`

### Custom exporter not working
- Check if port 8000 is available: `netstat -tulpn | grep 8000`
- Verify Python dependencies are available

---

**Need help?** [Join our discussions](https://github.com/wscoble/grafana-nix/discussions) or [open an issue](https://github.com/wscoble/grafana-nix/issues).