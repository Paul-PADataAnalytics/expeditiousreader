# Expeditious Reader

A cross-platform speed reading and ebook management application built with Flutter.

## Features

### Speed Reading Mode
- Display words one at a time at a user-defined speed (100-1000 WPM)
- Center-aligned word display for optimal reading
- Automatic pause on longer words for better comprehension
- Sentence-end pause feature (double delay on sentence boundaries)
- Chapter and sentence navigation controls
- Chapter indicator showing current chapter
- Adjustable speed controls with separate font size
- Progress tracking and resume capability

### Traditional Reading Mode
- **Lazy page loading** - Instant book opening with on-demand page calculation
- Multi-column newspaper-style layout (1-3 configurable columns)
- Text reflow for optimal column formatting (no scrolling or overflow)
- Dynamic text fitting that fills available screen height
- **Perfect bidirectional navigation** - Binary search algorithm ensures 0-word gaps
- Efficient memory usage with LRU cache (max 10 pages)
- Tap left/right to navigate pages
- Separate font size control from speed reader
- Multiple theme options (Light, Dark, Sepia)
- Adjustable column gap and line height
- Word-position based progress tracking for accuracy

### Library Management
- Import PDF, EPUB, and TXT files
- Multiple book import capability (works on all platforms including web)
- Web platform support with byte-based file processing
- Automatic text extraction and metadata collection
- HTML entity decoding for clean text display
- Cover image support with custom cover upload
- Search by title or author
- Multi-select delete
- Progress tracking for all books

### Cross-Platform Support
- Windows Desktop
- Linux Desktop
- Web Browser (with full import/export support via byte-based processing)
- Android Mobile

## Installation

### Prerequisites
- Flutter SDK (3.10.3 or higher)
- For desktop: Platform-specific build tools
- For Android: Android SDK and NDK

### Setup
```bash
# Clone the repository
cd expeditiousreader

# Get dependencies
flutter pub get

# Run the app
flutter run
```

## Building

### Quick Build - All Platforms

Automated build scripts are available to build all supported platforms at once:

**Linux/macOS:**
```bash
./build_all.sh
```

**Windows (PowerShell):**
```powershell
.\build_all.ps1
```

See [BUILD_SCRIPTS.md](BUILD_SCRIPTS.md) for detailed documentation.

### Manual Build - Individual Platforms

**Linux:**
```bash
flutter build linux --release
```

**Windows:**
```bash
flutter build windows --release
```

**Web:**
```bash
flutter build web --release
```

**Android APK:**
```bash
flutter build apk --release
```

**Android App Bundle (for Play Store):**
```bash
flutter build appbundle --release
```

All build artifacts are placed in the `build/` directory. The automated scripts copy them to `releases/` for easy distribution.

## Docker Deployment

Deploy the web app as a Docker container:

### Quick Start
```bash
# One command to build and run
./docker-build.sh

# Access at http://localhost:8080
```

### Using Docker Compose
```bash
# Start container
docker-compose up -d

# Stop container
docker-compose down
```

### Manual Docker Build
```bash
# Build web app first
flutter build web --release

# Build and run Docker container
docker build -f Dockerfile.prebuilt -t expeditiousreader-web .
docker run -d -p 8080:80 --name expeditiousreader-web expeditiousreader-web
```

See [DOCKER.md](DOCKER.md) for complete deployment guide and [DOCKER_QUICK_REF.md](DOCKER_QUICK_REF.md) for common commands.

## Usage

### Importing Books
1. Open the Library screen
2. Tap the "+" button
3. Select one or more PDF, EPUB, or TXT files (multi-select supported)
4. The books will be automatically processed and added to your library
5. Progress dialog shows import status with success/failure breakdown

### Speed Reading
1. Select a book from the library
2. Choose "Speed Read"
3. Adjust WPM using the slider
4. Use chapter/sentence navigation to jump around
5. Enable sentence-end pause for better comprehension
6. Press play to start reading
7. Your progress is automatically saved

### Traditional Reading
1. Select a book from the library
2. Choose "Traditional Read"
3. Tap left/right sides to navigate pages
4. Configure number of columns (1-3) for newspaper-style layout
5. Adjust column gap and line height for comfortable reading
6. Use settings to customize font size and appearance
7. Your progress is automatically saved

## Project Structure

```
lib/
├── main.dart                  # App entry point
├── models/                    # Data models
│   ├── book.dart
│   └── reading_settings.dart
├── providers/                 # State management
│   ├── library_provider.dart
│   └── settings_provider.dart
├── screens/                   # UI screens
│   ├── library_screen.dart
│   ├── settings_screen.dart
│   ├── speed_reader_screen.dart
│   └── traditional_reader_screen.dart
├── services/                  # Business logic
│   ├── book_parser_service.dart
│   ├── library_service.dart
│   └── settings_service.dart
├── utils/                     # Utilities
│   ├── column_text_layout.dart # Multi-column layout engine
│   └── text_processor.dart
```

## Technologies Used

- **Flutter**: Cross-platform UI framework
- **Provider**: State management
- **Syncfusion PDF**: PDF parsing
- **EpubX**: EPUB parsing
- **Shared Preferences**: Settings persistence
- **File Picker**: File import

## License

This project is open source and available for personal and commercial use.

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues.

## Roadmap

- [x] Multi-column newspaper-style layout
- [x] Separate font sizes for speed/traditional modes
- [x] Multiple book import
- [x] HTML entity decoding
- [x] Sentence-end pause feature
- [x] Chapter and sentence navigation
- [ ] Add cloud synchronization
- [ ] Support for more file formats (MOBI, AZW)
- [ ] Reading statistics and analytics
- [ ] Highlighting and note-taking
- [ ] iOS support
- [ ] Plugin system for custom importers/exporters
- [ ] Dark mode auto-switching
- [ ] Reading goals and achievements
