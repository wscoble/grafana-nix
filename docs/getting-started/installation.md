# 🚀 Installation Guide

This guide will get you from zero to running a complete Grafana observability stack in under 10 minutes, even if you've never used Nix before.

## Prerequisites

- **Operating System**: Linux, macOS, or WSL2 on Windows
- **Internet connection**: For downloading packages
- **Disk space**: ~2GB for the complete stack

That's it! No Docker, no Kubernetes, no package managers to install first.

## Step 1: Install Nix

### The One-Command Install

Run this command in your terminal:

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

This installs the [Determinate Nix Installer](https://github.com/DeterminateSystems/nix-installer), which is:
- **Fast**: Installs in under 60 seconds
- **Safe**: Can be uninstalled completely
- **Modern**: Includes flakes and other modern Nix features

### What just happened?

The installer:
1. Downloaded and verified the Nix package manager
2. Created the `/nix` store directory
3. Set up your shell environment
4. Enabled Nix flakes (the modern way to use Nix)

### Verify the installation

```bash
# Check Nix version
nix --version

# Should show something like: nix (Nix) 2.18.1
```

## Step 2: Try the Grafana Stack

Now for the magic! Run this single command:

```bash
nix run "https://flakehub.com/f/wscoble/grafana-nix"
```

### What's happening?

Nix is:
1. **Downloading** the flake from FlakeHub
2. **Building** all components (Grafana, Prometheus, Loki, Tempo, Alloy)
3. **Configuring** them to work together
4. **Starting** the complete stack

This might take a few minutes on first run as Nix downloads and builds everything. Subsequent runs are instant thanks to caching!

## Step 3: Access Your Stack

Once the command finishes, open your browser:

### 📊 Grafana Dashboard
- **URL**: http://localhost:3000
- **Username**: `admin`
- **Password**: `admin`
- **What you'll see**: Beautiful dashboards for system monitoring

### 📈 Prometheus Metrics
- **URL**: http://localhost:9090
- **What you'll see**: Raw metrics and a query interface

### 📝 Loki Logs
- **URL**: http://localhost:3100
- **What you'll see**: Log aggregation interface

### 🔍 Tempo Tracing
- **URL**: http://localhost:3200
- **What you'll see**: Distributed tracing interface

### 🤖 Alloy Agent
- **URL**: http://localhost:12345
- **What you'll see**: Grafana Agent UI for monitoring data collection

## Step 4: Development Mode

Want to customize or develop? Enter a development shell:

```bash
nix develop "https://flakehub.com/f/wscoble/grafana-nix"
```

This gives you:
- All binaries available in your PATH
- Configuration files in the current directory
- Hot reload for rapid iteration

## Common Issues & Solutions

### Issue: "Command not found: nix"

**Solution**: Restart your terminal or run:
```bash
source ~/.bashrc  # or ~/.zshrc
```

### Issue: Permission denied

**Solution**: The installer needs to create `/nix`. On some systems:
```bash
sudo mkdir /nix
sudo chown $USER /nix
# Then re-run the installer
```

### Issue: Ports already in use

**Solution**: Something else is using the default ports. Either:
1. Stop other services: `sudo systemctl stop grafana-server prometheus`
2. Or customize ports (see [Configuration Guide](./configuration.md))

### Issue: Slow first run

**Solution**: This is normal! Nix is downloading and building everything from source. Subsequent runs use cached results and are instant.

## Next Steps

🎉 **Congratulations!** You now have a complete observability stack running.

### Immediate next steps:
1. **[Basic Configuration](./configuration.md)** - Customize passwords, ports, retention
2. **[Adding Data Sources](./data-sources.md)** - Connect your applications
3. **[Creating Dashboards](./dashboards.md)** - Visualize your metrics

### When you're ready:
1. **[Docker Deployment](../advanced/docker.md)** - Containerized deployment
2. **[Kubernetes Deployment](../advanced/kubernetes.md)** - Production-ready orchestration
3. **[Custom Components](../advanced/custom-components.md)** - Add your own services

## Understanding What Happened

If you're curious about what Nix just did:

1. **Declarative**: Everything is defined in code, not imperative scripts
2. **Reproducible**: The same flake produces identical results everywhere
3. **Isolated**: Nothing was installed globally; everything lives in `/nix/store`
4. **Composable**: You can easily extend or modify the stack

This is why Nix is revolutionary for system configuration and deployment!

## Uninstalling (if needed)

Don't want to keep Nix? No problem:

```bash
/nix/nix-installer uninstall
```

This removes everything cleanly, leaving your system exactly as it was before.

---

**Need help?** [Open an issue](https://github.com/wscoble/grafana-nix/issues) or check our [FAQ](../faq.md).