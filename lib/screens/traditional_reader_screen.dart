import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../providers/library_provider.dart';
import '../providers/settings_provider.dart';
import '../services/library_service.dart';
import '../utils/column_text_layout.dart';

class TraditionalReaderScreen extends StatefulWidget {
  final Book book;

  const TraditionalReaderScreen({super.key, required this.book});

  @override
  State<TraditionalReaderScreen> createState() =>
      _TraditionalReaderScreenState();
}

class _TraditionalReaderScreenState extends State<TraditionalReaderScreen> {
  final LibraryService _libraryService = LibraryService();
  final GlobalKey _contentKey = GlobalKey();

  // Lazy loading: cache pages by their starting word index
  final Map<int, ColumnPage> _pageCache = {};
  ColumnPage? _currentPage;
  int _currentWordPosition = 0;

  List<String> _words = [];
  bool _isLoading = true;
  final String _loadingMessage = 'Loading book...';

  // Layout parameters (cached after first calculation)
  double? _cachedAvailableWidth;
  double? _cachedAvailableHeight;
  TextStyle? _cachedTextStyle;

  // Store provider reference to use in dispose
  LibraryProvider? _libraryProvider;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get and store the provider reference when dependencies are available
    _libraryProvider ??= context.read<LibraryProvider>();
  }

  @override
  void dispose() {
    _saveProgress();
    super.dispose();
  }

  Future<void> _loadBook() async {
    try {
      final text = await _libraryService.readBookText(widget.book);

      // For traditional reading, reflow text by removing all line breaks
      // This allows proper column-based pagination
      final reflowedText = text
          .replaceAll('\r\n', ' ') // Windows line endings
          .replaceAll('\n', ' ') // Unix line endings
          .replaceAll('\r', ' ') // Old Mac line endings
          .replaceAll('\t', ' ') // Tabs
          .replaceAll(RegExp(r'\s+'), ' ') // Multiple spaces to single space
          .trim();

      _words = reflowedText.split(' ');

      // Set initial position from saved progress
      _currentWordPosition = widget.book.currentPosition.clamp(
        0,
        _words.length - 1,
      );

      // Wait for first frame to get accurate dimensions
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _layoutCurrentPage();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading book: $e')));
    }
  }

  Future<void> _layoutCurrentPage() async {
    final settings = context.read<SettingsProvider>().settings;
    final renderBox =
        _contentKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) {
      // Try again on next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _layoutCurrentPage();
      });
      return;
    }

    final size = renderBox.size;

    // Account for the padding that will be applied in the rendering
    const padding = 32.0;
    final availableWidth = size.width - (padding * 2);
    final availableHeight = size.height - (padding * 2);

    // ignore: avoid_print
    print(
      '[TraditionalReader] Layout: Screen=${size.width}x${size.height}, Available=${availableWidth}x$availableHeight, Padding=$padding',
    );

    // Cache layout parameters
    _cachedAvailableWidth = availableWidth;
    _cachedAvailableHeight = availableHeight;
    // Bake text scaling into font size to ensure calculation and rendering match
    final textScaleFactor = MediaQuery.of(context).textScaler.scale(1.0);
    _cachedTextStyle = TextStyle(
      fontSize: settings.traditionalFontSize * textScaleFactor,
      color: settings.textColor,
      fontFamily: settings.fontFamily,
      height: settings.lineHeight,
    );

    // Calculate just the current page
    final page = await _calculatePage(_currentWordPosition);

    if (!mounted) return;

    setState(() {
      _currentPage = page;
      _isLoading = false;
    });
  }

  /// Calculate a single page starting from the given word index
  Future<ColumnPage> _calculatePage(int startWordIndex) async {
    // Check cache first
    if (_pageCache.containsKey(startWordIndex)) {
      return _pageCache[startWordIndex]!;
    }

    final settings = context.read<SettingsProvider>().settings;

    // Calculate the page
    final page = await Future.microtask(() {
      return ColumnTextLayout.layoutText(
        text: '',
        availableWidth: _cachedAvailableWidth!,
        availableHeight: _cachedAvailableHeight!,
        textStyle: _cachedTextStyle!,
        numberOfColumns: settings.numberOfColumns,
        columnGap: settings.columnGap,
        horizontalPadding: 0,
        verticalPadding: 0,
        maxPages: 1, // Only calculate one page
        startWordIndex: startWordIndex,
        preProcessedWords: _words,
        textScaler: TextScaler.noScaling, // Scaling is baked into fontSize
      );
    });

    if (page.isNotEmpty) {
      // Cache the page (keep cache size reasonable)
      _pageCache[startWordIndex] = page.first;

      // Limit cache size to prevent memory issues (keep last 10 pages)
      if (_pageCache.length > 10) {
        final keysToRemove = _pageCache.keys.toList()..sort();
        final currentIndex = keysToRemove.indexOf(startWordIndex);

        // Remove pages far from current position
        for (var i = 0; i < keysToRemove.length; i++) {
          if ((i < currentIndex - 5) || (i > currentIndex + 5)) {
            _pageCache.remove(keysToRemove[i]);
          }
        }
      }

      return page.first;
    }

    // Fallback: return empty page
    return ColumnPage(
      startWordIndex: startWordIndex,
      endWordIndex: startWordIndex,
      columns: [],
    );
  }

  /// Find the start of the previous page by working backward
  Future<int> _findPreviousPageStart(int currentPageStart) async {
    // We need to find the word index that, when laid out as a page,
    // ends exactly at currentPageStart (or as close as possible)

    if (currentPageStart <= 0) {
      return 0;
    }

    // Binary search to find the page that ends closest to currentPageStart
    int searchStart = 0;
    int searchEnd = currentPageStart - 1;
    int bestCandidate = 0;
    int bestEndDifference = currentPageStart; // How far off from target

    // Start with a guess based on current page size
    final currentPage = _currentPage;
    if (currentPage != null && currentPage.wordCount > 0) {
      searchStart = (currentPageStart - currentPage.wordCount * 1.5)
          .round()
          .clamp(0, searchEnd);
    } else {
      searchStart = (currentPageStart - 200).clamp(0, searchEnd);
    }

    while (searchStart <= searchEnd) {
      final mid = (searchStart + searchEnd) ~/ 2;
      final testPage = await _calculatePage(mid);

      final endDifference = (testPage.endWordIndex - currentPageStart).abs();

      // Track the best candidate (closest to ending at currentPageStart)
      if (endDifference < bestEndDifference) {
        bestCandidate = testPage.startWordIndex;
        bestEndDifference = endDifference;
      }

      // If this page ends exactly at currentPageStart, we found it!
      if (testPage.endWordIndex == currentPageStart) {
        return testPage.startWordIndex;
      } else if (testPage.endWordIndex < currentPageStart) {
        // Page ends before target, search later (higher word indices)
        searchStart = mid + 1;
      } else {
        // Page ends after target, search earlier (lower word indices)
        searchEnd = mid - 1;
      }
    }

    // If we didn't find exact match, use the best candidate
    if (bestEndDifference <= 50) {
      return bestCandidate;
    }

    return 0;
  }

  /// Recalculate current page when settings change
  Future<void> _relayoutPage() async {
    if (_currentPage == null) return;

    // Clear the cache since layout parameters have changed
    _pageCache.clear();

    // Clear cached layout parameters to force recalculation
    _cachedTextStyle = null;

    // Get current position before recalculating
    final currentPosition = _currentPage!.startWordIndex;

    // Recalculate with new settings
    final settings = context.read<SettingsProvider>().settings;

    // Update cached text style
    _cachedTextStyle = TextStyle(
      fontSize: settings.traditionalFontSize,
      color: settings.textColor,
      fontFamily: settings.fontFamily,
      height: settings.lineHeight,
    );

    // Recalculate current page
    final newPage = await _calculatePage(currentPosition);

    if (!mounted) return;

    setState(() {
      _currentPage = newPage;
    });
  }

  void _saveProgress() {
    if (_currentPage == null) return;

    final wordPosition = _currentPage!.startWordIndex;

    // Use stored provider reference instead of context.read
    _libraryProvider?.updateProgress(widget.book.id, position: wordPosition);
  }

  Future<void> _nextPage() async {
    if (_currentPage == null || _currentPage!.endWordIndex >= _words.length)
      return;

    // Calculate next page starting from where current page ends
    final nextPage = await _calculatePage(_currentPage!.endWordIndex);

    if (!mounted) return;

    setState(() {
      _currentPage = nextPage;
      _currentWordPosition = nextPage.startWordIndex;
    });
    _saveProgress();
  }

  Future<void> _previousPage() async {
    if (_currentPage == null || _currentPage!.startWordIndex <= 0) return;

    // Find where the previous page starts
    final previousPageStart = await _findPreviousPageStart(
      _currentPage!.startWordIndex,
    );
    final previousPage = await _calculatePage(previousPageStart);

    if (!mounted) return;

    setState(() {
      _currentPage = previousPage;
      _currentWordPosition = previousPage.startWordIndex;
    });
    _saveProgress();
  }

  double _getProgress() {
    if (_currentPage == null || _words.isEmpty) return 0.0;

    return _currentPage!.startWordIndex / _words.length;
  }

  bool _canGoNext() {
    return _currentPage != null && _currentPage!.endWordIndex < _words.length;
  }

  bool _canGoPrevious() {
    return _currentPage != null && _currentPage!.startWordIndex > 0;
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;

    return Scaffold(
      backgroundColor: settings.backgroundColor,
      appBar: AppBar(
        title: Text(widget.book.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(value: _getProgress(), minHeight: 4),

          // Page content with LayoutBuilder to detect size changes
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Check if dimensions have changed significantly (more than 10px)
                final needsRelayout =
                    _cachedAvailableWidth == null ||
                    _cachedAvailableHeight == null ||
                    (constraints.maxWidth - (_cachedAvailableWidth! + 64))
                            .abs() >
                        10 ||
                    (constraints.maxHeight - (_cachedAvailableHeight! + 64))
                            .abs() >
                        10;

                if (needsRelayout && !_isLoading && _words.isNotEmpty) {
                  // Schedule relayout after this frame
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _layoutCurrentPage();
                  });
                }

                return GestureDetector(
                  key: _contentKey,
                  onTapUp: (details) {
                    final width = MediaQuery.of(context).size.width;
                    if (details.localPosition.dx > width * 0.6) {
                      _nextPage();
                    } else if (details.localPosition.dx < width * 0.4) {
                      _previousPage();
                    }
                  },
                  child: Container(
                    color: settings.backgroundColor,
                    child: _isLoading
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 16),
                                Text(
                                  _loadingMessage,
                                  style: TextStyle(color: settings.textColor),
                                ),
                              ],
                            ),
                          )
                        : _currentPage == null
                        ? const Center(child: Text('No content available'))
                        : _buildPageContent(settings),
                  ),
                );
              },
            ),
          ),

          // Page indicator and controls
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: settings.backgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _canGoPrevious() ? _previousPage : null,
                ),
                Text(
                  'Position: ${_currentWordPosition + 1}  •  ${(_getProgress() * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: settings.textColor.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _canGoNext() ? _nextPage : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(settings) {
    if (_currentPage == null) {
      return const Center(child: Text('No content'));
    }

    final page = _currentPage!;
    // Use the cached text style that was used to Calculate this page.
    // This prevents "Old Content + New Style = Overflow" glitches while re-layout is in progress.
    final textStyle =
        _cachedTextStyle ??
        TextStyle(
          fontSize: settings.traditionalFontSize,
          color: settings.textColor,
          fontFamily: settings.fontFamily,
          height: settings.lineHeight,
        );

    // Build columns with proper spacing
    final List<Widget> columnWidgets = [];
    for (int i = 0; i < page.columns.length; i++) {
      final columnLines = page.columns[i];

      // Add the column content
      columnWidgets.add(
        Expanded(
          child: ClipRect(
            child: Text(
              columnLines.join('\n'),
              style: textStyle,
              textAlign: TextAlign.left,
              overflow: TextOverflow.clip,
              textScaler:
                  TextScaler.noScaling, // Critical: prevents double-scaling
            ),
          ),
        ),
      );

      // Add gap between columns (but not after the last column)
      if (i < page.columns.length - 1) {
        columnWidgets.add(SizedBox(width: settings.columnGap));
      }
    }

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.stretch, // Changed from start to stretch
        children: columnWidgets,
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reading Settings'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Font Size'),
              Consumer<SettingsProvider>(
                builder: (context, provider, child) => Slider(
                  value: provider.settings.traditionalFontSize,
                  min: 12,
                  max: 72,
                  divisions: 60,
                  label: provider.settings.traditionalFontSize.toStringAsFixed(
                    0,
                  ),
                  onChanged: (value) {
                    provider.updateTraditionalFontSize(value);
                    // Re-layout current page with new settings
                    _relayoutPage();
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Text('Number of Columns'),
              Consumer<SettingsProvider>(
                builder: (context, provider, child) => Slider(
                  value: provider.settings.numberOfColumns.toDouble(),
                  min: 1,
                  max: 3,
                  divisions: 2,
                  label: provider.settings.numberOfColumns.toString(),
                  onChanged: (value) {
                    provider.updateSettings(
                      provider.settings.copyWith(
                        numberOfColumns: value.toInt(),
                      ),
                    );
                    // Re-layout current page with new settings
                    _relayoutPage();
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Text('Column Gap'),
              Consumer<SettingsProvider>(
                builder: (context, provider, child) => Slider(
                  value: provider.settings.columnGap,
                  min: 16,
                  max: 64,
                  divisions: 12,
                  label: provider.settings.columnGap.toStringAsFixed(0),
                  onChanged: (value) {
                    provider.updateSettings(
                      provider.settings.copyWith(columnGap: value),
                    );
                    // Re-layout current page with new settings
                    _relayoutPage();
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Text('Line Height'),
              Consumer<SettingsProvider>(
                builder: (context, provider, child) => Slider(
                  value: provider.settings.lineHeight,
                  min: 1.0,
                  max: 2.5,
                  divisions: 15,
                  label: provider.settings.lineHeight.toStringAsFixed(1),
                  onChanged: (value) {
                    provider.updateSettings(
                      provider.settings.copyWith(lineHeight: value),
                    );
                    // Re-layout current page with new settings
                    _relayoutPage();
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Text('Theme'),
              Consumer<SettingsProvider>(
                builder: (context, provider, child) => Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Light'),
                      selected:
                          provider.settings.backgroundColor == Colors.white,
                      onSelected: (selected) {
                        if (selected) {
                          provider.updateColors(
                            backgroundColor: Colors.white,
                            textColor: Colors.black,
                          );
                        }
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Dark'),
                      selected:
                          provider.settings.backgroundColor == Colors.black,
                      onSelected: (selected) {
                        if (selected) {
                          provider.updateColors(
                            backgroundColor: Colors.black,
                            textColor: Colors.white,
                          );
                        }
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Sepia'),
                      selected:
                          provider.settings.backgroundColor ==
                          const Color(0xFFF4ECD8),
                      onSelected: (selected) {
                        if (selected) {
                          provider.updateColors(
                            backgroundColor: const Color(0xFFF4ECD8),
                            textColor: const Color(0xFF5B4636),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
