# 🦊 Observability in Your Development Environment

Add instant observability to any development project with Flox. Monitor your application's metrics, logs, and traces while you develop - no complex setup required.

## 🚀 Quick Start

### Add to Existing Project

```bash
# In your project directory
flox install github:wscoble/grafana-nix

# Start observability stack
flox services start observability

# Your app now has full observability at:
# - Grafana: http://localhost:3000 (admin/dev)
# - Prometheus: http://localhost:9090
# - Alloy: http://localhost:12345
```

### New Project with Observability

```bash
# Create environment with observability built-in
mkdir my-project && cd my-project
nix flake init -t github:wscoble/grafana-nix#flox
flox activate

# Start developing with observability
flox services start observability
```

## 🔧 Service Configuration

The manifest defines several services you can control:

### Complete Stack Service

```toml
[services.grafana-nix]
command = "grafana-stack"
vars.GRAFANA_DATA_DIR = "$FLOX_ENV_PROJECT_DIR/data"
is-daemon = true
shutdown.command = "pkill -f grafana-stack"
```

**Usage:**
```bash
flox services start grafana-nix    # Start complete stack
flox services stop grafana-nix     # Stop complete stack
flox services status               # Check status
```

### Individual Services

For more granular control, you can start individual components:

```bash
flox services start prometheus     # Prometheus only
flox services start grafana        # Grafana only
```

## ⚙️ Customization

### Environment Variables

Customize the stack behavior through environment variables:

```toml
[vars]
GRAFANA_ADMIN_PASSWORD = "your-secure-password"
PROMETHEUS_RETENTION = "90d"
LOKI_RETENTION = "2160h"  # 90 days
```

### Service Configuration

Override default service behavior:

```toml
[services.grafana-nix]
command = "grafana-stack --data-dir=$OBSERVABILITY_DATA_DIR"
vars.CUSTOM_CONFIG = "value"
```

### Custom Installation

Install specific versions or configurations:

```toml
[install]
# Production-ready stack
grafana-production.flake = "github:wscoble/grafana-nix#production-stack"

# Development stack with additional tools
grafana-dev.flake = "github:wscoble/grafana-nix#dev-stack"

# Minimal stack for testing
grafana-minimal.flake = "github:wscoble/grafana-nix#minimal-stack"
```

## 📊 Usage Patterns

### Development Workflow

```bash
# 1. Activate environment
flox activate

# 2. Start services
flox services start grafana-nix

# 3. Develop your application
# Services are automatically available at standard ports

# 4. Stop services when done
flox services stop grafana-nix
```

### Team Collaboration

Share the environment with your team:

```bash
# Commit manifest.toml to your repository
git add examples/flox/manifest.toml
git commit -m "Add Grafana stack environment"

# Team members can then:
flox init -m manifest.toml
flox activate
```

### CI/CD Integration

Use in CI/CD pipelines:

```bash
# In your CI script
flox activate --
flox services start grafana-nix
# Run your tests
flox services stop grafana-nix
```

## 🎯 Advanced Configuration

### Custom Stack Configuration

Create a custom stack with specific settings:

```toml
[services.custom-grafana]
command = """
grafana-stack-custom \
  --grafana-password=secure \
  --prometheus-retention=30d \
  --data-dir=$FLOX_ENV_PROJECT_DIR/custom-data
"""
vars.CUSTOM_SETTING = "value"
is-daemon = true
```

### Multiple Environments

Run different stack configurations:

```toml
[services.dev-stack]
command = "grafana-stack --config=dev"
vars.ENV = "development"

[services.staging-stack]
command = "grafana-stack --config=staging"
vars.ENV = "staging"
```

### Integration with External Services

```toml
[services.grafana-nix]
command = "grafana-stack"
vars.EXTERNAL_PROMETHEUS_URL = "https://prometheus.example.com"
vars.EXTERNAL_LOKI_URL = "https://loki.example.com"
```

## 🛠️ Troubleshooting

### Common Issues

**Services won't start:**
```bash
# Check service status
flox services status

# View service logs
flox services logs grafana-nix
```

**Port conflicts:**
```bash
# Override default ports
flox activate --set GRAFANA_PORT=3001
flox activate --set PROMETHEUS_PORT=9091
```

**Data persistence:**
```bash
# Check data directory
ls -la $OBSERVABILITY_DATA_DIR

# Reset data (⚠️ deletes all data)
rm -rf $OBSERVABILITY_DATA_DIR
flox services restart grafana-nix
```

## 📚 Learn More

- [Flox Documentation](https://flox.dev/docs/)
- [Flox Service Management](https://flox.dev/docs/reference/command-reference/manifest.toml/#services)
- [Extending Flox with Nix Flakes](https://flox.dev/blog/extending-flox-with-nix-flakes/)
- [Grafana Nix Stack Repository](https://github.com/wscoble/grafana-nix)