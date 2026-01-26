#!/bin/bash
# Script to prepare icons for all platforms locally

echo "Preparing icons for all platforms..."

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo "Error: ImageMagick is not installed. Please install it:"
    echo "  Ubuntu/Debian: sudo apt-get install imagemagick"
    echo "  macOS: brew install imagemagick"
    echo "  Windows: choco install imagemagick"
    exit 1
fi

# Android icons
echo "Preparing Android icons..."
mkdir -p android/app/src/main/res/mipmap-mdpi
mkdir -p android/app/src/main/res/mipmap-hdpi
mkdir -p android/app/src/main/res/mipmap-xhdpi
mkdir -p android/app/src/main/res/mipmap-xxhdpi
mkdir -p android/app/src/main/res/mipmap-xxxhdpi

convert icons/64x64.png -resize 48x48 android/app/src/main/res/mipmap-mdpi/ic_launcher.png
convert icons/64x64.png -resize 72x72 android/app/src/main/res/mipmap-hdpi/ic_launcher.png
convert icons/128x128.png -resize 96x96 android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
convert icons/128x128.png -resize 144x144 android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
convert icons/256x256.png -resize 192x192 android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png

# Windows icon
echo "Preparing Windows icon..."
mkdir -p windows/runner/resources
convert icons/64x64.png icons/128x128.png icons/256x256.png windows/runner/resources/app_icon.ico

# Web icons
echo "Preparing Web icons..."
cp icons/64x64.png web/favicon.png
cp icons/128x128.png web/icons/Icon-192.png
cp icons/256x256.png web/icons/Icon-512.png
# Maskable icons with padding
convert icons/128x128.png -gravity center -background white -extent 192x192 web/icons/Icon-maskable-192.png
convert icons/256x256.png -gravity center -background white -extent 512x512 web/icons/Icon-maskable-512.png

echo "Icons prepared successfully!"
