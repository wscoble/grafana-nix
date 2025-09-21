# 🤝 Contributing to Grafana Nix Stack

Thank you for your interest in contributing! This project aims to make Nix and observability accessible to everyone, from beginners to experts.

## 🎯 Project Goals

Our mission is to:
- **Lower the barrier** to using Nix for observability
- **Provide excellent documentation** for newcomers
- **Maintain high-quality** reproducible configurations
- **Support multiple deployment targets** from a single source

## 🚀 Quick Start for Contributors

### 1. Development Environment

```bash
# Clone the repository
git clone https://github.com/wscoble/grafana-nix
cd grafana-nix

# Enter development shell (installs all tools)
nix develop

# Verify everything works
nix flake check
```

### 2. Make Your Changes

```bash
# Create a feature branch
git checkout -b feature/your-feature-name

# Make your changes
# ... edit files ...

# Test your changes
nix flake check
nix build .#packages.grafana  # Test specific packages
```

### 3. Submit for Review

```bash
# Commit with conventional commits format
git commit -m "feat: add support for custom exporters"

# Push and create PR
git push origin feature/your-feature-name
```

## 📋 Types of Contributions

### 🐛 Bug Reports

Found a bug? Help us fix it:

1. **Search existing issues** to avoid duplicates
2. **Use the bug report template**
3. **Include minimal reproduction steps**
4. **Specify your environment** (OS, Nix version, etc.)

### 💡 Feature Requests

Have an idea? We'd love to hear it:

1. **Check existing discussions** for similar ideas
2. **Use the feature request template**
3. **Explain the use case** and expected behavior
4. **Consider offering to implement it**

### 📚 Documentation

Documentation improvements are always welcome:

- **Fix typos** and improve clarity
- **Add examples** for real-world use cases
- **Create tutorials** for specific scenarios
- **Improve beginner guides**

### 🔧 Code Contributions

Ready to dive into the code? Here's what we need:

#### High Priority
- [ ] Additional exporters (node-exporter, blackbox-exporter)
- [ ] Helm chart generation
- [ ] Better error messages and validation
- [ ] Performance optimizations

#### Medium Priority
- [ ] Grafana plugin support
- [ ] Advanced alerting configurations
- [ ] Multi-environment examples
- [ ] Integration tests

#### Nice to Have
- [ ] Web UI for configuration generation
- [ ] Terraform provider integration
- [ ] Custom dashboard library

## 🏗️ Development Workflow

### Repository Structure

```
├── flake.nix              # Main flake definition
├── lib/                   # Utility functions
│   ├── default.nix        # Main library exports
│   ├── generators.nix     # Config generators (JSON/YAML)
│   └── builders.nix       # Package builders
├── modules/               # Component modules
│   ├── grafana.nix        # Grafana configuration
│   ├── prometheus.nix     # Prometheus configuration
│   ├── loki.nix          # Loki configuration
│   └── tempo.nix         # Tempo configuration
├── packages/              # Package definitions
│   ├── default.nix       # Package exports
│   └── grafana-stack.nix  # Meta-package
├── examples/              # Usage examples
├── docs/                  # Documentation
└── tests/                 # Test suite
```

### Code Style

We follow standard Nix conventions:

```nix
# Good: Clear, descriptive names
{ lib, pkgs, config, ... }:

let
  cfg = config.services.grafana;
  configFile = pkgs.writeText "grafana.ini" (lib.generators.toINI {} cfg.settings);
in {
  # Options definition
  options.services.grafana = {
    enable = lib.mkEnableOption "Grafana service";

    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "Port for Grafana to listen on";
    };
  };

  # Implementation
  config = lib.mkIf cfg.enable {
    # Service configuration
  };
}
```

**Style Guidelines:**
- Use 2-space indentation
- Keep lines under 100 characters
- Add type annotations for options
- Include helpful descriptions
- Use `lib.mkIf` for conditional configuration

### Testing

Before submitting, ensure all tests pass:

```bash
# Check flake validity
nix flake check

# Build all packages
nix build .#packages.grafana
nix build .#packages.prometheus

# Test development shell
nix develop --command echo "Development shell works"

# Run integration tests (if available)
nix build .#checks.integration-test
```

### Documentation

Every contribution should include appropriate documentation:

