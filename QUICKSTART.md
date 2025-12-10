# Quick Start Guide - Expeditious Reader

## Running the Application

### Development Mode
To run the application in development mode:
```bash
# For desktop (Linux/Windows)
flutter run -d linux    # or -d windows

# For web
flutter run -d chrome

# For Android
flutter run -d android
```

### Building Release Versions

#### Linux
```bash
flutter build linux --release
# Executable will be in: build/linux/x64/release/bundle/
```

#### Windows
```bash
flutter build windows --release
# Executable will be in: build/windows/x64/runner/Release/
```

#### Web
```bash
flutter build web --release
# Output will be in: build/web/
```

#### Android
```bash
flutter build apk --release
# APK will be in: build/app/outputs/flutter-apk/
```

## First Time Setup

1. **Install Dependencies**
   ```bash
   flutter pub get
   ```

2. **Run the App**
   ```bash
   flutter run
   ```

3. **Import Your First Book**
   - Click the "+" button in the Library screen
   - Select a PDF, EPUB, or TXT file
   - Wait for processing (may take a moment for large files)
   - Your book will appear in the library

## Features Overview

### Speed Reading
- **WPM Control**: Adjust from 100 to 1000 words per minute
- **Auto Pause**: Longer words get extra display time
- **Sentence-End Pause**: Double delay on first word after sentence punctuation
- **Chapter Navigation**: Jump between chapters with chapter indicator
- **Sentence Navigation**: Jump to next/previous sentence
- **Separate Font Size**: Independent from traditional reader font
- **Progress Tracking**: Resume exactly where you left off
- **Skip Controls**: Jump forward/backward by 10 words

### Traditional Reading
- **Instant Loading**: Books open in <100ms with lazy page calculation
- **Efficient Memory**: Only 10 pages cached at a time (LRU cache)
- **Perfect Navigation**: Binary search ensures 0-word gaps between pages
- **Multi-Column Layout**: 1-3 configurable columns (newspaper-style)
- **Dynamic Text Fitting**: Fills entire screen height with no overflow
- **Text Reflow**: Automatic text formatting for optimal column display
- **Page Navigation**: Tap left side to go back, right side to go forward
- **Separate Font Size**: Independent from speed reader font
- **Customization**: Adjust column gap and line height
- **Themes**: Choose from Light, Dark, or Sepia themes
- **Progress Saving**: Your exact word position is saved automatically

### Library Management
- **Multiple Book Import**: Select and import multiple books at once
- **Search**: Find books by title or author
- **Multi-select**: Select multiple books to delete at once
- **Custom Covers**: Upload your own cover images
- **Format Support**: PDF, EPUB, and TXT files
- **HTML Entity Decoding**: Clean text with proper character rendering

## Tips

1. **For Best Speed Reading Experience**:
   - Start at 250-300 WPM and gradually increase
   - Enable "Sentence End Pause" for better comprehension
   - Use chapter navigation to jump to sections of interest
   - Use sentence navigation to re-read important parts
   - Use the pause button to take breaks
   - Enable "Pause on Long Words" for complex text

2. **For Traditional Reading**:
   - Books load instantly regardless of size
   - Choose 2-3 columns for newspaper-style reading
   - Adjust column gap to 24-32 for comfortable spacing
   - Set line height to 1.3-1.5 for optimal readability
   - Use Sepia theme for reduced eye strain
   - Increase font size for comfortable reading
   - Navigate smoothly with perfect page alignment
   - Text automatically reflows to fill columns perfectly

3. **Library Organization**:
   - Import multiple books at once to save time
   - Use the search feature to quickly find books
   - Delete books you've finished to keep library tidy
   - Custom covers make browsing more pleasant

## Keyboard Shortcuts (Coming Soon)
- Space: Play/Pause in speed reading mode
- Left/Right Arrow: Navigate pages in traditional mode
- Escape: Return to library

## Troubleshooting

### Import Issues
- **Large PDFs**: May take time to process, be patient
- **Encrypted PDFs**: Not currently supported
- **Image-based PDFs**: Text extraction may not work
- **Web Browser**: Files are processed as bytes (no file paths), works perfectly

### Performance
- **Slow Loading**: Clear old books from library
- **Memory Issues**: Close and restart the app
- **File Not Found**: Reimport the book (desktop/mobile only)
- **Web Storage**: Books stored in browser's IndexedDB, clearing browser data will delete books

## Data Storage

All your data is stored locally:
- **Linux**: `~/.local/share/expeditiousreader/`
- **Windows**: `%APPDATA%/expeditiousreader/`
- **Web**: Browser's IndexedDB (persistent storage)
- **Android**: App-specific storage

Books are converted to plain text and stored with their metadata in JSON format.

**Note for Web Users**: Your books are stored in your browser's persistent storage. Clearing browser data will delete your library.

## Next Steps

1. Import some books
2. Try both reading modes
3. Customize your settings
4. Start reading faster!

Enjoy your reading experience! 📚⚡
