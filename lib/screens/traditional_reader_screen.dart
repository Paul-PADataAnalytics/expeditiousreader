import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../models/reading_settings.dart';
import '../providers/library_provider.dart';
import '../providers/settings_provider.dart';
import '../services/library_service.dart';
import '../utils/column_text_layout.dart';
import '../utils/text_processor.dart';
import '../widgets/reader_shared_widgets.dart';
import 'speed_reader_screen.dart';

class TraditionalReaderScreen extends StatefulWidget {
  final Book book;

  const TraditionalReaderScreen({super.key, required this.book});

  @override
  State<TraditionalReaderScreen> createState() => _TraditionalReaderScreenState();
}

class _TraditionalReaderScreenState extends State<TraditionalReaderScreen> {
  final LibraryService _libraryService = LibraryService();

  final Map<int, ColumnPage> _pageCache = {};
  ColumnPage? _currentPage;
  int _currentWordPosition = 0;

  List<RichWord> _richWords = [];
  List<String> _words = [];
  List<int> _chapterWordPositions = [];
  List<ChapterInfo> _chapters = [];
  bool _isLoading = true;
  final String _loadingMessage = 'Loading book...';

  double? _cachedViewportWidth;
  double? _cachedViewportHeight;
  double _horizontalPadding = 24.0;
  double _verticalPadding = 16.0;
  TextStyle? _cachedTextStyle;

  LibraryProvider? _libraryProvider;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
      _richWords = TextProcessor.parseRichWords(text);
      _words = _richWords.map((rw) => rw.text).toList();

      if (_words.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        return;
      }

      _chapterWordPositions = TextProcessor.normalizeChapterWordPositions(
        widget.book.chapterPositions,
        _words.length,
        text.length,
      );
      _chapters = TextProcessor.buildChapterInfoList(_richWords, _chapterWordPositions);

      int initialPosition = widget.book.currentPosition;
      if (initialPosition <= 0) {
        initialPosition = TextProcessor.findStartPosition(
          text,
          chapterPositions: _chapterWordPositions,
        );
      }

