# Build Scripts Documentation

This directory contains automated build scripts for creating release versions of Expeditious Reader across multiple platforms.

## Available Scripts

### 🐧 Linux/macOS: `build_all.sh`
Bash script for building on Linux systems.

**Platforms Built:**
- ✅ Web (HTML/JavaScript/WebAssembly)
- ✅ Android APK (installable on Android devices)
- ✅ Android App Bundle (for Google Play Store)
- ✅ Linux (x64 executable bundle)
- ⊘ Windows (skipped - requires Windows host)

### 🪟 Windows: `build_all.ps1`
PowerShell script for building on Windows systems.

**Platforms Built:**
- ✅ Web (HTML/JavaScript/WebAssembly)
- ✅ Android APK (installable on Android devices)
- ✅ Android App Bundle (for Google Play Store)
- ✅ Windows (x64 executable)
- ⊘ Linux (skipped - requires Linux host)

## Prerequisites

### All Platforms
1. **Flutter SDK** - Install from [flutter.dev](https://flutter.dev)
2. **Git** - For version control
3. Ensure Flutter is in your PATH: `flutter doctor`

### For Android Builds
1. **Android SDK** - Install via Android Studio or command line tools
2. **Java JDK 11+** - Required for Android builds
3. Accept Android licenses: `flutter doctor --android-licenses`

### For Linux Builds (Linux Host)
1. **Development Libraries**:
   ```bash
   sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev
   ```

### For Windows Builds (Windows Host)
1. **Visual Studio 2022** - With "Desktop development with C++" workload
2. **Windows 10 SDK** - Usually included with Visual Studio

## Usage

### On Linux
```bash
# Make executable (first time only)
chmod +x build_all.sh

# Run the build
./build_all.sh
```

### On Windows (PowerShell)
```powershell
# Run the build
.\build_all.ps1

# If you get execution policy errors:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Output

All build artifacts are placed in the `releases/` directory:

```
releases/
├── web/                              # Web application (deploy to web server)
├── expeditiousreader-release.apk    # Android installable APK
├── expeditiousreader-release.aab    # Android App Bundle (Play Store)
├── linux-x64/                        # Linux executable bundle
└── windows-x64/                      # Windows executable bundle
```

## Build Process

Each script performs the following steps:

1. **Clean** - Removes previous build artifacts (`flutter clean`)
2. **Dependencies** - Gets latest package dependencies (`flutter pub get`)
3. **Build Each Platform** - Compiles release builds for configured platforms
4. **Copy Artifacts** - Organizes build outputs into `releases/` directory
5. **Summary** - Displays build results and artifact locations

## Distribution

### Web
Deploy the `releases/web/` directory to any static web host:
- GitHub Pages
- Netlify
- Vercel
- Firebase Hosting
- Your own web server

### Android APK
- **Direct Installation**: Share the `.apk` file for direct installation (requires "Install from Unknown Sources")
- **Testing**: Great for beta testing and internal distribution

### Android App Bundle (AAB)
- **Google Play Store**: Upload the `.aab` file to Google Play Console
- **Optimized**: Google Play generates optimized APKs for each device

### Linux
- Distribute the entire `linux-x64/` folder
- Users run the `expeditiousreader` executable
- May need to mark as executable: `chmod +x expeditiousreader`

### Windows
- Distribute the entire `windows-x64/` folder
- Users run `expeditiousreader.exe`
- Consider creating an installer (NSIS, WiX, etc.)

## Build Options

### Release Builds (Default)
All scripts build in release mode for production use:
- Optimized performance
- Smaller file sizes
- No debug information

### Custom Builds

For debug or profile builds, modify the script commands:

```bash
# Debug build
flutter build <platform> --debug

# Profile build (for performance testing)
flutter build <platform> --profile

# Split APKs by ABI (smaller individual APKs)
flutter build apk --split-per-abi
```

## Troubleshooting

### Build Fails with "Command not found"
- Ensure Flutter is installed and in your PATH
- Run `flutter doctor` to verify setup

### Android Build Fails
- Accept licenses: `flutter doctor --android-licenses`
- Check Android SDK is properly installed
- Verify Java JDK is installed

### Linux Build Fails
- Install required dependencies (see Prerequisites)
- Ensure you're on a Linux system or WSL

### Windows Build Fails
- Install Visual Studio with C++ workload
- Ensure you're on a Windows system

### Out of Memory Errors
- Increase available RAM
- Close other applications
- Build platforms individually instead of all at once

### QuotaExceededError (Web)
- This is now handled gracefully in the app
- See `QUOTA_ERROR_FIX.md` for details

## Performance Tips

### Faster Builds
```bash
# Build specific platform only
flutter build web --release
flutter build apk --release
flutter build linux --release
flutter build windows --release

# Use cached dependencies
flutter pub get --offline
```

### Smaller APK Sizes
```bash
# Split by ABI (creates multiple smaller APKs)
flutter build apk --split-per-abi --release

# Creates:
# - app-armeabi-v7a-release.apk
# - app-arm64-v8a-release.apk
# - app-x86_64-release.apk
```

## CI/CD Integration

These scripts can be integrated into CI/CD pipelines:

### GitHub Actions Example
```yaml
name: Build All Platforms
on: [push, pull_request]

jobs:
  build-linux:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: ./build_all.sh

  build-windows:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: .\build_all.ps1
```

## Version Information

To update version numbers before building:

1. Edit `pubspec.yaml`:
   ```yaml
   version: 1.0.0+1  # version+build_number
   ```

2. The version appears in:
   - Android app info
   - Windows app properties
   - Linux package metadata
   - Web app metadata

## Additional Resources

- [Flutter Build Documentation](https://docs.flutter.dev/deployment)
- [Android Publishing Guide](https://developer.android.com/studio/publish)
- [Flutter Web Deployment](https://docs.flutter.dev/deployment/web)
- Project Documentation: See `DOCUMENTATION_INDEX.md`

## Support

For issues specific to:
- **Expeditious Reader**: See project documentation
- **Flutter**: Visit [flutter.dev/docs](https://flutter.dev/docs)
- **Platform-specific**: Check platform documentation

---

**Note**: These scripts exclude macOS and iOS builds as they require a macOS host with Xcode installed.
