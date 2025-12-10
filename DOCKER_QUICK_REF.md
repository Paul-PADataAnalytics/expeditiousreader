# Docker Quick Reference

## 🚀 One-Command Deploy

```bash
./docker-build.sh
```

Then visit: **http://localhost:8080**

## 📋 Common Commands

### Build & Run
```bash
# Fastest (uses existing build)
./docker-build.sh prebuilt

# Complete (builds from source)
./docker-build.sh full

# Using Docker Compose
docker-compose up -d
```

### Control
```bash
# Stop container
docker stop expeditiousreader-web

# Start container
docker start expeditiousreader-web

# Restart container
docker restart expeditiousreader-web

# Remove container
docker rm -f expeditiousreader-web
```

### Logs & Debug
```bash
# View logs (follow)
docker logs -f expeditiousreader-web

# Last 50 lines
docker logs --tail 50 expeditiousreader-web

# Container shell
docker exec -it expeditiousreader-web sh

# Check health
docker ps --filter "health=healthy"
```

### Docker Compose
```bash
# Start
docker-compose up -d

# Stop
docker-compose down

# Logs
docker-compose logs -f

# Rebuild
docker-compose up -d --build
```

## 🎯 Build Modes

| Mode | Speed | Use Case | Command |
|------|-------|----------|---------|
| **Prebuilt** | ⚡ ~30s | Local dev, quick deploy | `./docker-build.sh prebuilt` |
| **Full** | 🐌 ~10min | CI/CD, no Flutter SDK | `./docker-build.sh full` |

## 🔧 Configuration

### Change Port
```bash
# Method 1: Environment variable
PORT=3000 ./docker-build.sh

# Method 2: Docker run
docker run -d -p 3000:80 --name reader expeditiousreader-web

# Method 3: Edit docker-compose.yml
ports:
  - "3000:80"
```

### Multiple Instances
```bash
docker run -d -p 8080:80 --name reader-1 expeditiousreader-web
docker run -d -p 8081:80 --name reader-2 expeditiousreader-web
docker run -d -p 8082:80 --name reader-3 expeditiousreader-web
```

## 🐛 Troubleshooting

### Container won't start
```bash
# Check logs
docker logs expeditiousreader-web

# Common fixes:
# 1. Port in use: Change port
# 2. No build: Run flutter build web
# 3. Permission: Check file ownership
```

### Blank page
```bash
# Check files exist
docker exec expeditiousreader-web ls -la /usr/share/nginx/html

# Check nginx config
docker exec expeditiousreader-web nginx -t

# Rebuild
docker rm -f expeditiousreader-web
./docker-build.sh
```

### Build fails
```bash
# Prebuilt mode: Need web build first
flutter build web --release

# Full mode: Check Docker resources
docker system df
docker system prune
```

## 📦 Image Management

```bash
# List images
docker images expeditiousreader-web

# Remove image
docker rmi expeditiousreader-web

# Clean up
docker system prune -a
```

## 🌐 Production

### Basic Production
```bash
docker run -d \
  --name expeditiousreader \
  -p 80:80 \
  --restart always \
  expeditiousreader-web:latest
```

### Behind Reverse Proxy
```nginx
# Nginx config
location / {
    proxy_pass http://localhost:8080;
    proxy_set_header Host $host;
}
```

### Push to Docker Hub
```bash
docker login
docker tag expeditiousreader-web username/expeditiousreader-web:v1.0
docker push username/expeditiousreader-web:v1.0
```

## 🔐 Security

```bash
# Built-in security headers ✓
# Non-root user ✓
# Health checks ✓

# Add HTTPS (production)
# Use reverse proxy (Nginx/Traefik)
# Regular image updates
```

## 📊 Monitoring

```bash
# Resource usage
docker stats expeditiousreader-web

# Health status
curl http://localhost:8080/health

# Container info
docker inspect expeditiousreader-web
```

## 🎨 Files

| File | Purpose |
|------|---------|
| `Dockerfile` | Full build from source |
| `Dockerfile.prebuilt` | Uses existing build (fast) |
| `docker-compose.yml` | Orchestration |
| `docker/nginx.conf` | Web server config |
| `docker-build.sh` | Automated script |
| `.dockerignore` | Build optimization |

## 📚 More Info

- Full guide: [DOCKER.md](DOCKER.md)
- Build scripts: [BUILD_SCRIPTS.md](BUILD_SCRIPTS.md)
- Project docs: [README.md](README.md)

---

**Need help?** Check `docker logs expeditiousreader-web` or see [DOCKER.md](DOCKER.md)
