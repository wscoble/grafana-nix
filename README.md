# 📊 Grafana Nix Stack

> **Add instant observability to any development project**

[![CI](https://github.com/wscoble/grafana-nix/actions/workflows/ci.yml/badge.svg)](https://github.com/wscoble/grafana-nix/actions/workflows/ci.yml)
[![FlakeHub](https://img.shields.io/endpoint?url=https://flakehub.com/f/wscoble/grafana-nix/badge)](https://flakehub.com/flake/wscoble/grafana-nix)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Nix](https://img.shields.io/badge/Nix-flake-informational?logo=nixos&logoColor=white)](https://nixos.org/)
[![Flox](https://img.shields.io/badge/Flox-compatible-orange)](https://flox.dev/)

## 🎯 What is this?

Get **instant observability** for your development projects. This Nix flake provides Grafana, Prometheus, Loki, Tempo, and Alloy - everything you need to monitor your application's metrics, logs, and traces while you develop.

### ✨ Why developers love this

- **⚡ Instant setup**: One command gets you full observability
- **🔧 Zero config**: Works out of the box with sensible defaults
- **🏠 Local development**: Perfect for monitoring your app while coding
- **🔒 Reproducible**: Same stack everywhere - laptop, CI, production
- **🎯 Nix-powered**: Configuration as code, no more YAML hell

## 🚀 Quick Start

### 🦊 Using Flox (Recommended)

Add observability to any project with [Flox](https://flox.dev/):

> ⏱️ **First time**: ~5-10 minutes (downloads packages)
> **Subsequent runs**: ~30 seconds (cached)

```bash
# Add to your existing project
flox install github:wscoble/grafana-nix

# Start observability stack
flox services start observability

# Monitor your app at http://localhost:3000 (admin/dev)
```

### 📦 Using Nix directly

If you prefer using Nix directly:

> ⏱️ **First time**: ~10-15 minutes (installs Nix + downloads packages)
> **Subsequent runs**: Instant (cached)

#### 1. Install Nix (one command)

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

#### 2. Try the stack immediately

```bash
# Run the complete Grafana stack locally
nix run github:wscoble/grafana-nix

# Or enter a development shell with all tools
nix develop github:wscoble/grafana-nix
```

#### 3. Open your browser

- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **Loki**: http://localhost:3100
- **Tempo**: http://localhost:3200
- **Alloy**: http://localhost:12345

That's it! You now have complete observability for your development. 🎉

## 📚 What You Get

### Complete Observability Stack

| Component | What it monitors | Port | Why you need it |
|-----------|------------------|------|-----------------|
| **Grafana** | Dashboard for everything | 3000 | See all your metrics, logs, traces in one place |
| **Prometheus** | App metrics & performance | 9090 | Response times, error rates, resource usage |
| **Loki** | Application logs | 3100 | Debug issues with structured log search |
| **Tempo** | Request tracing | 3200 | Track requests across your services |
| **Alloy** | Data collection agent | 12345 | Collects and forwards telemetry data |

### Use It Anywhere

- **🏠 Development**: Local monitoring while you code
- **🐳 Docker**: Containerized development environments
- **☸️ Kubernetes**: Production-ready deployments
- **🖥️ Servers**: Native systemd services

## 📖 New to Nix? No Problem!

### Why Nix for Observability?

**The problem**: Setting up observability usually means:
- Installing multiple tools separately
- Wrestling with config files
- Dealing with version conflicts
- "Works on my machine" problems

**The Nix solution**: One command, perfect setup, works everywhere.

```bash
# Instead of this mess:
brew install grafana prometheus
docker run -d grafana/loki
# + configuring everything to work together...

# Just do this:
flox install github:wscoble/grafana-nix
flox services start observability
```

### Don't Know Nix? Start Here

1. **Try our stack**: Follow the Quick Start (you don't need to understand Nix)
2. **It just works**: Everything pre-configured for development
3. **Explore**: Check out the examples when you're curious
4. **Learn more**: [Zero to Nix](https://zero-to-nix.com/) when you want to dive deeper

## 🔧 Real-World Usage

### Add to Your Existing Project

```bash
# In your project directory
cd my-awesome-app
flox install github:wscoble/grafana-nix

# Start monitoring
flox services start observability

# Develop with observability running
npm run dev  # or whatever you normally do
```

### New Project with Built-in Observability

```bash
# Set up new project with observability
mkdir my-new-project && cd my-new-project
nix flake init -t github:wscoble/grafana-nix#flox
flox activate

# Your project now has instant observability
flox services start observability
```

### Team Development Environment

Add to your project's `manifest.toml` so everyone gets observability:

```toml
[install]
# Give the whole team observability
grafana-nix.flake = "github:wscoble/grafana-nix"

[services.observability]
command = "grafana-stack"
vars.GRAFANA_DATA_DIR = "$FLOX_ENV_PROJECT_DIR/data"
vars.PROMETHEUS_RETENTION = "7d"  # Short retention for dev
is-daemon = true
```

Now anyone can `flox activate` and get the same observability setup.


## 🎓 Learning More

### Want to understand your observability data?

- [📊 Grafana Fundamentals](https://grafana.com/tutorials/grafana-fundamentals/) - Learn to build dashboards
- [📈 Prometheus Basics](https://prometheus.io/docs/introduction/first_steps/) - Understanding metrics
- [📝 Loki for Logs](https://grafana.com/docs/loki/latest/fundamentals/overview/) - Better log analysis

### Curious about Nix?

- [🎯 Zero to Nix](https://zero-to-nix.com/) - Gentle introduction
- [🚀 Why Nix?](https://nixos.org/guides/how-nix-works/) - The big picture
- [📦 Flakes](https://nixos.wiki/wiki/Flakes) - Modern Nix (what this project uses)

### Examples You Can Try

- [📁 examples/flox/](./examples/flox/) - Detailed Flox integration
- [🐳 examples/docker/](./examples/docker/) - Docker deployment
- [⚙️ examples/custom/](./examples/custom/) - Advanced customization

## 🚀 Deployment Beyond Development

While this project is optimized for development environments, you can also deploy to production:

### Docker

```bash
# Generate Docker Compose setup
nix build .#docker-compose
cd result && docker-compose up -d
```

### Kubernetes

```bash
# Generate Kubernetes manifests
nix build .#kubernetes-manifests
kubectl apply -f result/
```

### NixOS

```nix
# In your NixOS configuration
imports = [ inputs.grafana-nix.nixosModules.default ];
services.grafana-stack.enable = true;
```

## 🤝 Contributing

We welcome contributions from Nix beginners and experts alike!

### Quick Contribution Guide

1. **Fork** the repository
2. **Create** a feature branch: `git checkout -b feature/amazing-feature`
3. **Test** your changes: `nix flake check`
4. **Commit** with conventional commits: `feat: add amazing feature`
5. **Push** and open a Pull Request

See [CONTRIBUTING.md](./CONTRIBUTING.md) for detailed guidelines.

## 🔄 Releases

This project uses semantic versioning and publishes to [FlakeHub](https://flakehub.com):

- **Tagged releases**: `v1.0.0`, `v1.1.0`, etc.
- **Rolling releases**: Latest `main` branch automatically published
- **GitHub Releases**: Automated release notes and artifacts

## 🆘 Getting Help

- **📋 Issues**: [GitHub Issues](https://github.com/wscoble/grafana-nix/issues)
- **💬 Discussions**: [GitHub Discussions](https://github.com/wscoble/grafana-nix/discussions)
- **📖 Documentation**: [docs/](./docs/)
- **🐦 Twitter**: Follow [@DeterminateSys](https://twitter.com/DeterminateSys) for Nix updates

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) for details.

## 🙏 Acknowledgments

- [Determinate Systems](https://determinate.systems/) for excellent Nix tooling
- [FlakeHub](https://flakehub.com/) for flake hosting and discovery
- The [Grafana Labs](https://grafana.com/) team for amazing observability tools
- The [Nix community](https://nixos.org/community/) for making reproducible software possible

---

<div align="center">

**Made with ❤️ and Nix**

[⭐ Star this project](https://github.com/wscoble/grafana-nix) if it helped you!

</div>