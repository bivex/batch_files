#!/bin/bash

# Script for removing all EspoCRM Docker containers and images
# Version: 1.0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check that the script is running in the correct directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ESPOCRM_DIR="$(dirname "$SCRIPT_DIR")"

log "Starting removal of EspoCRM Docker containers and images..."
log "EspoCRM directory: $ESPOCRM_DIR"

# Navigate to EspoCRM directory
cd "$ESPOCRM_DIR" || {
    error "Failed to navigate to EspoCRM directory: $ESPOCRM_DIR"
    exit 1
}

# Check for docker-compose.yml
if [ ! -f "docker-compose.yml" ]; then
    error "docker-compose.yml file not found in $ESPOCRM_DIR"
    exit 1
fi

log "Stopping and removing EspoCRM containers..."

# Stop and remove containers via docker-compose
if docker-compose down --volumes --remove-orphans; then
    success "EspoCRM containers successfully stopped and removed"
else
    error "Error stopping EspoCRM containers"
    exit 1
fi

log "Searching for and removing Docker images..."

# Search for images related to EspoCRM
IMAGES=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -E "(espocrm|mariadb|adminer|linuxserver)" | grep -v hwid)

if [ -n "$IMAGES" ]; then
    log "Found the following images to remove:"
    echo "$IMAGES"
    
    # Remove images
    echo "$IMAGES" | xargs docker rmi --force
    
    if [ $? -eq 0 ]; then
        success "Docker images successfully removed"
    else
        warning "Some images could not be removed (possibly being used by other containers)"
    fi
else
    success "EspoCRM images not found (already removed)"
fi

log "Cleaning up unused Docker resources..."

# Clean up Docker system
if docker system prune -f; then
    success "Docker system cleaned of unused resources"
else
    warning "Error cleaning Docker system"
fi

log "Checking results..."

# Check containers
CONTAINERS=$(docker ps -a | grep -E "(espocrm|mariadb|adminer)" | grep -v hwid || true)
if [ -z "$CONTAINERS" ]; then
    success "EspoCRM containers not found"
else
    warning "Found remaining containers:"
    echo "$CONTAINERS"
fi

# Check volumes
VOLUMES=$(docker volume ls | grep -E "(espocrm|mariadb)" | grep -v hwid || true)
if [ -z "$VOLUMES" ]; then
    success "EspoCRM volumes not found"
else
    warning "Found remaining volumes:"
    echo "$VOLUMES"
fi

# Check images
REMAINING_IMAGES=$(docker images | grep -E "(espocrm|mariadb|adminer|linuxserver)" | grep -v hwid || true)
if [ -z "$REMAINING_IMAGES" ]; then
    success "EspoCRM images not found"
else
    warning "Found remaining images:"
    echo "$REMAINING_IMAGES"
fi

# Show freed space
log "Docker disk usage information:"
docker system df

success "EspoCRM removal script completed!"
log "Now you can start a new installation with: docker-compose up -d" 
