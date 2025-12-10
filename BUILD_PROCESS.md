# Build Process Visualization

## 🔄 Build Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                   START BUILD SCRIPT                         │
│              (build_all.sh / build_all.ps1)                 │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  Step 1: Clean Previous Builds                              │
│  ► flutter clean                                             │
│  ► Remove old build artifacts                               │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  Step 2: Get Dependencies                                    │
│  ► flutter pub get                                           │
│  ► Download/update packages                                 │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  Step 3: Build Platforms (in sequence)                      │
└────────────────────────┬────────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┬───────────────┐
         ▼               ▼               ▼               ▼
    ┌────────┐      ┌─────────┐    ┌─────────┐    ┌──────────┐
    │  Web   │      │ Android │    │ Android │    │  Linux/  │
    │ Build  │      │   APK   │    │   AAB   │    │ Windows  │
    └───┬────┘      └────┬────┘    └────┬────┘    └────┬─────┘
        │                │              │              │
        │ 2-3 min        │ 3-5 min      │ 3-5 min      │ 2-4 min
        │                │              │              │
        ▼                ▼              ▼              ▼
    ┌────────┐      ┌─────────┐    ┌─────────┐    ┌──────────┐
    │build/  │      │build/app│    │build/app│    │build/    │
    │web/    │      │/outputs/│    │/outputs/│    │linux/ or │
    │        │      │apk/     │    │bundle/  │    │windows/  │
    └───┬────┘      └────┬────┘    └────┬────┘    └────┬─────┘
        │                │              │              │
        └────────────────┴──────────────┴──────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  Step 4: Organize Release Artifacts                         │
│  ► Copy builds to releases/ directory                       │
│  ► Rename for clarity                                       │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                  RELEASE DIRECTORY                           │
│                                                              │
│  releases/                                                   │
│  ├── web/                     [Deploy to hosting]          │
│  ├── expeditiousreader.apk   [Android install]             │
│  ├── expeditiousreader.aab   [Play Store]                  │
│  ├── linux-x64/               [Linux distribution]         │
│  └── windows-x64/             [Windows distribution]       │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  Step 5: Display Build Summary                              │
│  ► List all platforms built                                 │
│  ► Show file sizes                                          │
│  ► Report success/failures                                  │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
                    ┌─────────┐
                    │  DONE!  │
                    └─────────┘
