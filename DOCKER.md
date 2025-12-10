# Docker Deployment Guide

Complete guide for building and deploying Expeditious Reader as a Docker container.

## 🚀 Quick Start

### Option 1: Using the Build Script (Recommended)
```bash
# Build and run (uses prebuilt web assets - fast)
./docker-build.sh

# Access the app at http://localhost:8080
```

### Option 2: Using Docker Compose
```bash
# Build the web app first
flutter build web --release

# Start the container
docker-compose up -d

# Access the app at http://localhost:8080
```

### Option 3: Manual Docker Commands
```bash
# Build the web app
flutter build web --release

# Build Docker image
docker build -f Dockerfile.prebuilt -t expeditiousreader-web .

# Run container
docker run -d -p 8080:80 --name expeditiousreader-web expeditiousreader-web
```

## 📁 Files Overview

### Docker Files

1. **`Dockerfile`** - Full build from source
   - Builds Flutter app inside Docker
   - Slower but completely self-contained
   - Use for CI/CD or when you don't have Flutter installed

2. **`Dockerfile.prebuilt`** - Uses existing build
   - Uses `build/web` or `releases/web`
   - Much faster (~30 seconds vs 10+ minutes)
   - Requires Flutter web build first

3. **`docker-compose.yml`** - Container orchestration
   - Defines both prebuilt and full-build services
   - Easy multi-container management
   - Production-ready configuration

4. **`docker/nginx.conf`** - Web server configuration
   - Optimized for Flutter web apps
   - Gzip compression enabled
   - Proper caching headers
   - SPA routing support

5. **`docker-build.sh`** - Automated build script
   - Handles everything automatically
   - Checks prerequisites
   - Builds and runs container
   - Shows useful information

6. **`.dockerignore`** - Build context optimization
   - Excludes unnecessary files
   - Speeds up Docker builds
   - Reduces image size

## 🎯 Build Modes

### Prebuilt Mode (Fast - Recommended)
Uses existing `build/web` directory.

**Advantages:**
- ✅ Very fast (~30 seconds)
- ✅ Smaller Docker image
- ✅ Great for rapid iteration

**When to use:**
- Local development
- Quick deployments
- You already have a web build

**Command:**
```bash
./docker-build.sh prebuilt
# or
docker-compose up -d
```

### Full Build Mode (Slow - CI/CD)
Builds Flutter app from source inside Docker.

**Advantages:**
- ✅ No Flutter SDK required
- ✅ Reproducible builds
- ✅ Perfect for CI/CD

**When to use:**
- CI/CD pipelines
- Fresh deployments
- No local Flutter installation

**Command:**
```bash
./docker-build.sh full
# or
docker-compose --profile dev up -d
```

## 🔧 Configuration

### Port Configuration

Change the port in `docker-compose.yml`:
```yaml
services:
  expeditiousreader:
    ports:
      - "8080:80"  # Change 8080 to your desired port
```

Or with docker run:
```bash
docker run -d -p 3000:80 --name expeditiousreader-web expeditiousreader-web
```

Or with environment variable:
```bash
PORT=3000 ./docker-build.sh
```

### Nginx Configuration

Edit `docker/nginx.conf` to customize:
- Cache duration
- Gzip compression levels
- Security headers
- Request size limits

## 📊 Container Management

### View Logs
```bash
# Follow logs
docker logs -f expeditiousreader-web

# Last 100 lines
docker logs --tail 100 expeditiousreader-web

# With timestamps
docker logs -t expeditiousreader-web
```

### Control Container
```bash
# Stop
docker stop expeditiousreader-web

# Start
docker start expeditiousreader-web

# Restart
docker restart expeditiousreader-web

# Remove
docker rm -f expeditiousreader-web
```

### Container Information
```bash
# Check status
docker ps -a | grep expeditiousreader

# Inspect details
docker inspect expeditiousreader-web

# Check health
docker ps --filter "health=healthy"

# Resource usage
docker stats expeditiousreader-web
```

### Shell Access
```bash
# Access container shell
docker exec -it expeditiousreader-web sh

# Run commands
docker exec expeditiousreader-web ls -la /usr/share/nginx/html
```

## 🌐 Production Deployment

### Basic Production Setup
```bash
# 1. Build the web app
flutter build web --release

# 2. Build Docker image
docker build -f Dockerfile.prebuilt -t expeditiousreader-web:v1.0.0 .

# 3. Run container
docker run -d \
  --name expeditiousreader-web \
  -p 80:80 \
  --restart always \
  expeditiousreader-web:v1.0.0
```

### With Docker Compose (Production)
```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  app:
    image: expeditiousreader-web:latest
    container_name: expeditiousreader-prod
    ports:
      - "80:80"
      - "443:443"  # If using HTTPS
    restart: always
    environment:
      - NGINX_ENTRYPOINT_QUIET_LOGS=1
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/health"]
      interval: 30s
      timeout: 3s
      retries: 3
    volumes:
      - ./ssl:/etc/nginx/ssl:ro  # For HTTPS certificates
```

### Behind a Reverse Proxy (Nginx/Apache)

**Nginx reverse proxy config:**
```nginx
server {
    listen 80;
    server_name reader.example.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### With Traefik
```yaml
services:
  app:
    image: expeditiousreader-web:latest
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.reader.rule=Host(`reader.example.com`)"
      - "traefik.http.routers.reader.entrypoints=websecure"
      - "traefik.http.routers.reader.tls.certresolver=letsencrypt"
