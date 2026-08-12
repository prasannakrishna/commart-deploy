# Commart Platform — Single-Server Deployment

Deploy the entire platform (38 microservices + infrastructure) on one VPS for ~$15/month.

## Prerequisites

- Server: 4 vCPU, 16GB RAM minimum (Hetzner CX41 or equivalent)
- Docker + Docker Compose installed
- Domain DNS configured (see main deployment strategy doc)

## Quick Start

```bash
# 1. SSH into your server
ssh root@your-server-ip

# 2. Clone this deploy folder
git clone https://github.com/<org>/commart-deploy.git
cd commart-deploy

# 3. Copy and edit environment
cp .env.example .env
nano .env  # set DB_PASSWORD, GHCR_ORG

# 4. Login to GitHub Container Registry
echo $GITHUB_PAT | docker login ghcr.io -u <username> --password-stdin

# 5. Start infrastructure first
docker compose up -d postgres mongodb kafka redis elasticsearch
# Wait 30 seconds for healthy

# 6. Start config server
docker compose up -d config-server
# Wait 15 seconds

# 7. Start all services
docker compose up -d

# 8. Check health
docker compose ps
curl http://localhost:80/health
```

## Architecture

```
Internet → Nginx (:80/:443) → Java Services → PostgreSQL/MongoDB/Kafka/Redis
              ↑
    api.commart.co.in (CNAME to this server)
```

## Memory Usage (~14GB)

| Component | Memory | Count |
|-----------|--------|-------|
| PostgreSQL | 1024MB | 1 |
| MongoDB | 512MB | 1 |
| Kafka (KRaft) | 768MB | 1 |
| Elasticsearch | 512MB | 1 |
| Redis | 128MB | 1 |
| Config Server | 192MB | 1 |
| Nginx | 64MB | 1 |
| Java services (×28) | 192MB each | ~5.4GB total |
| **Total** | | **~8.6GB** |

Fits comfortably in 16GB with headroom for spikes.

## Tier-Based Startup

Start only what you need:

```bash
# Tier 1: Core (customer journey works)
docker compose up -d postgres kafka redis config-server \
  auth-service user-service customer-service cart-manager \
  order-service catalog-service community-manager payment-service nginx

# Tier 2: Fulfillment (seller + logistics)
docker compose up -d seller-service allocation-service wms-service \
  store-service carrier-service transport-planner delivery-service

# Tier 3: Finance
docker compose up -d billing-engine finance-service escrow-gateway \
  subscription-billing contract-manager lineage-service

# Tier 4: Intelligence (optional)
docker compose up -d sla-watchdog dispute-service feed-service notification-service
```

## SSL with Let's Encrypt (free)

```bash
# Install certbot
apt install certbot
certbot certonly --standalone -d api.commart.co.in

# Update nginx.conf to use certs, or use Cloudflare tunnel (free, zero-config SSL)
```

## Updates

```bash
# Pull latest images and restart
docker compose pull
docker compose up -d
```
