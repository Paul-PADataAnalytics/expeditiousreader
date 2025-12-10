#!/bin/bash

# Build script for Expeditious Reader
# Builds all available platforms: Android (APK & AAB), Linux, Windows, Web
# Excludes: macOS, iOS

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Build output directory
BUILD_DIR="$(pwd)/build"
RELEASE_DIR="$(pwd)/releases"

echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   Expeditious Reader - Multi-Platform Build Script${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

# Create releases directory
mkdir -p "$RELEASE_DIR"

# Clean previous builds
echo -e "${YELLOW}🧹 Cleaning previous builds...${NC}"
flutter clean
echo -e "${GREEN}✓ Clean complete${NC}"
echo ""

# Get dependencies
echo -e "${YELLOW}📦 Getting dependencies...${NC}"
flutter pub get
echo -e "${GREEN}✓ Dependencies installed${NC}"
echo ""

# Function to build and copy artifacts
build_platform() {
    local platform=$1
    local build_cmd=$2
    local source_path=$3
    local dest_name=$4
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}🔨 Building for ${platform}...${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if eval "$build_cmd"; then
        echo -e "${GREEN}✓ ${platform} build successful${NC}"
        
        # Copy artifacts to release directory
        if [ -n "$source_path" ] && [ -n "$dest_name" ]; then
            if [ -e "$source_path" ]; then
                cp -r "$source_path" "$RELEASE_DIR/$dest_name"
                echo -e "${GREEN}✓ Artifacts copied to: $RELEASE_DIR/$dest_name${NC}"
            else
                echo -e "${YELLOW}⚠ Warning: Source path not found: $source_path${NC}"
            fi
        fi
        echo ""
        return 0
    else
        echo -e "${RED}✗ ${platform} build failed${NC}"
        echo ""
        return 1
    fi
}

# Track build results
declare -A BUILD_RESULTS

# Build Web (Release)
if build_platform "Web" \
    "flutter build web --release" \
    "$BUILD_DIR/web" \
    "web"; then
    BUILD_RESULTS[web]="✓ SUCCESS"
else
    BUILD_RESULTS[web]="✗ FAILED"
fi

# Build Android APK (Release)
if build_platform "Android APK" \
    "flutter build apk --release" \
    "$BUILD_DIR/app/outputs/flutter-apk/app-release.apk" \
    "expeditiousreader-release.apk"; then
    BUILD_RESULTS[android_apk]="✓ SUCCESS"
else
    BUILD_RESULTS[android_apk]="✗ FAILED"
fi

# Build Android App Bundle (Release)
if build_platform "Android App Bundle" \
    "flutter build appbundle --release" \
    "$BUILD_DIR/app/outputs/bundle/release/app-release.aab" \
    "expeditiousreader-release.aab"; then
    BUILD_RESULTS[android_aab]="✓ SUCCESS"
else
    BUILD_RESULTS[android_aab]="✗ FAILED"
fi

# Build Linux (Release)
if build_platform "Linux" \
    "flutter build linux --release" \
    "$BUILD_DIR/linux/x64/release/bundle" \
    "linux-x64"; then
    BUILD_RESULTS[linux]="✓ SUCCESS"
else
    BUILD_RESULTS[linux]="✗ FAILED"
fi

# Build Windows (Release) - Only if on Linux with cross-compilation support
# Note: Building Windows from Linux requires special setup
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}🔨 Checking Windows build capability...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ -d "windows" ]; then
    echo -e "${YELLOW}⚠ Windows build configuration found${NC}"
    echo -e "${YELLOW}⚠ Note: Building Windows apps from Linux requires Wine and additional setup${NC}"
    echo -e "${YELLOW}⚠ Skipping Windows build (build on Windows host for best results)${NC}"
    BUILD_RESULTS[windows]="⊘ SKIPPED (requires Windows host)"
else
    echo -e "${YELLOW}⚠ No Windows configuration found${NC}"
    BUILD_RESULTS[windows]="⊘ NOT CONFIGURED"
fi
echo ""

# Summary
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   Build Summary${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

for platform in "${!BUILD_RESULTS[@]}"; do
    result="${BUILD_RESULTS[$platform]}"
    if [[ $result == *"SUCCESS"* ]]; then
        echo -e "${GREEN}  $platform: $result${NC}"
    elif [[ $result == *"FAILED"* ]]; then
        echo -e "${RED}  $platform: $result${NC}"
    else
        echo -e "${YELLOW}  $platform: $result${NC}"
    fi
done

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Release artifacts available in: $RELEASE_DIR${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

# List release directory contents
if [ -d "$RELEASE_DIR" ] && [ "$(ls -A $RELEASE_DIR)" ]; then
    echo -e "${YELLOW}📦 Release Contents:${NC}"
    ls -lh "$RELEASE_DIR" | tail -n +2 | awk '{printf "  %s  %s\n", $9, $5}'
    echo ""
fi

# Calculate total size
if [ -d "$RELEASE_DIR" ] && [ "$(ls -A $RELEASE_DIR)" ]; then
    total_size=$(du -sh "$RELEASE_DIR" | cut -f1)
    echo -e "${YELLOW}Total size: $total_size${NC}"
    echo ""
fi

# Check if any builds failed
failed_count=$(echo "${BUILD_RESULTS[@]}" | grep -o "FAILED" | wc -l)
if [ $failed_count -gt 0 ]; then
    echo -e "${RED}⚠ Warning: $failed_count build(s) failed${NC}"
    exit 1
else
    echo -e "${GREEN}🎉 All configured builds completed successfully!${NC}"
    exit 0
fi
