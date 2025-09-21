# 🐳 Docker Deployment Example

This example shows how to deploy the Grafana stack using Docker and Docker Compose, with all images built by Nix for maximum reproducibility.

## Features

- **Nix-built Docker images** for all components
- **Docker Compose** orchestration
- **Persistent volumes** for data
- **Network isolation** with custom bridge network
- **Easy management** with helper scripts

## Prerequisites

- Docker daemon running
- Docker Compose installed
- User in `docker` group

```bash
# Add user to docker group (logout/login required)
sudo usermod -aG docker $USER

# Start Docker daemon (if not running)
sudo systemctl start docker
```

## Quick Start

```bash
cd examples/docker

# Start the complete stack
nix run .

# Access services:
# - Grafana: http://localhost:3000 (admin/admin)
# - Prometheus: http://localhost:9090
# - Loki: http://localhost:3100
# - Tempo: http://localhost:3200
# - Alloy: http://localhost:12345
```

## Management Commands

```bash
# View logs
nix run .#logs

# Stop the stack
nix run .#stop

# Restart individual services
docker-compose restart grafana
docker-compose restart prometheus
```

## Architecture

```
┌─────────────────┐    ┌─────────────────┐
│    Grafana      │    │   Prometheus    │
│   :3000         │◄───┤     :9090       │
└─────────────────┘    └─────────────────┘
         ▲                       ▲
         │              ┌─────────────────┐
         │              │  Node Exporter  │
         │              │     :9100       │
         │              └─────────────────┘
         │
┌─────────────────┐    ┌─────────────────┐
│      Loki       │    │      Tempo      │
│     :3100       │    │     :3200       │
└─────────────────┘    └─────────────────┘
```

## Container Details

### Grafana Container
- **Base**: Minimal Nix-built image
- **Port**: 3000
- **Volume**: `grafana-data:/var/lib/grafana`
- **Config**: Auto-provisioned data sources

### Prometheus Container
- **Base**: Minimal Nix-built image
- **Port**: 9090
- **Volume**: `prometheus-data:/prometheus`
- **Retention**: 30 days
- **Scrape targets**: Grafana, self, node-exporter

### Loki Container
- **Base**: Minimal Nix-built image
- **Port**: 3100
- **Volume**: `loki-data:/loki`
- **Storage**: Local filesystem

### Tempo Container
- **Base**: Minimal Nix-built image
- **Ports**: 3200 (HTTP), 4317 (OTLP gRPC), 4318 (OTLP HTTP), 14268 (Jaeger)
- **Volume**: `tempo-data:/tmp/tempo`
- **Protocols**: OTLP, Jaeger

## Custom Configuration

### Override Docker Compose Settings

```bash
# Create docker-compose.override.yml
cat > docker-compose.override.yml <<EOF
version: '3.8'
services:
  grafana:
    environment:
      GF_SECURITY_ADMIN_PASSWORD: "my-secure-password"
      GF_INSTALL_PLUGINS: "grafana-piechart-panel"
    ports:
      - "3001:3000"  # Use different port
EOF

# Restart with overrides
docker-compose up -d
```

### Add Custom Dashboards

```bash
# Create custom config
mkdir -p config/grafana/dashboards
cp my-dashboard.json config/grafana/dashboards/

# Restart Grafana
docker-compose restart grafana
```

### Add Prometheus Scrape Targets

```yaml
# config/prometheus/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'my-app'
    static_configs:
      - targets: ['host.docker.internal:8080']
```

## Debugging

### View Container Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f grafana
docker-compose logs -f prometheus
```

### Check Container Health

```bash
# List running containers
docker-compose ps

# Check specific service
docker-compose exec grafana grafana-cli admin stats
docker-compose exec prometheus promtool query instant 'up'
```

### Access Container Shell

```bash
# Grafana
docker-compose exec grafana /bin/sh

# Prometheus
docker-compose exec prometheus /bin/sh
```

## Data Persistence

All data is stored in Docker volumes:

```bash
# List volumes
docker volume ls | grep grafana

# Backup data
docker run --rm -v grafana-data:/data -v $(pwd):/backup \
  alpine tar czf /backup/grafana-backup.tar.gz -C /data .

# Restore data
docker run --rm -v grafana-data:/data -v $(pwd):/backup \
  alpine tar xzf /backup/grafana-backup.tar.gz -C /data
```

## Production Considerations

### Security

```yaml
# docker-compose.override.yml
services:
  grafana:
    environment:
      GF_SECURITY_ADMIN_PASSWORD: "${GRAFANA_PASSWORD}"
      GF_SECURITY_SECRET_KEY: "${GRAFANA_SECRET_KEY}"
      GF_USERS_ALLOW_SIGN_UP: "false"
```

### Resource Limits

```yaml
services:
  grafana:
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
```

### External Storage

```yaml
services:
  prometheus:
    volumes:
      - "/data/prometheus:/prometheus"  # External mount
```

## Troubleshooting

### Port Conflicts

```bash
# Check what's using a port
sudo netstat -tulpn | grep :3000

# Change ports in docker-compose.yml
```

### Permission Issues

```bash
# Fix volume permissions
docker-compose exec grafana chown -R grafana:grafana /var/lib/grafana
```

### Memory Issues

```bash
# Check container memory usage
docker stats

# Increase Docker memory limits
# Docker Desktop: Settings > Resources > Memory
```

## Next Steps

- **Scale with [Kubernetes](../kubernetes/)**
- **Add monitoring for your applications**
- **Set up external storage (S3, GCS)**
- **Configure SSL/TLS termination**
- **Implement backup strategies**

## Cleanup

```bash
# Stop and remove everything
docker-compose down -v

# Remove images
docker rmi $(docker images | grep grafana-nix | awk '{print $3}')

# Remove volumes (⚠️ deletes all data)
docker volume rm grafana-data prometheus-data loki-data tempo-data
```