- **New features**: Add to relevant docs/ files
- **Configuration options**: Document in module files
- **Breaking changes**: Update migration guides
- **Examples**: Add to examples/ directory

## 📝 Commit Guidelines

We use [Conventional Commits](https://www.conventionalcommits.org/):

```bash
# Format: <type>(<scope>): <description>

# Examples:
feat(grafana): add support for custom themes
fix(prometheus): correct retention period validation
docs(readme): improve installation instructions
test(ci): add integration test for Docker deployment
refactor(lib): simplify configuration generation
```

**Types:**
- `feat`: New features
- `fix`: Bug fixes
- `docs`: Documentation changes
- `test`: Adding or updating tests
- `refactor`: Code changes that don't add features or fix bugs
- `chore`: Maintenance tasks

## 🔍 Code Review Process

### For Reviewers

When reviewing PRs, check:

1. **Functionality**: Does it work as expected?
2. **Nix best practices**: Follows conventions?
3. **Documentation**: Is it documented?
4. **Tests**: Are there appropriate tests?
5. **Breaking changes**: Are they necessary and documented?

### For Contributors

To get your PR merged quickly:

1. **Keep PRs focused**: One feature/fix per PR
2. **Write good commit messages**: Follow conventional commits
3. **Include tests**: Verify your changes work
4. **Update documentation**: Help others understand your changes
5. **Respond to feedback**: Address reviewer comments promptly

## 🛡️ Security

### Reporting Security Issues

**Do not** open public issues for security vulnerabilities. Instead:

1. Email: [SECURITY_EMAIL](mailto:security@example.com)
2. Include: Detailed description and reproduction steps
3. We'll respond within 48 hours

### Security Guidelines

When contributing:
- **Never commit secrets** (passwords, API keys, certificates)
- **Validate inputs** to prevent injection attacks
- **Use secure defaults** in configurations
- **Follow least privilege** principle

## 🏷️ Release Process

### Versioning

We use [Semantic Versioning](https://semver.org/):
- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

### Release Workflow

1. **PRs are merged** to `main` branch
2. **Rolling releases** are published automatically to FlakeHub
3. **Tagged releases** are created manually for stable versions
4. **GitHub releases** include change logs and assets

### Creating a Release

Maintainers can create releases:

```bash
# Update version in flake.nix
# Create and push tag
git tag v1.2.0
git push origin v1.2.0

# GitHub Actions will:
# 1. Run all tests
# 2. Publish to FlakeHub
# 3. Create GitHub release
# 4. Update documentation
```

## 👥 Community

### Communication Channels

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: Questions and general discussion
- **Discord**: Real-time chat in [Nix Community](https://discord.gg/RbvHtGa)

### Code of Conduct

We follow the [Contributor Covenant](https://www.contributor-covenant.org/). In summary:

- **Be respectful** of differing viewpoints
- **Accept constructive criticism** gracefully
- **Focus on what's best** for the community
- **Show empathy** towards other community members

## 🎓 Learning Resources

### New to Nix?

- [Zero to Nix](https://zero-to-nix.com/) - Start here!
- [Nix Pills](https://nixos.org/guides/nix-pills/) - Deep dive
- [NixOS Manual](https://nixos.org/manual/nixos/stable/) - Comprehensive reference

### New to Observability?

- [Grafana Fundamentals](https://grafana.com/tutorials/grafana-fundamentals/)
- [Prometheus Basics](https://prometheus.io/docs/introduction/first_steps/)
- [The Three Pillars of Observability](https://www.oreilly.com/library/view/distributed-systems-observability/9781492033431/ch04.html)

## 🏆 Recognition

Contributors are recognized in several ways:

- **README credits**: Listed in acknowledgments
- **Release notes**: Highlighted for significant contributions
- **Special recognition**: For outstanding contributions

## ❓ Questions?

Need help getting started?

1. **Read the docs**: Start with [docs/getting-started/](./docs/getting-started/)
2. **Search issues**: Your question might already be answered
3. **Ask in discussions**: [GitHub Discussions](https://github.com/wscoble/grafana-nix/discussions)
4. **Join Discord**: [Nix Community](https://discord.gg/RbvHtGa)

---

**Thank you for contributing to making Nix and observability more accessible!** 🎉