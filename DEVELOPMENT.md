# Development Notes

## Architecture Decisions

### Why Provider for State Management?
- Simple and built into Flutter ecosystem
- Perfect for this app's moderate complexity
- Easy to understand and maintain
- Good for cross-widget communication

### Why Local Storage?
- Matches design requirement for offline-first
- Fast access to books
- No dependency on external services
- Easy backup and restore

### Why Extract to Plain Text?
- Enables fast search and processing
- Simplifies pagination
- Reduces memory usage during reading
- Makes word-by-word display efficient

## Code Organization

### Models
- `Book`: Immutable data class with JSON serialization
- `ReadingSettings`: Custom JSON handling for Color objects

### Services Layer
- Pure business logic, no UI dependencies
- Easy to test and reuse
- Clear separation of concerns

### Providers
- Thin layer connecting services to UI
- Manages UI state
- Triggers rebuilds when data changes

### Screens
- Stateful widgets for interactive features
- Use Consumer widgets for reactive updates
- Handle user input and navigation

## Performance Considerations

### Speed Reading
- Timer-based word display
- Configurable delays with sentence-end pause detection
- Chapter and sentence navigation with position tracking
- Efficient word splitting (done once at load)
- Separate font size from traditional reader

### Traditional Reading
- Multi-column newspaper-style layout with dynamic text fitting
- Column-based pagination using ColumnTextLayout utility
- No safety margins - fills entire available height
- Word-position based progress tracking
- Text reflow removes all line breaks for optimal column display
- Separate font size from speed reader
- Minimal rebuilds using Consumer

### Library
- Lazy loading for book covers
- Grid layout for efficient display
- Multiple book import with progress tracking
- Search filtering without rebuilding entire list
- HTML entity decoding for clean text display

## Error Handling

### Import Errors
- Try-catch blocks around file parsing
- User-friendly error messages
- Graceful degradation (e.g., missing cover)

### File I/O
- Proper exception handling
- Logging to console (can be replaced with proper logging)
- Fallback values for missing data

## Security Considerations

### File Access
- Uses platform-appropriate file picker
- Scoped to document directories
- No arbitrary file system access

### Data Storage
- Local-only storage
- No network transmission
- User-controlled data deletion

## Platform Specifics

### Linux
- Uses GTK file picker
- XDG user directories
- Native window management

### Windows
- Win32 file dialogs
- AppData for storage
- Windows-specific paths

### Web
- Browser file picker with byte-based processing
- IndexedDB for storage via path_provider
- No file paths available (security restriction)
- Files processed as Uint8List bytes
- Full import/export functionality maintained
- CORS considerations

### Android
- SAF (Storage Access Framework)
- App-specific directories
- Permissions handling

## Accessibility

### Current Support
- Material Design widgets (accessible by default)
- Clear text labels
- Logical navigation flow

### Future Improvements
- Screen reader optimization
- Keyboard navigation
- High contrast themes
- Larger touch targets

## Localization

Currently English-only, but structure supports i18n:
- Use of string constants
- Separable UI text
- Ready for flutter_localizations

## Testing Strategy

### Unit Tests (Future)
- Text processor functions
- Book model serialization
- Settings validation

### Widget Tests (Basic)
- App initialization
- Navigation flow
- Screen rendering

### Integration Tests (Future)
- Book import flow
- Reading mode switching
- Progress saving

## Known Technical Debt

1. **Print Statements**: Replace with proper logging framework
2. **Hard-coded Strings**: Extract to constants/localization
3. **Radio Deprecation**: Update to RadioGroup when stable
4. **Color Deprecation**: Update to newer Color API
5. **Build Context Async**: Add mounted checks
6. **Error Recovery**: More robust error handling
7. ~~**Column Height Calculation**: Safety margins removed for optimal space usage~~ ✅ FIXED

## Build Configuration

### pubspec.yaml Notes
- Version conflicts resolved (image package)
- Platform-specific dependencies handled
- Asset paths configured

### Platform Configs
- Android: Min SDK 21 (Lollipop)
- Windows: CMake-based build
- Linux: GTK3 dependencies
- Web: WebAssembly ready

## Debugging Tips

### Common Issues

1. **Import Fails**
   - Check file permissions
   - Verify format support
   - Look for encrypted content

2. **Slow Performance**
   - Large book files
   - Too many books in library
   - Insufficient memory

3. **Build Failures**
   - Run `flutter clean`
   - Delete build folder
   - Re-run `flutter pub get`

### Development Commands

```bash
# Clean build
flutter clean && flutter pub get

# Analyze code
flutter analyze

# Run tests
flutter test

# Build for platform
flutter build linux/windows/web/apk

# Hot reload during development
# (Press 'r' in terminal)

# Hot restart
# (Press 'R' in terminal)
```

## Git Workflow (Recommended)

```bash
# Feature branches
git checkout -b feature/your-feature

# Commit conventions
git commit -m "feat: add feature"
git commit -m "fix: bug fix"
git commit -m "docs: update docs"
git commit -m "refactor: code improvement"

# Before merging
flutter analyze
flutter test
flutter build linux
```

## Performance Metrics (Estimated)

- App startup: ~2-3 seconds
- Book import (100 pages): ~5-10 seconds
- Book import (500 pages): ~20-30 seconds
- Page turn: Instant
- Search: <100ms for typical library

## Memory Usage (Approximate)

- Base app: ~50-100 MB
- Per book in library: ~1-5 MB
- Active reading session: +20-50 MB
- Cover images: ~100-500 KB each

## Future Optimization Ideas

1. **Lazy Loading**: Load book text on demand
2. **Caching**: Cache frequently accessed books
3. **Background Import**: Import books in isolate
4. **Incremental Search**: Index-based search
5. **Image Optimization**: Compress cover images
6. **Database**: Consider SQLite for large libraries

## Contributing Guidelines (If Open Source)

1. Follow existing code style
2. Add tests for new features
3. Update documentation
4. Check for analyzer warnings
5. Test on multiple platforms
6. Keep commits atomic and descriptive

## License Considerations

- Flutter: BSD 3-Clause
- Syncfusion PDF: Community license available
- EpubX: BSD-3-Clause
- Other dependencies: Check individual licenses

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Provider Package](https://pub.dev/packages/provider)
- [Syncfusion PDF](https://pub.dev/packages/syncfusion_flutter_pdf)
- [EpubX](https://pub.dev/packages/epubx)

---

**Last Updated**: December 9, 2025
**Maintainer**: Project Team
**Flutter Version**: 3.10.3+
