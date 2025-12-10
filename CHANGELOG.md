# Changelog - Expeditious Reader

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added - December 9, 2025

#### Web Platform Support
- **SharedPreferences-based storage** for web platform (replaces file system)
- **Byte-based book import** using FilePicker with `withData: true`
- **Web-compatible cover image display** using `Image.memory` for base64 data
- **Platform detection** using `kIsWeb` flag throughout codebase
- **Seamless storage abstraction** - same API for desktop, mobile, and web
- **`importBooksFromBytes()` method** in LibraryProvider for web platform
- **`importBookFromBytes()` method** in LibraryService for byte-based book processing
- **Byte-based parsing methods** in BookParserService:
  - `parseBookFromBytes()` - main entry point for byte-based parsing
  - `_parseEpubFromBytes()` - EPUB parsing from bytes
  - `_parsePdfFromBytes()` - PDF parsing from bytes
  - `_parseTxtFromBytes()` - TXT parsing from bytes
- **Web storage methods** in LibraryService:
  - `loadLibrary()` - reads from SharedPreferences on web
  - `saveLibrary()` - writes to SharedPreferences on web
  - `readBookText()` - retrieves book content from SharedPreferences on web
  - `deleteBook()` - removes book data from SharedPreferences on web

#### Traditional Reader Enhancements
- **Lazy page loading** - Pages calculated on-demand instead of at startup
- **Instant book opening** - First page renders in <100ms regardless of book size
- **Efficient memory usage** - LRU cache keeps only 10 pages in memory
- **Perfect backward navigation** - Binary search algorithm ensures 0-word gaps between pages
- **Multi-column newspaper-style layout** (1-3 configurable columns)
- **Dynamic text fitting** that fills entire screen height without overflow or scrolling
- **Text reflow system** removes all line breaks for optimal column display
- **Column layout engine** (`lib/utils/column_text_layout.dart`) with word-position tracking
- **Separate font size** independent from speed reader (12-72pt)
- **Column gap control** (16-64px configurable spacing)
- **Line height adjustment** (1.0-2.5x configurable)
- **Zero safety margins** for maximum content display
- **Word-position based progress tracking** for accurate resume points

#### Speed Reader Enhancements
- **Sentence-end pause feature** applies double delay after `.`, `!`, `?` for better comprehension
- **Chapter indicator** displays current chapter number in app bar
- **Chapter navigation** with next/previous chapter controls
- **Sentence navigation** with next/previous sentence jump controls
- **Separate font size** independent from traditional reader (12-72pt)
- **Improved chapter detection** using ratio-based position mapping

#### Library Enhancements
- **Multiple book import** capability with file picker multi-select
- **Import progress tracking** shows "Importing X book(s)..." dialog
- **Detailed import results** displays success/failure breakdown with error messages
- **HTML entity decoding** for clean text rendering
  - Hexadecimal entities (`&#x2009;`, `&#xA0;`)
  - Decimal entities (`&#8201;`, `&#160;`)
  - Named entities (`&ensp;`, `&emsp;`, `&bull;`, `&copy;`)
  - Special space conversion (thin space, non-breaking space, em space)
  - Zero-width character removal (`&#x200B;`, `&#x200C;`, `&#x200D;`)

### Changed
- **Traditional reader settings** now include separate font size slider
- **Speed reader settings** now include separate font size slider and sentence-end pause toggle
- **Column rendering** uses `MainAxisSize.max` and `CrossAxisAlignment.stretch` for full height
- **Column height calculation** removed safety margins for optimal space usage
- **Chapter position tracking** improved with ratio-based mapping for accuracy

### Fixed
- **Column height issue** where columns were not filling available screen height (430px → 524px)
- **Double-padding bug** in column width calculations
- **Chapter indicator accuracy** now correctly tracks chapters regardless of text processing
- **Web platform storage** fixed MissingPluginException by using SharedPreferences instead of path_provider

### Technical Details

#### New Files
- `/lib/utils/column_text_layout.dart` - Column layout engine with `ColumnPage` and `ColumnTextLayout` classes

#### Modified Files
- `/lib/models/reading_settings.dart` - Added `speedReaderFontSize`, `traditionalFontSize`, `numberOfColumns`, `columnGap`, `lineHeight`, `pauseOnSentenceEnd`
- `/lib/providers/library_provider.dart` - Added `importBooks()` and `importBooksFromBytes()` methods for file/byte import
- `/lib/providers/settings_provider.dart` - Added `updateSpeedReaderFontSize()` and `updateTraditionalFontSize()` methods
- `/lib/screens/library_screen.dart` - Updated import UI with multi-select, web support, and `_buildCoverImage()` helper
- `/lib/screens/settings_screen.dart` - Added separate font sliders and sentence pause toggle
- `/lib/screens/speed_reader_screen.dart` - Added chapter/sentence navigation, pause feature, chapter indicator
- `/lib/screens/traditional_reader_screen.dart` - Implemented column layout with dynamic text fitting
- `/lib/services/book_parser_service.dart` - Added `_decodeHtmlEntities()` and byte-based parsing methods
- `/lib/services/library_service.dart` - Added web platform support with SharedPreferences storage

#### Performance Improvements
- Column layout uses incremental batching (20 pages at a time)
- TextPainter-based width measurements (5% safety margin)
- Word-position based progress tracking (efficient resume)
- Ratio-based chapter detection (independent of text cleaning)

## [1.0.0] - Initial Release

### Added
- Speed reading mode with variable WPM (100-1000)
- Traditional reading mode with page-based navigation
- Library management with search and multi-select delete
- PDF, EPUB, and TXT file support
- Cover image extraction and custom upload
- Progress tracking and resume capability
- Multiple themes (Light, Dark, Sepia)
- Cross-platform support (Linux, Windows, Web, Android)
- Chapter detection and TOC filtering
- Automatic text extraction and metadata collection

---

**Format**: Based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
**Versioning**: Follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
