# Product Requirements Document: Nix Grafana Stack Flake

**Document Version:** 1.0
**Date:** September 21, 2025
**Author:** Scott (and T3 Chat)
**Product Name:** Nix Grafana Stack Flake
**Project Goal:** To create a self-contained, reproducible, and highly configurable Nix flake that provides the full Grafana ecosystem (Grafana, Loki, Prometheus, Tempo, Mimir, etc.) with various deployment targets and configuration outputs.

---

### 1. Executive Summary

The Nix Grafana Stack Flake aims to be the definitive way to deploy and manage the Grafana ecosystem. By leveraging Nix, we will achieve unparalleled reproducibility, ease of configuration, and flexibility in deployment. This flake will provide multiple artifacts, including pre-built binaries, Docker images, and Kubernetes configurations, allowing users to run the Grafana stack natively, within Docker, or on a Kubernetes cluster, all from a single source of truth. Structured data like JSON and YAML will be represented as Nix expressions, ensuring all configurations are dynamic, type-safe, and easily customizable.

### 2. Goals & Objectives

*   **Primary Goal:** Provide a complete, reproducible, and configurable Grafana stack using a Nix flake.
*   **Reproducibility:** Ensure that any build or deployment derived from the flake is bit-for-bit identical given the same inputs.
*   **Flexibility:** Support multiple deployment targets:
    *   Native (systemd services, standalone binaries)
    *   Docker (individual containers and Compose configurations)
    *   Kubernetes (Helm charts, raw YAML manifests)
*   **Configurability:** All aspects of the Grafana stack (including dashboards, data sources, Loki/Prometheus/Tempo/Mimir configurations) should be configurable via Nix expressions.
*   **Maintainability:** Simplify updates and maintenance of the Grafana stack components through Nix's declarative nature.
*   **Developer Experience:** Offer an excellent developer experience for local iteration and testing of Grafana stack components.

### 3. Scope

The initial scope will include core components and key deployment outputs.

#### 3.1. Core Grafana Stack Components (Minimum Viable Stack)

*   **Grafana:** Core observability dashboard platform.
*   **Prometheus:** Time-series monitoring and alerting.
*   **Loki:** Log aggregation system.
*   **Tempo:** Distributed tracing backend.
*   *Stretch Goal (Future Iterations):* Mimir (scalable Prometheus), Alertmanager, Kube-state-metrics, Node Exporter, Grafana Agent, etc.

#### 3.2. Outputs from the Nix Flake

The flake will expose the following outputs, accessible via `nix build`, `nix run`, `nix develop`, or direct `nixpkgs` integration:

*   **`apps`:**
    *   `grafana-stack-native-run`: An executable that brings up the entire Grafana stack natively (e.g., via `systemd-nspawn` or a wrapper script).
    *   `grafana-stack-docker-compose`: An executable that deploys the stack via Docker Compose.
    *   `grafana-stack-k8s-apply`: An executable that applies the Kubernetes manifests.
*   **`packages`:**
    *   `grafana`: Self-contained Grafana binary/package.
    *   `prometheus`: Self-contained Prometheus binary/package.
    *   `loki`: Self-contained Loki binary/package.
    *   `tempo`: Self-contained Tempo binary/package.
    *   Individual Docker images for each component (`grafana-image`, `prometheus-image`, `loki-image`, `tempo-image`).
    *   `grafana-stack-docker-compose-file`: A `.tar.gz` or similar containing the Docker Compose YAML and associated files.
    *   `grafana-stack-kubernetes-manifests`: A `.tar.gz` or similar containing all K8s manifests (deployments, services, configmaps, ingresses, etc.).
*   **`devShells`:**
    *   `default`: A development shell providing all necessary tools and binaries for working with the Grafana stack.
*   **`config`:**
    *   A top-level attribute set representing the *evaluated* structured configuration for each component, making it easy to inspect and debug.

#### 3.3. Configuration Management

*   **Nix Expressions for Structured Data:** All structured data (JSON, YAML, etc.) that defines configurations, dashboards, data sources, alerts, etc., will be expressed directly in Nix.
    *   For example, a Grafana dashboard JSON will be represented as a Nix attribute set that evaluates to the desired JSON structure.
    *   Prometheus/Loki/Tempo configuration YAMLs will similarly be Nix expressions that evaluate to the respective YAMLs.
*   **Parameterization:** The flake should expose configurable options for:
    *   Component versions (Grafana, Prometheus, Loki, Tempo).
    *   Network ports.
    *   Storage paths.
    *   Resource limits (for K8s/Docker).
    *   Authentication details (e.g., Grafana admin password, API keys for external services).
    *   Dashboard definitions (potentially an input where users can provide their own).
    *   Data source definitions.
    *   Alerting rules.

### 4. Technical Requirements

#### 4.1. Nix Flake Structure

*   `flake.nix`: The entry point for the flake, defining inputs, outputs, and default configuration.
*   `modules/`: Directory for reusable Nix modules for different components or configurations.
*   `lib/`: Directory for common Nix utility functions.
*   `data/`: Directory (potentially) for any non-Nix native data that needs to be consumed (e.g., raw SQL schemas, although most will be Nix-nativized).
*   `overlays/`: For custom Nixpkgs overlays if necessary.

#### 4.2. Build System

