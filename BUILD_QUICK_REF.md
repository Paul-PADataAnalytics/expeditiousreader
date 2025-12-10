# Build Scripts - Quick Reference

## 🚀 Quick Start

### Linux/macOS
```bash
chmod +x build_all.sh  # First time only
./build_all.sh
```

### Windows
```powershell
.\build_all.ps1
```

## 📦 What Gets Built

| Platform | Output Location | Size (approx) |
|----------|----------------|---------------|
| **Web** | `releases/web/` | ~5-10 MB |
| **Android APK** | `releases/expeditiousreader-release.apk` | ~20-30 MB |
| **Android AAB** | `releases/expeditiousreader-release.aab` | ~15-25 MB |
| **Linux** | `releases/linux-x64/` | ~40-60 MB |
| **Windows** | `releases/windows-x64/` | ~40-60 MB |

## 🎯 Individual Builds

Sometimes you only need one platform:

```bash
# Web only (works everywhere)
flutter build web --release

# Android APK only
flutter build apk --release

# Linux only (on Linux)
flutter build linux --release

# Windows only (on Windows)
flutter build windows --release
```

## ⚡ Build Time Estimates

| Platform | Clean Build | Incremental |
|----------|-------------|-------------|
| Web | ~2-3 min | ~30-60 sec |
| Android APK | ~3-5 min | ~1-2 min |
| Android AAB | ~3-5 min | ~1-2 min |
| Linux | ~2-4 min | ~30-90 sec |
| Windows | ~2-4 min | ~30-90 sec |
| **All (script)** | ~10-20 min | N/A |

*Times vary based on hardware and caching*

## 🛠️ Before Building

Make sure you have:
- ✅ Flutter SDK installed
- ✅ `flutter doctor` shows no critical errors
- ✅ For Android: Android SDK and licenses accepted
- ✅ For Linux: Development libraries installed
- ✅ For Windows: Visual Studio with C++ workload

## 📱 Deployment Guide

### Web
```bash
# Local test
cd releases/web
python -m http.server 8000
# Visit http://localhost:8000

# Deploy to hosting (examples)
# GitHub Pages, Netlify, Vercel, etc.
```

### Android APK
```bash
# Install on device via ADB
adb install releases/expeditiousreader-release.apk

# Or share the .apk file directly
```

### Android App Bundle
- Upload to Google Play Console
- Requires developer account ($25 one-time fee)

### Linux
```bash
# Make executable
cd releases/linux-x64
chmod +x expeditiousreader
./expeditiousreader
```

### Windows
- Double-click `expeditiousreader.exe` in `releases/windows-x64/`

## 🐛 Common Issues

**"flutter: command not found"**
- Add Flutter to PATH
- Run `flutter doctor`

**Android build fails**
```bash
flutter doctor --android-licenses
```

**Out of disk space**
```bash
flutter clean
```

**Build cache issues**
```bash
flutter clean
flutter pub get
# Try build again
```

## 💡 Pro Tips

1. **Faster Android builds**: 
   ```bash
   flutter build apk --split-per-abi
   # Creates separate APKs per architecture (smaller)
   ```

2. **Debug build for testing**:
   ```bash
   flutter build <platform> --debug
   ```

3. **Profile build for performance testing**:
   ```bash
   flutter build <platform> --profile
   ```

4. **Check what will be built**:
   ```bash
   flutter devices
   ```

5. **Version bumping** (edit `pubspec.yaml`):
   ```yaml
   version: 1.0.0+1  # version+build_number
   ```

## 📚 More Information

- Full documentation: [BUILD_SCRIPTS.md](BUILD_SCRIPTS.md)
- Flutter deployment: https://docs.flutter.dev/deployment
- Project docs: [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md)

---

**Need help?** Run `flutter doctor -v` and check for issues.
