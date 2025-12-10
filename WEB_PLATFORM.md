# Web Platform Support

## Overview

Expeditious Reader now fully supports the web platform with seamless book import and management. Since web browsers don't provide file paths for security reasons, the application uses a byte-based approach with SharedPreferences for storage.

## Key Changes

### Storage Architecture

#### Desktop/Mobile (File System)
- Books stored as `.txt` files in `~/.local/share/expeditiousreader/books/`
- Covers stored as `.png` files in `~/.local/share/expeditiousreader/covers/`
- Library metadata in `library.json` file

#### Web (SharedPreferences)
- Book text stored in browser's local storage with key pattern: `book_text_{bookId}`
- Cover images stored as base64 strings with key pattern: `book_cover_{bookId}`
- Library metadata stored in SharedPreferences under key: `library.json`
- All data persists in browser's IndexedDB through Flutter's web implementation

### Import Flow

#### Desktop/Mobile
1. User selects files via file picker
2. File paths returned from picker
3. Files read from disk using `File` API
4. Books saved to application documents directory

#### Web
1. User selects files via browser file picker
2. File bytes loaded with `withData: true` parameter
3. Bytes processed directly without file system access
4. Books saved to SharedPreferences (browser local storage)

### Platform Detection

All platform-specific code uses the `kIsWeb` constant from `package:flutter/foundation.dart`:

```dart
if (kIsWeb) {
  // Web-specific code
} else {
  // Desktop/mobile code
}
```

## Implementation Details

### LibraryService Changes

#### New Methods
- **`importBookFromBytes()`** - Import books from byte data (web)
- **Platform-aware storage methods**:
  - `loadLibrary()` - Reads from SharedPreferences on web, file system otherwise
  - `saveLibrary()` - Writes to SharedPreferences on web, file system otherwise
  - `readBookText()` - Retrieves from SharedPreferences on web, file otherwise
  - `deleteBook()` - Removes from SharedPreferences on web, deletes files otherwise

### BookParserService Changes

#### New Methods
- **`parseBookFromBytes()`** - Entry point for byte-based parsing
- **`_parseEpubFromBytes()`** - EPUB parsing from Uint8List
- **`_parsePdfFromBytes()`** - PDF parsing from Uint8List
- **`_parseTxtFromBytes()`** - TXT parsing from Uint8List

All methods handle the same text extraction, metadata collection, and cover image extraction as their file-based counterparts.

### LibraryProvider Changes

#### New Methods
- **`importBooksFromBytes()`** - Batch import from byte arrays
  - Returns same result format as `importBooks()`
  - Shows progress dialog during import
  - Displays success/failure breakdown

### LibraryScreen Changes

#### Cover Image Display
- New `_buildCoverImage()` helper method
- On web: Uses `FutureBuilder` + `Image.memory` for base64 covers
- On desktop/mobile: Uses `Image.file` for file-based covers
- Graceful fallback to placeholder on error

#### Import Logic
- Detects platform with `kIsWeb`
- Enables `withData: true` on web to load file bytes
- Routes to appropriate import method based on platform

## Storage Limits

### Web Platform
- **SharedPreferences limit**: Typically 5-10 MB per domain (browser-dependent)
- **Recommended**: Keep library size reasonable on web
- **Large books**: May hit storage limits with multiple books
- **Solution**: Users can clear browser data if needed

### Desktop/Mobile
- Limited only by available disk space
- No practical limit for typical usage

## Testing

### Web Testing
```bash
# Run in debug mode
flutter run -d chrome

# Build for production
flutter build web --release

# Serve built files
cd build/web && python3 -m http.server 8000
```

### Cross-Platform Testing
Test the same book import on:
1. **Linux/Windows**: Verify file system storage
2. **Web**: Verify SharedPreferences storage
3. **Both**: Ensure same functionality and user experience

## Known Limitations

### Web Platform
1. **Cover image updates**: Not yet supported (would need byte-based file picker)
2. **Storage quota**: Limited by browser's local storage limits
3. **No file exports**: Can't save books back to disk on web
4. **Performance**: Large books may be slower to load than on desktop

### All Platforms
- Original file path not meaningful on web (stores filename only)
- Cover update feature disabled on web platform

## Future Improvements

1. **IndexedDB direct access**: Could increase storage capacity on web
2. **Book export**: Allow downloading books as files on web
3. **Cover updates on web**: Implement byte-based cover selection
4. **Compression**: Compress book text before storing on web
5. **Chunked storage**: Split large books across multiple keys
6. **Storage usage indicator**: Show remaining space on web

## Troubleshooting

### "No implementation found for method getApplicationDocumentsDirectory"
This error occurs if `path_provider` is called on web. The app now uses SharedPreferences on web instead, so this should be fixed.

### Books not appearing after import on web
1. Check browser console for errors
2. Verify SharedPreferences is enabled in browser
3. Check browser's storage quota
4. Try incognito mode to test with fresh storage

### Cover images not loading on web
1. Verify cover was extracted during import (check base64 data)
2. Check browser console for Image.memory errors
3. Ensure SharedPreferences has the cover data

---

**Last Updated**: December 9, 2025
**Platform Support**: Linux, Windows, Web, Android
**Web Storage**: SharedPreferences (Browser Local Storage)
