#!/bin/bash

# Docker Build & Run Script for Expeditious Reader Web App
# Builds the Flutter web app and creates a Docker image to serve it

set -e  # Exit on error

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="expeditiousreader-web"
CONTAINER_NAME="expeditiousreader-web"
PORT="${PORT:-8080}"
BUILD_MODE="${1:-prebuilt}"  # 'prebuilt' or 'full'

echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   Expeditious Reader - Docker Build Script${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

# Function to check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}✗ Docker is not installed${NC}"
        echo "Please install Docker: https://docs.docker.com/get-docker/"
        exit 1
    fi
    echo -e "${GREEN}✓ Docker is installed${NC}"
}

# Function to check if build/web exists for prebuilt mode
check_web_build() {
    if [ "$BUILD_MODE" = "prebuilt" ]; then
        if [ ! -d "build/web" ] && [ ! -d "releases/web" ]; then
            echo -e "${YELLOW}⚠ No web build found${NC}"
            echo -e "${YELLOW}Building web app first...${NC}"
            echo ""
            flutter build web --release
            echo ""
        else
            echo -e "${GREEN}✓ Web build found${NC}"
        fi
    fi
}

# Function to stop and remove existing container
cleanup_container() {
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo -e "${YELLOW}Stopping and removing existing container...${NC}"
        docker stop "$CONTAINER_NAME" 2>/dev/null || true
        docker rm "$CONTAINER_NAME" 2>/dev/null || true
        echo -e "${GREEN}✓ Cleanup complete${NC}"
    fi
}

# Function to build Docker image
build_image() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}🔨 Building Docker image...${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if [ "$BUILD_MODE" = "prebuilt" ]; then
        echo -e "${YELLOW}Mode: Using prebuilt web assets${NC}"
        docker build -f Dockerfile.prebuilt -t "$IMAGE_NAME:latest" -t "$IMAGE_NAME:prebuilt" .
    else
        echo -e "${YELLOW}Mode: Building from source (this will take longer)${NC}"
        docker build -f Dockerfile -t "$IMAGE_NAME:latest" -t "$IMAGE_NAME:full" .
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Docker image built successfully${NC}"
    else
        echo -e "${RED}✗ Docker build failed${NC}"
        exit 1
    fi
}

# Function to run Docker container
run_container() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}🚀 Starting Docker container...${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    docker run -d \
        --name "$CONTAINER_NAME" \
        -p "$PORT:80" \
        --restart unless-stopped \
        "$IMAGE_NAME:latest"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Container started successfully${NC}"
    else
        echo -e "${RED}✗ Failed to start container${NC}"
        exit 1
    fi
}

# Function to display summary
show_summary() {
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}   Docker Setup Complete!${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}Container Information:${NC}"
    echo -e "  Name:       $CONTAINER_NAME"
    echo -e "  Image:      $IMAGE_NAME:latest"
    echo -e "  Port:       $PORT"
    echo -e "  Build Mode: $BUILD_MODE"
    echo ""
    echo -e "${YELLOW}Access the app:${NC}"
    echo -e "  ${GREEN}http://localhost:$PORT${NC}"
    echo ""
    echo -e "${YELLOW}Useful Commands:${NC}"
    echo -e "  View logs:     ${GREEN}docker logs -f $CONTAINER_NAME${NC}"
    echo -e "  Stop:          ${GREEN}docker stop $CONTAINER_NAME${NC}"
    echo -e "  Start:         ${GREEN}docker start $CONTAINER_NAME${NC}"
    echo -e "  Restart:       ${GREEN}docker restart $CONTAINER_NAME${NC}"
    echo -e "  Remove:        ${GREEN}docker rm -f $CONTAINER_NAME${NC}"
    echo -e "  Shell access:  ${GREEN}docker exec -it $CONTAINER_NAME sh${NC}"
    echo ""
    echo -e "${YELLOW}Using Docker Compose:${NC}"
    echo -e "  Start:         ${GREEN}docker-compose up -d${NC}"
    echo -e "  Stop:          ${GREEN}docker-compose down${NC}"
    echo -e "  Logs:          ${GREEN}docker-compose logs -f${NC}"
    echo ""
    
    # Wait a moment for container to fully start
    sleep 2
    
    # Check if container is healthy
    if docker ps --filter "name=$CONTAINER_NAME" --filter "health=healthy" | grep -q "$CONTAINER_NAME"; then
        echo -e "${GREEN}✓ Container is healthy and running${NC}"
    elif docker ps --filter "name=$CONTAINER_NAME" | grep -q "$CONTAINER_NAME"; then
        echo -e "${YELLOW}⚠ Container is running (health check pending...)${NC}"
    else
        echo -e "${RED}✗ Container is not running${NC}"
        echo -e "${YELLOW}Check logs with: docker logs $CONTAINER_NAME${NC}"
    fi
    echo ""
}

# Main execution
main() {
    # Parse arguments
    case "$BUILD_MODE" in
        prebuilt|pre|quick)
            BUILD_MODE="prebuilt"
            ;;
        full|source|complete)
            BUILD_MODE="full"
            ;;
        *)
            echo -e "${YELLOW}Usage: $0 [prebuilt|full]${NC}"
            echo -e "${YELLOW}  prebuilt (default): Use existing build/web files (fast)${NC}"
            echo -e "${YELLOW}  full:               Build from source in Docker (slow)${NC}"
            echo ""
            echo -e "${YELLOW}Using default: prebuilt${NC}"
            BUILD_MODE="prebuilt"
            ;;
    esac
    
    # Execute build steps
    check_docker
    check_web_build
    cleanup_container
    build_image
    run_container
    show_summary
}

# Run main
main
