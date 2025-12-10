# Build script for Expeditious Reader (Windows PowerShell)
# Builds all available platforms: Android (APK & AAB), Linux, Windows, Web
# Excludes: macOS, iOS

# Enable strict error handling
$ErrorActionPreference = "Stop"

# Build output directory
$BUILD_DIR = Join-Path $PSScriptRoot "build"
$RELEASE_DIR = Join-Path $PSScriptRoot "releases"

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "   Expeditious Reader - Multi-Platform Build Script" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Create releases directory
New-Item -ItemType Directory -Force -Path $RELEASE_DIR | Out-Null

# Clean previous builds
Write-Host "🧹 Cleaning previous builds..." -ForegroundColor Yellow
flutter clean
Write-Host "✓ Clean complete" -ForegroundColor Green
Write-Host ""

# Get dependencies
Write-Host "📦 Getting dependencies..." -ForegroundColor Yellow
flutter pub get
Write-Host "✓ Dependencies installed" -ForegroundColor Green
Write-Host ""

# Function to build and copy artifacts
function Build-Platform {
    param(
        [string]$PlatformName,
        [string]$BuildCommand,
        [string]$SourcePath,
        [string]$DestName
    )
    
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "🔨 Building for $PlatformName..." -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    
    try {
        Invoke-Expression $BuildCommand
        Write-Host "✓ $PlatformName build successful" -ForegroundColor Green
        
        # Copy artifacts to release directory
        if ($SourcePath -and $DestName) {
            $fullSourcePath = Join-Path $PSScriptRoot $SourcePath
            if (Test-Path $fullSourcePath) {
                $destPath = Join-Path $RELEASE_DIR $DestName
                Copy-Item -Path $fullSourcePath -Destination $destPath -Recurse -Force
                Write-Host "✓ Artifacts copied to: $destPath" -ForegroundColor Green
            } else {
                Write-Host "⚠ Warning: Source path not found: $fullSourcePath" -ForegroundColor Yellow
            }
        }
        Write-Host ""
        return $true
    } catch {
        Write-Host "✗ $PlatformName build failed" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
        Write-Host ""
        return $false
    }
}

# Track build results
$BuildResults = @{}

# Build Web (Release)
if (Build-Platform -PlatformName "Web" `
    -BuildCommand "flutter build web --release" `
    -SourcePath "build\web" `
    -DestName "web") {
    $BuildResults["Web"] = "✓ SUCCESS"
} else {
    $BuildResults["Web"] = "✗ FAILED"
}

# Build Android APK (Release)
if (Build-Platform -PlatformName "Android APK" `
    -BuildCommand "flutter build apk --release" `
    -SourcePath "build\app\outputs\flutter-apk\app-release.apk" `
    -DestName "expeditiousreader-release.apk") {
    $BuildResults["Android APK"] = "✓ SUCCESS"
} else {
    $BuildResults["Android APK"] = "✗ FAILED"
}

# Build Android App Bundle (Release)
if (Build-Platform -PlatformName "Android App Bundle" `
    -BuildCommand "flutter build appbundle --release" `
    -SourcePath "build\app\outputs\bundle\release\app-release.aab" `
    -DestName "expeditiousreader-release.aab") {
    $BuildResults["Android App Bundle"] = "✓ SUCCESS"
} else {
    $BuildResults["Android App Bundle"] = "✗ FAILED"
}

# Build Windows (Release)
if (Build-Platform -PlatformName "Windows" `
    -BuildCommand "flutter build windows --release" `
    -SourcePath "build\windows\x64\runner\Release" `
    -DestName "windows-x64") {
    $BuildResults["Windows"] = "✓ SUCCESS"
} else {
    $BuildResults["Windows"] = "✗ FAILED"
}

# Build Linux (Release) - Only if on Windows with WSL or cross-compilation
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🔨 Checking Linux build capability..." -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

if (Test-Path "linux") {
    Write-Host "⚠ Linux build configuration found" -ForegroundColor Yellow
    Write-Host "⚠ Note: Building Linux apps from Windows requires WSL and additional setup" -ForegroundColor Yellow
    Write-Host "⚠ Skipping Linux build (build on Linux host for best results)" -ForegroundColor Yellow
    $BuildResults["Linux"] = "⊘ SKIPPED (requires Linux host)"
} else {
    Write-Host "⚠ No Linux configuration found" -ForegroundColor Yellow
    $BuildResults["Linux"] = "⊘ NOT CONFIGURED"
}
Write-Host ""

# Summary
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "   Build Summary" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

foreach ($platform in $BuildResults.Keys | Sort-Object) {
    $result = $BuildResults[$platform]
    if ($result -match "SUCCESS") {
        Write-Host "  ${platform}: $result" -ForegroundColor Green
    } elseif ($result -match "FAILED") {
        Write-Host "  ${platform}: $result" -ForegroundColor Red
    } else {
        Write-Host "  ${platform}: $result" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "Release artifacts available in: $RELEASE_DIR" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# List release directory contents
if (Test-Path $RELEASE_DIR) {
    $items = Get-ChildItem -Path $RELEASE_DIR
    if ($items) {
        Write-Host "📦 Release Contents:" -ForegroundColor Yellow
        foreach ($item in $items) {
            $size = if ($item.PSIsContainer) {
                $folderSize = (Get-ChildItem -Path $item.FullName -Recurse -File | Measure-Object -Property Length -Sum).Sum
                "{0:N2} MB" -f ($folderSize / 1MB)
            } else {
                "{0:N2} MB" -f ($item.Length / 1MB)
            }
            Write-Host "  $($item.Name)  $size"
        }
        Write-Host ""
        
        # Calculate total size
        $totalSize = (Get-ChildItem -Path $RELEASE_DIR -Recurse -File | Measure-Object -Property Length -Sum).Sum
        Write-Host "Total size: $("{0:N2} MB" -f ($totalSize / 1MB))" -ForegroundColor Yellow
        Write-Host ""
    }
}

# Check if any builds failed
$failedCount = ($BuildResults.Values | Where-Object { $_ -match "FAILED" }).Count
if ($failedCount -gt 0) {
    Write-Host "⚠ Warning: $failedCount build(s) failed" -ForegroundColor Red
    exit 1
} else {
    Write-Host "🎉 All configured builds completed successfully!" -ForegroundColor Green
    exit 0
}
