# 🚀 Basic Grafana Stack Example

This example shows the simplest way to use the Grafana Nix Stack with default settings.

## Quick Start

```bash
# Clone this example
git clone https://github.com/wscoble/grafana-nix
cd grafana-nix/examples/basic

# Run the stack
nix run .
```

## What You Get

- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **Loki**: http://localhost:3100
- **Tempo**: http://localhost:3200
- **Alloy**: http://localhost:12345

## Development

```bash
# Enter development shell
nix develop

# Individual components
nix build .#grafana
nix build .#prometheus
```

## Next Steps

- Try the [Custom Configuration Example](../custom/)
- Deploy with [Docker Example](../docker/)
- Scale with [Kubernetes Example](../kubernetes/)