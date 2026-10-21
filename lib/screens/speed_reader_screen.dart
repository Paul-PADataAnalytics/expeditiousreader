import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../providers/library_provider.dart';
import '../providers/settings_provider.dart';
import '../services/library_service.dart';
import '../utils/text_processor.dart';
import '../widgets/reader_shared_widgets.dart';
import 'traditional_reader_screen.dart';

class SpeedReaderScreen extends StatefulWidget {
  final Book book;

  const SpeedReaderScreen({super.key, required this.book});

  @override
  State<SpeedReaderScreen> createState() => _SpeedReaderScreenState();
}

class _SpeedReaderScreenState extends State<SpeedReaderScreen> {
  final LibraryService _libraryService = LibraryService();

  List<RichWord> _richWords = [];
  List<String> _words = [];
  List<int> _chapterWordPositions = [];
  List<ChapterInfo> _chapters = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  Timer? _timer;
  String _fullText = '';
  int _currentChapter = 1;

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
    _timer?.cancel();
    _saveProgress();
    super.dispose();
  }

  Future<void> _loadBook() async {
    try {
      _fullText = await _libraryService.readBookText(widget.book);
      _richWords = TextProcessor.parseRichWords(_fullText);
      _words = _richWords.map((rw) => rw.text).toList();

      if (_words.isEmpty) return;

      _chapterWordPositions = TextProcessor.normalizeChapterWordPositions(
        widget.book.chapterPositions,
        _words.length,
        _fullText.length,
      );
      _chapters = TextProcessor.buildChapterInfoList(_richWords, _chapterWordPositions);

      int initialPosition = widget.book.currentPosition;
      if (initialPosition <= 0) {
        initialPosition = TextProcessor.findStartPosition(
          _fullText,
          chapterPositions: _chapterWordPositions,
        );
      }

      setState(() {
        _currentIndex = initialPosition.clamp(0, _words.length - 1);
        _currentChapter = _getCurrentChapter();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading book: $e')),
      );
    }
  }

  void _switchToTraditionalReader() {
    _timer?.cancel();
    _isPlaying = false;
    _saveProgress();

    final updatedBook = widget.book.copyWith(currentPosition: _currentIndex);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TraditionalReaderScreen(book: updatedBook),
      ),
    );
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      _startReading();
    } else {
      _timer?.cancel();
    }
  }

  void _startReading() {
    final settings = context.read<SettingsProvider>().settings;
    final baseDelay = Duration(milliseconds: (60000 / settings.wordsPerMinute).round());

    _timer = Timer.periodic(baseDelay, (timer) {
      if (_currentIndex >= _words.length - 1) {
        _timer?.cancel();
        setState(() {
          _isPlaying = false;
        });
        return;
      }

      bool shouldPauseForBoundary = false;
      if (_currentIndex >= 0 && _currentIndex < _richWords.length) {
        final prevRich = _richWords[_currentIndex];
        if (settings.pauseOnSentenceEnd && _endsWithSentencePunctuation(prevRich.text)) {
          shouldPauseForBoundary = true;
        } else if (prevRich.lineBreaksAfter >= 2 || prevRich.headingLevel > 0) {
          shouldPauseForBoundary = true;
        }
      }

      setState(() {
        _currentIndex++;
        _currentChapter = _getCurrentChapter();
      });

      int pauseMultiplier = 1;
      if (shouldPauseForBoundary) {
        pauseMultiplier = 2;
      } else if (settings.pauseOnLongWords) {
        final currentWord = _words[_currentIndex];
        if (currentWord.length >= settings.longWordThreshold) {
          pauseMultiplier = settings.longWordPauseMultiplier;
        }
      }

      if (pauseMultiplier > 1) {
        _timer?.cancel();
        Future.delayed(baseDelay * pauseMultiplier, () {
          if (_isPlaying && mounted) {
            _startReading();
          }
        });
      }
    });
  }

  bool _endsWithSentencePunctuation(String word) {
    if (word.isEmpty) return false;
    final cleaned = word.replaceAll(RegExp(r'''["'”’)\]]+$'''), '');
    if (cleaned.isEmpty) return false;
    final lastChar = cleaned[cleaned.length - 1];
    return lastChar == '.' || lastChar == '!' || lastChar == '?';
  }

  void _saveProgress() {
    int page = 0;
    if (_words.isNotEmpty && widget.book.pageCount > 0) {
      final progressRatio = _currentIndex / _words.length;
      page = (progressRatio * widget.book.pageCount).floor();
    }

    _libraryProvider?.updateProgress(
      widget.book.id,
      position: _currentIndex,
      page: page,
    );
  }

  RichWord? _getCurrentRichWord() {
    if (_richWords.isEmpty || _currentIndex >= _richWords.length) {
      return null;
    }
    return _richWords[_currentIndex];
  }

  double _getProgress() {
    if (_words.isEmpty) return 0.0;
    return _currentIndex / _words.length;
  }

  int _getCurrentChapter() {
    if (_chapterWordPositions.isEmpty) return 1;
    for (int i = _chapterWordPositions.length - 1; i >= 0; i--) {
      if (_currentIndex >= _chapterWordPositions[i]) {
        return i + 1;
      }
    }
    return 1;
  }

  void _nextSentence() {
    if (_currentIndex >= _words.length - 1) return;

    for (int i = _currentIndex + 1; i < _words.length; i++) {
      if (_endsWithSentencePunctuation(_words[i]) || _richWords[i].lineBreaksAfter > 0) {
        setState(() {
          _currentIndex = (i + 1).clamp(0, _words.length - 1);
          _currentChapter = _getCurrentChapter();
        });
        return;
      }
    }

    setState(() {
      _currentIndex = _words.length - 1;
      _currentChapter = _getCurrentChapter();
    });
  }

  void _previousSentence() {
    if (_currentIndex <= 0) return;

    int target = 0;
    for (int i = _currentIndex - 2; i >= 0; i--) {
      if (_endsWithSentencePunctuation(_words[i]) || _richWords[i].lineBreaksAfter > 0) {
        target = i + 1;
        break;
      }
    }

    setState(() {
      _currentIndex = target.clamp(0, _words.length - 1);
      _currentChapter = _getCurrentChapter();
    });
  }

  void _nextChapter() {
    if (_chapterWordPositions.isEmpty || _currentIndex >= _words.length - 1) return;

    for (final chapterWordPos in _chapterWordPositions) {
      if (chapterWordPos > _currentIndex) {
        setState(() {
          _currentIndex = chapterWordPos.clamp(0, _words.length - 1);
          _currentChapter = _getCurrentChapter();
        });
        _saveProgress();
        return;
      }
    }
  }

  void _previousChapter() {
    if (_chapterWordPositions.isEmpty || _currentIndex <= 0) return;

    for (int i = _chapterWordPositions.length - 1; i >= 0; i--) {
      final chapterWordPos = _chapterWordPositions[i];
      if (chapterWordPos < _currentIndex - 15) {
        setState(() {
          _currentIndex = chapterWordPos.clamp(0, _words.length - 1);
          _currentChapter = _getCurrentChapter();
        });
        _saveProgress();
        return;
      }
    }

    setState(() {
      _currentIndex = 0;
      _currentChapter = _getCurrentChapter();
    });
  }

  void _showChaptersDialog() {
    showChaptersModalDialog(
      context: context,
      chapters: _chapters,
      currentChapter: _currentChapter,
      totalWords: _words.length,
      onChapterSelected: (ch) {
        setState(() {
          _currentIndex = ch.wordIndex.clamp(0, _words.length - 1);
          _currentChapter = _getCurrentChapter();
        });
        _saveProgress();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;
    final currentRich = _getCurrentRichWord();
    final headingLevel = currentRich?.headingLevel ?? 0;
    final double fontMultiplier =
        headingLevel == 1 ? 1.35 : (headingLevel == 2 ? 1.2 : (headingLevel == 3 ? 1.1 : 1.0));

    return Scaffold(
      backgroundColor: settings.backgroundColor,
      appBar: AppBar(
        title: Text(widget.book.title),
        actions: [
          if (_chapterWordPositions.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.format_list_bulleted, size: 18),
              label: Text('Ch $_currentChapter/${_chapterWordPositions.length}'),
              onPressed: _showChaptersDialog,
            ),
          IconButton(
            icon: const Icon(Icons.chrome_reader_mode),
            tooltip: 'Switch to Traditional Reader (Same Position)',
            onPressed: _switchToTraditionalReader,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: _getProgress(),
            minHeight: 4,
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (headingLevel > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            headingLevel == 1 ? 'CHAPTER HEADING' : 'SECTION HEADING',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                              color: settings.textColor.withValues(alpha: 0.75),
                            ),
                          ),
                        ),
                      ),
                    Text(
                      currentRich?.text ?? '',
                      style: TextStyle(
                        fontSize: settings.speedReaderFontSize * fontMultiplier,
                        color: settings.textColor,
                        fontFamily: settings.fontFamily,
                        fontWeight: headingLevel > 0 ? FontWeight.bold : FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '${_words.isEmpty ? 0 : _currentIndex + 1} / ${_words.length} words  •  ${(_getProgress() * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                color: settings.textColor.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
            child: Column(
              children: [
                if (_chapterWordPositions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Chapters:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: settings.textColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.first_page, color: settings.textColor),
                          iconSize: 28,
                          onPressed: _previousChapter,
                          tooltip: 'Previous Chapter',
                        ),
                        IconButton(
                          icon: Icon(Icons.last_page, color: settings.textColor),
                          iconSize: 28,
                          onPressed: _nextChapter,
                          tooltip: 'Next Chapter',
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sentences:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: settings.textColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: settings.textColor),
                        iconSize: 28,
                        onPressed: _previousSentence,
                        tooltip: 'Previous Sentence / Line',
                      ),
                      IconButton(
                        icon: Icon(Icons.arrow_forward, color: settings.textColor),
                        iconSize: 28,
                        onPressed: _nextSentence,
                        tooltip: 'Next Sentence / Line',
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.skip_previous, color: settings.textColor),
                      iconSize: 48,
                      onPressed: () {
                        setState(() {
                          _currentIndex = (_currentIndex - 10).clamp(0, _words.length - 1);
                          _currentChapter = _getCurrentChapter();
                        });
                      },
                      tooltip: 'Back 10 Words',
                    ),
                    const SizedBox(width: 32),
                    IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                        color: settings.textColor,
                      ),
                      iconSize: 64,
                      onPressed: _togglePlayPause,
                    ),
                    const SizedBox(width: 32),
                    IconButton(
                      icon: Icon(Icons.skip_next, color: settings.textColor),
                      iconSize: 48,
                      onPressed: () {
                        setState(() {
                          _currentIndex = (_currentIndex + 10).clamp(0, _words.length - 1);
                          _currentChapter = _getCurrentChapter();
                        });
                      },
                      tooltip: 'Forward 10 Words',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
            child: Column(
              children: [
                Text(
                  '${settings.wordsPerMinute} WPM',
                  style: TextStyle(
                    fontSize: 16,
                    color: settings.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Slider(
                  value: settings.wordsPerMinute.toDouble(),
                  min: 100,
                  max: 1000,
                  divisions: 90,
                  label: '${settings.wordsPerMinute} WPM',
                  onChanged: (value) {
                    context.read<SettingsProvider>().updateWPM(value.toInt());
                    if (_isPlaying) {
                      _timer?.cancel();
                      _startReading();
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reading Settings'),
        content: Consumer<SettingsProvider>(
          builder: (context, provider, child) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Font Size',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Slider(
                value: provider.settings.speedReaderFontSize,
                min: 16,
                max: 72,
                divisions: 28,
                label: provider.settings.speedReaderFontSize.toStringAsFixed(0),
                onChanged: (value) {
                  provider.updateSpeedReaderFontSize(value);
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Theme',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ReadingThemeChips(provider: provider),
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