```

## 📊 Platform Build Matrix

### Linux Host Running `build_all.sh`

| Platform | Status | Output | Size | Time |
|----------|--------|--------|------|------|
| Web | ✅ Built | `releases/web/` | ~8 MB | 2-3 min |
| Android APK | ✅ Built | `releases/*.apk` | ~25 MB | 3-5 min |
| Android AAB | ✅ Built | `releases/*.aab` | ~20 MB | 3-5 min |
| Linux | ✅ Built | `releases/linux-x64/` | ~50 MB | 2-4 min |
| Windows | ⊘ Skipped | - | - | - |

**Total Time**: ~10-17 minutes  
**Total Size**: ~103 MB

### Windows Host Running `build_all.ps1`

| Platform | Status | Output | Size | Time |
|----------|--------|--------|------|------|
| Web | ✅ Built | `releases/web/` | ~8 MB | 2-3 min |
| Android APK | ✅ Built | `releases/*.apk` | ~25 MB | 3-5 min |
| Android AAB | ✅ Built | `releases/*.aab` | ~20 MB | 3-5 min |
| Windows | ✅ Built | `releases/windows-x64/` | ~50 MB | 2-4 min |
| Linux | ⊘ Skipped | - | - | - |

**Total Time**: ~10-17 minutes  
**Total Size**: ~103 MB

## 🎯 Build Decision Tree

```
                    Which platform?
                          │
         ┌────────────────┼────────────────┐
         ▼                ▼                ▼
    Need all?        Single OS?      Just Web?
         │                │                │
         │                ▼                ▼
         │           OS-specific    flutter build
         │           build only      web --release
         │                │                │
         ▼                │                │
    ./build_all.sh       │                │
         │               │                │
         │               ▼                │
         │         flutter build          │
         │         <platform> --release   │
         │                                │
         └────────────────┬───────────────┘
                          ▼
                  Build Complete!
```

## 💡 When to Use Which Script

### Use `build_all.sh` or `build_all.ps1` when:
- ✅ You need builds for multiple platforms
- ✅ You're preparing a release
- ✅ You want organized output in one place
- ✅ You need both Android formats (APK + AAB)
- ✅ You're setting up CI/CD

### Use individual `flutter build` when:
- ✅ You only need one platform
- ✅ You're doing rapid testing/iteration
- ✅ You need debug or profile builds
- ✅ You want to use special flags (--split-per-abi, etc.)

## 🚀 Example Usage Scenarios

### Scenario 1: First Release
```bash
# You want to release v1.0.0 to all platforms
./build_all.sh

# Result: 4 platforms built and ready to distribute
# - Web → Deploy to GitHub Pages
# - APK → Beta testers
# - AAB → Google Play Store
# - Linux → Direct download from website
```

### Scenario 2: Quick Web Update
```bash
# Small bug fix, only need web version
flutter build web --release

# Result: Fast build, web only
# Deploy: Copy build/web/ to hosting
```

### Scenario 3: Android Testing
```bash
# Testing new feature on Android device
flutter build apk --debug
adb install build/app/outputs/flutter-apk/app-debug.apk

# Result: Debug build with hot reload support
```

### Scenario 4: CI/CD Pipeline
```yaml
# GitHub Actions workflow
- name: Build all platforms
  run: ./build_all.sh
  
- name: Upload artifacts
  uses: actions/upload-artifact@v3
  with:
    path: releases/
```

## 📦 Output Directory Structure

```
your-project/
│
├── build/                    ← Flutter's build directory
│   ├── web/                 (temporary build output)
│   ├── app/outputs/         (temporary Android builds)
│   ├── linux/x64/           (temporary Linux builds)
│   └── windows/x64/         (temporary Windows builds)
│
└── releases/                 ← Organized by build scripts
    ├── web/                 ✅ Ready to deploy
    │   ├── index.html
    │   ├── main.dart.js
    │   └── ...
    │
    ├── expeditiousreader-release.apk  ✅ Ready to install
    ├── expeditiousreader-release.aab  ✅ Ready for Play Store
    │
    ├── linux-x64/           ✅ Ready to distribute
    │   ├── expeditiousreader (executable)
    │   ├── lib/
    │   └── data/
    │
    └── windows-x64/         ✅ Ready to distribute
        ├── expeditiousreader.exe
        ├── flutter_windows.dll
        └── data/
```

## 🔍 Build Script Features

### Error Handling
```bash
# If a build fails:
- ✅ Script continues with other platforms
- ✅ Failed builds are reported in summary
- ✅ Non-zero exit code if any failures
- ✅ Detailed error messages
```

### Progress Tracking
```bash
# During build:
🧹 Cleaning previous builds...
✓ Clean complete

📦 Getting dependencies...
✓ Dependencies installed

🔨 Building for Web...
✓ Web build successful
✓ Artifacts copied

[... continues for each platform ...]
```

### Summary Report
```bash
# At the end:
════════════════════════════════════════
   Build Summary
════════════════════════════════════════
  web: ✓ SUCCESS
  android_apk: ✓ SUCCESS
  android_aab: ✓ SUCCESS
  linux: ✓ SUCCESS
  windows: ⊘ SKIPPED

📦 Release Contents:
  web              8.2 MB
  *.apk           24.5 MB
  *.aab           19.8 MB
  linux-x64       51.3 MB

Total size: 103.8 MB

🎉 All configured builds completed successfully!
```

## 🎨 Color Coding

The scripts use color-coded output for better readability:

- 🔵 **Blue**: Section headers and informational messages
- 🟡 **Yellow**: In-progress operations
- 🟢 **Green**: Successful completions
- 🔴 **Red**: Errors and failures
- ⚪ **Default**: Normal output

## 📝 Next Steps After Building

1. **Test the builds**:
   ```bash
   # Web
   cd releases/web && python -m http.server 8000
   
   # Android
   adb install releases/expeditiousreader-release.apk
   
   # Linux
   cd releases/linux-x64 && ./expeditiousreader
   
   # Windows
   # Double-click expeditiousreader.exe
   ```

2. **Create checksums** (optional):
   ```bash
   cd releases
   sha256sum * > checksums.txt
   ```

3. **Distribute**:
   - Upload to hosting/stores
   - Create GitHub release
   - Update documentation

---

**Ready to build?** See [BUILD_QUICK_REF.md](BUILD_QUICK_REF.md) for quick commands!
