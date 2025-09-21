# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Grafana Nix Stack** is a complete, working Nix flake that provides instant observability for development projects. It's designed primarily for developers who want to add Grafana, Prometheus, Loki, Tempo, and Alloy to their development environment with zero configuration.

**Primary Use Case**: Add observability to development projects via Flox:
```bash
flox install github:wscoble/grafana-nix
flox services start observability
```

## Architecture

The project is **fully implemented** and provides a complete observability stack:

### Core Stack
- **Grafana** (port 3000): Dashboards and visualization
- **Prometheus** (port 9090): Metrics collection and storage
- **Loki** (port 3100): Log aggregation
- **Tempo** (port 3200): Distributed tracing
- **Alloy** (port 12345): Data collection agent (Grafana Agent)

### Project Structure
```
├── flake.nix              # Main flake with all outputs
├── lib/                   # Stack builder and utilities
│   ├── stack-builder.nix  # Core opinionated API
│   ├── generators.nix     # Config file generators
│   ├── docker.nix         # Docker utilities
│   └── kubernetes.nix     # K8s manifest generators
├── packages/              # Package definitions and variants
├── modules/               # NixOS/home-manager modules
├── examples/              # Usage examples
│   ├── flox/              # Flox integration (primary)
│   ├── docker/            # Docker deployment
│   └── custom/            # Advanced customization
└── template*/             # Flake templates

```

## Development Commands

**Working on this project**:
- `nix develop`: Enter dev environment for this project
- `nix run .`: Test the stack locally
- `nix flake check`: Validate everything
- `nix build .#grafana-stack`: Build main package

**Using the stack in other projects**:
- `flox install github:wscoble/grafana-nix`: Add to any project
- `nix run github:wscoble/grafana-nix`: Quick test run
- `nix flake init -t github:wscoble/grafana-nix#flox`: Template setup

## Key Design Principles

1. **Developer Experience First**: Optimized for development environments, not production
2. **Flox-Native**: Primary consumption via Flox with service management
3. **Zero Configuration**: Works out of the box with sensible defaults
4. **Environment Variable Support**: Configurable via env vars for Flox integration
5. **Reproducible**: Same setup everywhere (laptop, CI, team)

## Important Implementation Details

### Flox Integration
- Main service name: `observability` (not `grafana-nix`)
- Environment variables: `GRAFANA_ADMIN_PASSWORD=dev`, `PROMETHEUS_RETENTION=7d`
- Dev-focused defaults: Short retention, simple passwords, local data storage

### Package Outputs
- `grafana-nix`: Main package for Flox installation
- `grafana-stack`: Complete local binary stack
- Individual components: `grafana`, `prometheus`, `loki`, `tempo`
- Docker images and K8s manifests available but secondary

### Configuration API
```nix
# Simple API for customization
grafana-nix.lib.buildStack {
  grafana.adminPassword = "secure";
  prometheus.retention = "30d";
}
```

## Development Focus

This project prioritizes **developer experience** over enterprise features:
- Quick setup over complex configuration
- Development defaults over production hardening
- Flox integration over standalone usage
- Clear documentation over comprehensive features

When making changes, always consider: "Does this make it easier for a developer to add observability to their project?"