      _currentWordPosition = initialPosition.clamp(0, _words.length - 1);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      if (_cachedViewportWidth != null && _cachedViewportHeight != null) {
        await _layoutForViewport(_cachedViewportWidth!, _cachedViewportHeight!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading book: $e')),
      );
    }
  }

  void _switchToSpeedReader() {
    _saveProgress();
    final pos = _currentPage?.startWordIndex ?? _currentWordPosition;
    final updatedBook = widget.book.copyWith(currentPosition: pos);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SpeedReaderScreen(book: updatedBook),
      ),
    );
  }

  int _getCurrentChapter() {
    if (_chapterWordPositions.isEmpty) return 1;
    final pos = _currentPage?.startWordIndex ?? _currentWordPosition;
    for (int i = _chapterWordPositions.length - 1; i >= 0; i--) {
      if (pos >= _chapterWordPositions[i]) {
        return i + 1;
      }
    }
    return 1;
  }

  void _showChaptersDialog() {
    showChaptersModalDialog(
      context: context,
      chapters: _chapters,
      currentChapter: _getCurrentChapter(),
      totalWords: _words.length,
      onChapterSelected: (ch) async {
        final targetPos = ch.wordIndex.clamp(0, _words.length - 1);
        final page = await _calculatePage(targetPos);
        if (!mounted) return;
        setState(() {
          _currentPage = page;
          _currentWordPosition = page.startWordIndex;
        });
        _saveProgress();
      },
    );
  }

  TextStyle _buildEffectiveTextStyle(ReadingSettings settings) {
    final textScaleFactor = MediaQuery.of(context).textScaler.scale(1.0);
    return ColumnTextLayout.normalizeBaseStyle(
      TextStyle(
        fontSize: settings.traditionalFontSize * textScaleFactor,
        color: settings.textColor,
        fontFamily: settings.fontFamily,
        height: settings.lineHeight,
      ),
    );
  }

  Future<void> _layoutForViewport(double maxWidth, double maxHeight) async {
    if (_words.isEmpty || maxWidth <= 40 || maxHeight <= 40) return;

    final settings = context.read<SettingsProvider>().settings;
    _cachedViewportWidth = maxWidth;
    _cachedViewportHeight = maxHeight;
    _horizontalPadding = maxWidth < 600 ? 16.0 : 24.0;
    _verticalPadding = maxHeight < 600 ? 10.0 : 16.0;
    _cachedTextStyle = _buildEffectiveTextStyle(settings);
    _pageCache.clear();

    final anchorPos = _currentPage?.startWordIndex ?? _currentWordPosition;
    final page = await _calculatePage(anchorPos);

    if (!mounted) return;

    setState(() {
      _currentPage = page;
      _currentWordPosition = page.startWordIndex;
    });
  }

  Future<ColumnPage> _calculatePage(int startWordIndex) async {
    if (_pageCache.containsKey(startWordIndex)) {
      return _pageCache[startWordIndex]!;
    }

    final settings = context.read<SettingsProvider>().settings;
    final viewportWidth = _cachedViewportWidth ?? 800.0;
    final viewportHeight = _cachedViewportHeight ?? 600.0;
    final style = _cachedTextStyle ?? _buildEffectiveTextStyle(settings);

    final page = await Future.microtask(() {
      return ColumnTextLayout.layoutText(
        text: '',
        availableWidth: viewportWidth,
        availableHeight: viewportHeight,
        textStyle: style,
        numberOfColumns: settings.numberOfColumns,
        columnGap: settings.columnGap,
        horizontalPadding: _horizontalPadding,
        verticalPadding: _verticalPadding,
        maxPages: 1,
        startWordIndex: startWordIndex,
        preProcessedRichWords: _richWords,
        respectFormatting: settings.respectFormatting,
        textScaler: TextScaler.noScaling,
      );
    });

    if (page.isNotEmpty) {
      _pageCache[startWordIndex] = page.first;

      if (_pageCache.length > 12) {
        final keysToRemove = _pageCache.keys.toList()..sort();
        final currentIndex = keysToRemove.indexOf(startWordIndex);

        for (var i = 0; i < keysToRemove.length; i++) {
          if ((i < currentIndex - 6) || (i > currentIndex + 6)) {
            _pageCache.remove(keysToRemove[i]);
          }
        }
      }

      return page.first;
    }

    return ColumnPage(
      startWordIndex: startWordIndex,
      endWordIndex: startWordIndex,
      columns: [],
    );
  }

  Future<int> _findPreviousPageStart(int currentPageStart) async {
    if (currentPageStart <= 0) {
      return 0;
    }

    int searchStart = 0;
    int searchEnd = currentPageStart - 1;
    int bestCandidate = 0;
    int bestEndDifference = currentPageStart;

    final currentPage = _currentPage;
    if (currentPage != null && currentPage.wordCount > 0) {
      searchStart = (currentPageStart - currentPage.wordCount * 1.6).round().clamp(0, searchEnd);
    } else {
      searchStart = (currentPageStart - 250).clamp(0, searchEnd);
    }

    while (searchStart <= searchEnd) {
      final mid = (searchStart + searchEnd) ~/ 2;
      final testPage = await _calculatePage(mid);

      final endDifference = (testPage.endWordIndex - currentPageStart).abs();

      if (endDifference < bestEndDifference) {
        bestCandidate = testPage.startWordIndex;
        bestEndDifference = endDifference;
      }

      if (testPage.endWordIndex == currentPageStart) {
        return testPage.startWordIndex;
      } else if (testPage.endWordIndex < currentPageStart) {
        searchStart = mid + 1;
      } else {
        searchEnd = mid - 1;
      }
    }

    if (bestEndDifference <= 60) {
      return bestCandidate;
    }

    return 0;
  }

  Future<void> _relayoutPage() async {
    if (_cachedViewportWidth == null || _cachedViewportHeight == null) return;
    await _layoutForViewport(_cachedViewportWidth!, _cachedViewportHeight!);
  }

  void _saveProgress() {
    if (_currentPage == null) return;
    final wordPosition = _currentPage!.startWordIndex;
    _libraryProvider?.updateProgress(widget.book.id, position: wordPosition);
  }

  Future<void> _nextPage() async {
    if (_currentPage == null || _currentPage!.endWordIndex >= _words.length) return;

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

    final previousPageStart = await _findPreviousPageStart(_currentPage!.startWordIndex);
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
    final settingsProvider = context.watch<SettingsProvider>();
    final settings = settingsProvider.settings;

    return Scaffold(
      backgroundColor: settings.backgroundColor,
      appBar: AppBar(
        title: Text(widget.book.title),
        actions: [
          if (_chapterWordPositions.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.format_list_bulleted, size: 18),
              label: Text('Ch ${_getCurrentChapter()}/${_chapterWordPositions.length}'),
              onPressed: _showChaptersDialog,
            ),
          IconButton(
            icon: Icon(settings.respectFormatting ? Icons.format_align_left : Icons.notes),
            tooltip: settings.respectFormatting
                ? 'Original Carriage Returns & Heading Sizes (Tap for Dense Reflow)'
                : 'Dense Continuous Reflow (Tap for Original Carriage Returns & Headings)',
            onPressed: () {
              settingsProvider.updateRespectFormatting(!settings.respectFormatting);
              _relayoutPage();
            },
          ),
          IconButton(
            icon: const Icon(Icons.speed),
            tooltip: 'Switch to Speed Reader (Same Position)',
            onPressed: _switchToSpeedReader,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: _getProgress(), minHeight: 4),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxW = constraints.maxWidth;
                final maxH = constraints.maxHeight;
                final needsRelayout = _cachedViewportWidth == null ||
                    _cachedViewportHeight == null ||
                    (maxW - _cachedViewportWidth!).abs() >= 1.0 ||
                    (maxH - _cachedViewportHeight!).abs() >= 1.0;

                if (needsRelayout && !_isLoading && _words.isNotEmpty) {
                  _cachedViewportWidth = maxW;
                  _cachedViewportHeight = maxH;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _layoutForViewport(maxW, maxH);
                    }
                  });
                }

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) {
                    if (details.localPosition.dx > maxW * 0.6) {
                      _nextPage();
                    } else if (details.localPosition.dx < maxW * 0.4) {
                      _previousPage();
                    }
                  },
                  child: Container(
                    width: maxW,
                    height: maxH,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: settings.backgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: settings.textColor),
                  onPressed: _canGoPrevious() ? _previousPage : null,
                ),
                Text(
                  'Position: ${_currentWordPosition + 1} / ${_words.length}  •  ${(_getProgress() * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: settings.textColor.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward, color: settings.textColor),
                  onPressed: _canGoNext() ? _nextPage : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(ReadingSettings settings) {
    final page = _currentPage;
    if (page == null) {
      return const Center(child: Text('No content'));
    }

    final textStyle = _cachedTextStyle ?? _buildEffectiveTextStyle(settings);

    final List<Widget> columnWidgets = [];
    for (int i = 0; i < page.columns.length; i++) {
      final hasRichSpan = i < page.columnSpans.length;
      final columnLines = page.columns[i];
      final span = hasRichSpan
          ? page.columnSpans[i]
          : TextSpan(text: columnLines.join('\n'), style: textStyle);

      columnWidgets.add(
        SizedBox(
          width: page.columnWidth > 0 ? page.columnWidth : null,
          height: page.columnHeight > 0 ? page.columnHeight : null,
          child: Semantics(
            label: columnLines.join('\n'),
            child: CustomPaint(
              painter: _ColumnSpanPainter(
                span: span,
                columnWidth: page.columnWidth,
              ),
            ),
          ),
        ),
      );

      if (i < page.columns.length - 1) {
        columnWidgets.add(SizedBox(width: settings.columnGap));
      }
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _horizontalPadding,
        vertical: _verticalPadding,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          child: Consumer<SettingsProvider>(
            builder: (context, provider, child) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Original Line Breaks & Headings'),
                  subtitle: const Text('Preserve carriage returns and heading sizes'),
                  value: provider.settings.respectFormatting,
                  onChanged: (val) {
                    provider.updateRespectFormatting(val);
                    _relayoutPage();
                  },
                ),
                const Divider(),
                const Text('Font Size'),
                Slider(
                  value: provider.settings.traditionalFontSize,
                  min: 12,
                  max: 72,
                  divisions: 60,
                  label: provider.settings.traditionalFontSize.toStringAsFixed(0),
                  onChanged: (value) {
                    provider.updateTraditionalFontSize(value);
                    _relayoutPage();
                  },
                ),
                const SizedBox(height: 16),
                const Text('Number of Columns'),
                Slider(
                  value: provider.settings.numberOfColumns.toDouble(),
                  min: 1,
                  max: 3,
                  divisions: 2,
                  label: provider.settings.numberOfColumns.toString(),
                  onChanged: (value) {
                    provider.updateSettings(
                      provider.settings.copyWith(numberOfColumns: value.toInt()),
                    );
                    _relayoutPage();
                  },
                ),
                const SizedBox(height: 16),
                const Text('Column Gap'),
                Slider(
                  value: provider.settings.columnGap,
                  min: 16,
                  max: 64,
                  divisions: 12,
                  label: provider.settings.columnGap.toStringAsFixed(0),
                  onChanged: (value) {
                    provider.updateSettings(
                      provider.settings.copyWith(columnGap: value),
                    );
                    _relayoutPage();
                  },
                ),
                const SizedBox(height: 16),
                const Text('Line Height'),
                Slider(
                  value: provider.settings.lineHeight,
                  min: 1.0,
                  max: 2.5,
                  divisions: 15,
                  label: provider.settings.lineHeight.toStringAsFixed(1),
                  onChanged: (value) {
                    provider.updateSettings(
                      provider.settings.copyWith(lineHeight: value),
                    );
                    _relayoutPage();
                  },
                ),
                const SizedBox(height: 16),
                const Text('Theme'),
                const SizedBox(height: 8),
                ReadingThemeChips(provider: provider),
              ],
            ),
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

/// Renders a column's TextSpan using the exact same TextPainter configuration
/// used during ColumnTextLayout measurement, guaranteeing 0.0px divergence.
class _ColumnSpanPainter extends CustomPainter {
  final TextSpan span;
  final double columnWidth;

  _ColumnSpanPainter({
    required this.span,
    required this.columnWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final maxWidth = columnWidth > 0 ? columnWidth : size.width;
    if (maxWidth <= 0) return;

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final textPainter = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
      textHeightBehavior: ColumnTextLayout.kTextHeightBehavior,
    )..layout(maxWidth: maxWidth);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ColumnSpanPainter oldDelegate) {
    return oldDelegate.span != span || oldDelegate.columnWidth != columnWidth;
  }
}