```

## 🔐 Security Considerations

### Built-in Security Headers
The nginx configuration includes:
- X-Frame-Options: SAMEORIGIN
- X-Content-Type-Options: nosniff
- X-XSS-Protection: 1; mode=block
- Referrer-Policy: no-referrer-when-downgrade

### Additional Recommendations
1. **Use HTTPS** in production
2. **Limit request sizes** (already set to 50MB)
3. **Regular updates** of base image
4. **Run as non-root** (already configured)
5. **Network isolation** with Docker networks

### Enable HTTPS
```bash
# Generate self-signed cert (development only)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout docker/ssl/key.pem \
  -out docker/ssl/cert.pem

# Update nginx.conf to include SSL configuration
```

## 📈 Performance Optimization

### Image Size Optimization
```bash
# Check image size
docker images expeditiousreader-web

# Use multi-stage build (already implemented)
# Current size: ~50MB (nginx:alpine + web assets)
```

### Build Cache
```bash
# Clear build cache if needed
docker builder prune

# Build with no cache
docker build --no-cache -f Dockerfile.prebuilt -t expeditiousreader-web .
```

### Resource Limits
```yaml
services:
  app:
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 128M
```

## 🐛 Troubleshooting

### Container won't start
```bash
# Check logs
docker logs expeditiousreader-web

# Common issues:
# 1. Port already in use - change the port
# 2. Build files missing - run flutter build web
# 3. Permission issues - check file ownership
```

### App loads but shows blank page
```bash
# Check if files are present
docker exec expeditiousreader-web ls -la /usr/share/nginx/html

# Check nginx configuration
docker exec expeditiousreader-web nginx -t

# View nginx logs
docker exec expeditiousreader-web cat /var/log/nginx/error.log
```

### Health check fails
```bash
# Manual health check
docker exec expeditiousreader-web wget -O- http://localhost/health

# Check nginx status
docker exec expeditiousreader-web ps aux | grep nginx
```

### Build fails
```bash
# For prebuilt mode:
# 1. Ensure build/web exists
flutter build web --release

# 2. Check .dockerignore isn't excluding build/
cat .dockerignore

# For full build mode:
# 1. Check internet connection (downloads Flutter)
# 2. Increase Docker memory/CPU limits
# 3. Check disk space
df -h
```

## 🔄 CI/CD Integration

### GitHub Actions Example
```yaml
name: Build and Deploy Docker Image

on:
  push:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build Docker image
        run: |
          docker build -f Dockerfile -t expeditiousreader-web:latest .
      
      - name: Push to registry
        run: |
          echo "${{ secrets.DOCKER_PASSWORD }}" | docker login -u "${{ secrets.DOCKER_USERNAME }}" --password-stdin
          docker tag expeditiousreader-web:latest username/expeditiousreader-web:latest
          docker push username/expeditiousreader-web:latest
```

### GitLab CI Example
```yaml
build-docker:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker build -f Dockerfile -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
```

## 📦 Distribution

### Push to Docker Hub
```bash
# Login
docker login

# Tag image
docker tag expeditiousreader-web:latest username/expeditiousreader-web:v1.0.0

# Push
docker push username/expeditiousreader-web:v1.0.0
```

### Export/Import Image
```bash
# Export image to tar
docker save expeditiousreader-web:latest -o expeditiousreader-web.tar

# Import on another machine
docker load -i expeditiousreader-web.tar
```

### Private Registry
```bash
# Tag for private registry
docker tag expeditiousreader-web:latest registry.example.com/expeditiousreader-web:latest

# Push to private registry
docker push registry.example.com/expeditiousreader-web:latest
```

## 🎨 Customization

### Custom Environment Variables
Create `.env` file:
```env
PORT=8080
CONTAINER_NAME=my-reader-app
IMAGE_NAME=my-reader-image
```

Use in docker-compose:
```yaml
services:
  app:
    env_file:
      - .env
```

### Multiple Instances
```bash
# Run multiple instances on different ports
docker run -d -p 8080:80 --name reader-instance-1 expeditiousreader-web
docker run -d -p 8081:80 --name reader-instance-2 expeditiousreader-web
docker run -d -p 8082:80 --name reader-instance-3 expeditiousreader-web
```

## 📚 Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Flutter Web Deployment](https://docs.flutter.dev/deployment/web)
- Project Build Scripts: [BUILD_SCRIPTS.md](../BUILD_SCRIPTS.md)

## ✅ Verification Checklist

After deployment, verify:
- [ ] Container is running: `docker ps`
- [ ] Health check passes: `docker ps --filter "health=healthy"`
- [ ] App is accessible: `curl http://localhost:8080`
- [ ] Logs show no errors: `docker logs expeditiousreader-web`
- [ ] Static assets load: Check browser network tab
- [ ] Routing works: Navigate between pages

---

**Quick Commands Reference:**
```bash
# Build and run
./docker-build.sh

# Stop
docker stop expeditiousreader-web

# Start
docker start expeditiousreader-web

# Logs
docker logs -f expeditiousreader-web

# Remove
docker rm -f expeditiousreader-web
```

For more help, see the project documentation or visit the [Docker Guide](https://docs.docker.com/get-started/).
