# ❓ Frequently Asked Questions

## General Questions

### What is this project exactly?

The Grafana Nix Stack is a single Nix flake that packages the complete Grafana observability ecosystem (Grafana, Prometheus, Loki, Tempo) with:
- Reproducible builds across all platforms
- Multiple deployment targets (native, Docker, Kubernetes)
- Configuration entirely written as Nix code
- Zero-configuration data source integration

Think of it as "the easiest way to get a production-ready observability stack."

### Why use Nix instead of Docker/Helm/etc?

**Reproducibility**: Nix guarantees bit-for-bit identical builds. Your laptop, CI, and production will have exactly the same software.

**Configuration as Code**: Instead of managing YAML files, environment variables, and configuration drift, everything is declared in Nix's powerful expression language.

**Multiple Outputs**: One source produces native binaries, Docker images, and Kubernetes manifests - no need to maintain separate build systems.

**Dependency Management**: Nix handles all dependencies, including specific versions of libraries, without conflicts.

### Is this production-ready?

Yes! The components (Grafana, Prometheus, etc.) are the same stable versions you'd use elsewhere. Nix adds:
- Better reproducibility than traditional packaging
- Easier rollbacks if something breaks
- Atomic updates (either the whole system updates or none of it does)

Many organizations use Nix in production, including [Shopify](https://shopify.engineering/shipit-presents-how-shopify-uses-nix), [Tweag](https://www.tweag.io/), and [Mercury](https://mercury.com/).

## Nix Questions

### I'm new to Nix. Where should I start?

1. **Start here**: Follow our [Installation Guide](./docs/getting-started/installation.md)
2. **Learn basics**: [Zero to Nix](https://zero-to-nix.com/) (30 minutes)
3. **Try examples**: Use our provided configurations
4. **Experiment**: Modify configurations to see what happens
5. **Deep dive**: [Nix Pills](https://nixos.org/guides/nix-pills/) when you're ready

You don't need to understand Nix deeply to use this project effectively!

### How is this different from NixOS?

- **NixOS**: Complete Linux distribution using Nix
- **This project**: Nix flake that runs on any Linux/macOS system

You can use this project on Ubuntu, macOS, or any other system - you don't need to switch your entire OS to NixOS.

### What if I want to uninstall Nix later?

No problem! The [Determinate Nix Installer](https://github.com/DeterminateSystems/nix-installer) includes a complete uninstaller:

```bash
/nix/nix-installer uninstall
```

This removes everything cleanly, leaving your system exactly as it was.

### How much disk space does this use?

- **Nix itself**: ~500MB
- **Complete Grafana stack**: ~1.5GB on first build
- **Subsequent builds**: Nearly instant (cached)

Everything lives in `/nix/store` and doesn't interfere with your system packages.

## Usage Questions

### Can I use this alongside existing Grafana installations?

Yes, but you'll need to change ports to avoid conflicts:

```nix
{
  grafana.port = 3001;  # Instead of default 3000
  prometheus.port = 9091;  # Instead of default 9090
}
```

### How do I customize configurations?

Everything is configurable through Nix expressions:

```nix
{
  inputs.grafana-nix.url = "github:OWNER/grafana-nix";

  outputs = { grafana-nix, ... }: {
    myStack = grafana-nix.lib.buildStack {
      grafana = {
        adminPassword = "my-secure-password";
        theme = "dark";
      };
      prometheus.retention = "90d";
      loki.retentionPeriod = "2160h";  # 90 days
    };
  };
}
```

### Can I add my own dashboards?

Absolutely! Dashboards are just JSON files referenced in your Nix config:

```nix
{
  grafana.dashboards = [
    ./my-dashboard.json
    ./team-dashboard.json
  ];
}
```

### How do I deploy to production?

We provide several deployment methods:

**Docker**:
```bash
nix build .#docker-compose
docker-compose -f result/docker-compose.yml up -d
```

**Kubernetes**:
```bash
nix build .#kubernetes-manifests
kubectl apply -f result/
```

**Native** (systemd):
```bash
nix build .#systemd-services
sudo cp result/lib/systemd/system/* /etc/systemd/system/
sudo systemctl enable --now grafana-stack
```

### How do I update components?

Update the flake lock file:
```bash
nix flake update
nix build .  # Test the update
```

Or pin to specific versions:
```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";  # Pin to specific release
  };
}
```

## Troubleshooting

### "Error: file 'nixpkgs' was not found"

This usually means Nix flakes aren't enabled. Our installer enables them automatically, but if you installed Nix differently:

```bash
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### Ports are already in use

Something else is using the default ports. Either:

1. **Stop conflicting services**:
   ```bash
   sudo systemctl stop grafana-server prometheus
   ```

2. **Change ports in configuration**:
   ```nix
   {
     grafana.port = 3001;
     prometheus.port = 9091;
   }
   ```

### Build fails with "out of disk space"

Nix stores everything in `/nix/store`. If it's full:

```bash
# Clean old generations
nix-collect-garbage -d

# Or clean specific profile
nix-collect-garbage --delete-older-than 30d
```

### "Permission denied" errors

The Nix installer usually handles permissions, but on some systems:

```bash
sudo mkdir -p /nix
sudo chown -R $USER /nix
```

### Slow builds on first run

This is normal! Nix is downloading and building everything from source. Subsequent builds use cached results and are nearly instant.

To speed up initial builds, add binary caches:
```bash
echo "substituters = https://cache.nixos.org https://cache.iog.io" >> ~/.config/nix/nix.conf
```

## Advanced Questions

### Can I run this in CI/CD?

Yes! We provide GitHub Actions workflows that use the [Magic Nix Cache](https://github.com/DeterminateSystems/magic-nix-cache-action) for fast CI builds.

### How do I contribute custom components?

1. Add packages to `packages/`
2. Create modules in `modules/`
3. Update `flake.nix` outputs
4. Add tests and documentation

See [CONTRIBUTING.md](./CONTRIBUTING.md) for details.

### Can I use this with existing Kubernetes clusters?

Absolutely! The generated Kubernetes manifests work with any compliant cluster:

```bash
nix build .#kubernetes-manifests
kubectl apply -f result/ --namespace=observability
```

### How do I integrate with external services?

Configure data sources to point to external services:

```nix
{
  grafana.datasources = [
    {
      name = "External Prometheus";
      url = "https://prometheus.example.com";
      type = "prometheus";
    }
  ];
}
```

### Performance compared to traditional deployments?

Nix builds can be slower initially (everything from source), but runtime performance is identical or better:
- **Same binaries**: We're packaging the same Grafana, Prometheus, etc.
- **Better optimization**: Nix can optimize for your specific use case
- **Reduced overhead**: No container runtime overhead in native mode

## Getting Help

### My question isn't answered here

1. **Search existing issues**: [GitHub Issues](https://github.com/OWNER/grafana-nix/issues)
2. **Start a discussion**: [GitHub Discussions](https://github.com/OWNER/grafana-nix/discussions)
3. **Join the community**: [Nix Community Discord](https://discord.gg/RbvHtGa)

### How can I help improve this project?

- **Documentation**: Help make Nix more approachable for beginners
- **Testing**: Try on different platforms and report issues
- **Features**: Add new components or deployment targets
- **Examples**: Share your configurations and use cases

See [CONTRIBUTING.md](./CONTRIBUTING.md) for contribution guidelines.

### Is commercial support available?

For commercial support, training, and consulting around Nix and this stack, contact:
- [Determinate Systems](https://determinate.systems/) - Nix experts and tooling
- [Tweag](https://www.tweag.io/) - Nix consulting and development
- [NumTide](https://numtide.com/) - Nix/NixOS services

---

**Still have questions?** [Open an issue](https://github.com/OWNER/grafana-nix/issues/new) and we'll add it to this FAQ!