*   Leverage `mkDerivation` and `buildEnv` for package construction.
*   Utilize Nix's native builders for efficiency and reproducibility.
*   Use `nix-dockertools` or similar for Docker image creation within Nix.
*   Employ Nix's JSON/YAML serialization functions (e.g., `builtins.toJSON`, `pkgs.lib.generators.toYAML`) for generating structured data from Nix expressions.

#### 4.3. Deployment Targets Details

##### 4.3.1. Native Deployment

*   **Binaries:** Each component will have a runnable binary output.
*   **Configurations:** Configuration files for each component will be generated and placed in a standard location relative to the binaries.
*   **Service Wrappers:** Provide `systemd` unit files (or similar service management definitions) as part of the output, configured to use the generated binaries and configurations.
*   **Example Usage:** `nix run .#grafana-stack-native-run` which might launch a `systemd-nspawn` container or just run the services locally.

##### 4.3.2. Docker Deployment

*   **Individual Docker Images:** Each component will have its own optimized Docker image output, based on minimal base images (e.g., `scratch` or `distroless` where possible).
*   **Docker Compose:** A `docker-compose.yaml` file will be generated that orchestrates all components, linked to the generated Docker images. This will include volumes, networks, and environment variables derived from Nix configurations.
*   **Example Usage:** `nix build .#grafana-stack-docker-compose-file` followed by `docker compose -f <path-to-file> up`.

##### 4.3.3. Kubernetes Deployment

*   **Kubernetes Manifests:** A complete set of Kubernetes YAML manifests (Deployments, Services, ConfigMaps, PersistentVolumeClaims, Ingresses, etc.) will be generated.
*   **ConfigMaps:** All structured configurations (Prometheus rules, Loki config, Grafana dashboards, data sources) will be injected into Kubernetes via ConfigMaps, generated directly from Nix expressions.
*   **Service Accounts & RBAC:** Appropriately configured service accounts and role-based access control (RBAC) rules.
*   **Example Usage:** `nix build .#grafana-stack-kubernetes-manifests` followed by `kubectl apply -f <path-to-manifests>`.

#### 4.4. Configuration as Nix Expressions

*   **Structured Types:** Define clear Nix types for common configuration patterns (e.g., a `grafanaDashboard` type, a `prometheusRule` type).
*   **Generators:** Use `lib.generators` to convert Nix expressions into JSON, YAML, or other formats as required by the respective components.
*   **Modularity:** Allow users to easily add their own dashboards, data sources, and alerting rules by extending lists of Nix expressions.

### 5. User Stories

*   **As a Developer,** I want to quickly spin up a local Grafana stack with specific versions of components so I can develop and test my applications against a known environment.
*   **As an SRE/DevOps Engineer,** I want to deploy a production-ready Grafana stack to Kubernetes with all configurations managed declaratively in Nix so that I can ensure consistency and reproducibility across environments.
*   **As a Data Engineer,** I want to define Grafana dashboards as Nix expressions and have them automatically deployed with my stack so that I can version control and review changes to my visualizations.
*   **As an Administrator,** I want to easily update the Grafana stack components to newer versions and ensure all dependencies are resolved automatically by Nix.
*   **As a Security Engineer,** I want to build Docker images for the Grafana stack from source, ensuring no extraneous packages or vulnerabilities are present.

### 6. Success Metrics

*   All specified Grafana stack components are available as Nix packages.
*   The flake successfully builds Docker images, binaries, and Kubernetes configurations.
*   A user can run the full Grafana stack successfully using the native, Docker, and Kubernetes outputs.
*   Configuration values can be overridden via Nix flake inputs or module options.
*   Dashboards and data sources can be defined purely as Nix expressions and are correctly applied.
*   The build time for the core components is reasonable (e.g., under 1 hour on a cold cache for all outputs).
*   The generated Docker images are minimal and efficient.

### 7. Future Considerations (Out of Scope for Initial Release)

*   **Grafana Plugins:** Support for easily integrating and building Grafana plugins via Nix.
*   **Mimir/Thanos Integration:** Full integration of highly scalable observability backends.
*   **Managed Services Integration:** Options to connect to external managed databases, object storage, etc.
*   **Terraform/Pulumi Integration:** Providing outputs compatible with infrastructure-as-code tools.
*   **Automated Testing:** Integration with `nix test` or similar for end-to-end testing of the deployed stack.
*   **Community Contributions:** Establishing guidelines for contributing new components, dashboards, or configurations.

### 8. Open Questions / Decisions To Be Made

*   **Base Images for Docker:** Which minimal base images (e.g., `scratch`, `distroless`, `alpine`) will be used for Docker outputs, balancing size vs. debugging capabilities?
*   **Kubernetes Manifest Generation Tool:** Will this be entirely custom Nix-to-YAML, or will a tool like `kcl` or `jsonnet` (integrated via Nix) be used for complex K8s manifest generation? (Initial thought: pure Nix, using `lib.generators.toYAML`).
*   **Systemd vs. Other Native Service Management:** While `systemd` is common, are there other native service management systems to consider or generic run scripts? (Initial thought: `systemd` as the primary example, with run scripts for manual execution).
*   **Parameterization Mechanism:** How will top-level configurable options be exposed (e.g., `specialArgs` to the flake, specific `options` in a top-level module)?