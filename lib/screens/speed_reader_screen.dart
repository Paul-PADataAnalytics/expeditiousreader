import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../providers/library_provider.dart';
import '../providers/settings_provider.dart';
import '../services/library_service.dart';
import '../utils/text_processor.dart';

class SpeedReaderScreen extends StatefulWidget {
  final Book book;

  const SpeedReaderScreen({super.key, required this.book});

  @override
  State<SpeedReaderScreen> createState() => _SpeedReaderScreenState();
}

class _SpeedReaderScreenState extends State<SpeedReaderScreen> {
  final LibraryService _libraryService = LibraryService();
  
  List<String> _words = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  Timer? _timer;
  String _fullText = '';
  int _currentChapter = 0;
  
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
    _timer?.cancel();
    _saveProgress();
    super.dispose();
  }

  Future<void> _loadBook() async {
    try {
      _fullText = await _libraryService.readBookText(widget.book);
      _words = TextProcessor.splitIntoWords(_fullText);
      
      int initialPosition = 0;
      
      // Prefer the word position if it exists (from speed reading)
      if (widget.book.currentPosition > 0) {
        initialPosition = widget.book.currentPosition;
      } 
      // Otherwise, if there's a traditional reading page position, sync to it
      else if (widget.book.currentPage > 0 && widget.book.pageCount > 0) {
        // Calculate which word position corresponds to the current page
        final progressRatio = widget.book.currentPage / widget.book.pageCount;
        initialPosition = (progressRatio * _words.length).floor();
      }
      
      // Set initial position
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

      // Check if previous word ended with a sentence-ending punctuation
      bool shouldPauseForSentence = false;
      if (settings.pauseOnSentenceEnd && _currentIndex > 0) {
        final previousWord = _words[_currentIndex];
        shouldPauseForSentence = _endsWithSentencePunctuation(previousWord);
      }

      setState(() {
        _currentIndex++;
        _currentChapter = _getCurrentChapter();
      });

      // Determine if we need an extended pause
      int pauseMultiplier = 1;
      
      // Check for sentence end pause (takes precedence)
      if (shouldPauseForSentence) {
        pauseMultiplier = 2;
      }
      // Otherwise check for long word pause
      else if (settings.pauseOnLongWords) {
        final currentWord = _words[_currentIndex];
        if (currentWord.length >= settings.longWordThreshold) {
          pauseMultiplier = settings.longWordPauseMultiplier;
        }
      }

      // Apply extended pause if needed
      if (pauseMultiplier > 1) {
        _timer?.cancel();
        Future.delayed(baseDelay * pauseMultiplier, () {
          if (_isPlaying) {
            _startReading();
          }
        });
      }
    });
  }

  /// Check if a word ends with sentence-ending punctuation
  bool _endsWithSentencePunctuation(String word) {
    if (word.isEmpty) return false;
    final lastChar = word[word.length - 1];
    return lastChar == '.' || lastChar == '!' || lastChar == '?';
  }

  void _saveProgress() {
    // Calculate approximate page based on current word position
    int page = 0;
    if (_words.isNotEmpty && widget.book.pageCount > 0) {
      final progressRatio = _currentIndex / _words.length;
      page = (progressRatio * widget.book.pageCount).floor();
    }
    
    // Use stored provider reference instead of context.read
    _libraryProvider?.updateProgress(
      widget.book.id,
      position: _currentIndex,
      page: page,
    );
  }

  String _getCurrentWord() {
    if (_words.isEmpty || _currentIndex >= _words.length) {
      return '';
    }
    return _words[_currentIndex];
  }

  double _getProgress() {
    if (_words.isEmpty) return 0.0;
    return _currentIndex / _words.length;
  }

  /// Find the current chapter based on word position
  int _getCurrentChapter() {
    if (widget.book.chapterPositions.isEmpty) return 0;
    
    // Calculate the character position in the original full text
    // We need to find where we are in the original text, not the word array
    // Use a simple ratio-based approach
    if (_words.isEmpty) return 1;
    
    final progressRatio = _currentIndex / _words.length;
    final approximateCharPosition = (progressRatio * _fullText.length).round();
    
    // Find which chapter this position falls into
    for (int i = widget.book.chapterPositions.length - 1; i >= 0; i--) {
      if (approximateCharPosition >= widget.book.chapterPositions[i]) {
        return i + 1; // Chapter numbers are 1-based
      }
    }
    return 1; // Default to chapter 1
  }

  /// Move to the next sentence
  void _nextSentence() {
    if (_currentIndex >= _words.length - 1) return;
    
    // Find the next sentence ending
    for (int i = _currentIndex + 1; i < _words.length; i++) {
      if (_endsWithSentencePunctuation(_words[i])) {
        setState(() {
          _currentIndex = (i + 1).clamp(0, _words.length - 1);
          _currentChapter = _getCurrentChapter();
        });
        return;
      }
    }
    
    // If no sentence ending found, go to end
    setState(() {
      _currentIndex = _words.length - 1;
      _currentChapter = _getCurrentChapter();
    });
  }

  /// Move to the previous sentence
  void _previousSentence() {
    if (_currentIndex <= 0) return;
    
    // Move back to find the start of current sentence
    int sentenceStart = _currentIndex;
    for (int i = _currentIndex - 1; i >= 0; i--) {
      if (_endsWithSentencePunctuation(_words[i])) {
        sentenceStart = i + 1;
        break;
      }
      if (i == 0) {
        sentenceStart = 0;
      }
    }
    
    // If we're already at sentence start, find previous sentence
    if (sentenceStart == _currentIndex) {
      for (int i = _currentIndex - 1; i >= 0; i--) {
        if (_endsWithSentencePunctuation(_words[i])) {
          // Found previous sentence ending, find its start
          for (int j = i - 1; j >= 0; j--) {
            if (_endsWithSentencePunctuation(_words[j])) {
              setState(() {
                _currentIndex = j + 1;
                _currentChapter = _getCurrentChapter();
              });
              return;
            }
            if (j == 0) {
              setState(() {
                _currentIndex = 0;
                _currentChapter = _getCurrentChapter();
              });
              return;
            }
          }
        }
      }
    }
    
    setState(() {
      _currentIndex = sentenceStart;
      _currentChapter = _getCurrentChapter();
    });
  }

  /// Move to the next chapter
  void _nextChapter() {
    if (widget.book.chapterPositions.isEmpty || _currentIndex >= _words.length - 1) return;
    
    // Calculate current position in the full text using ratio
    final currentProgressRatio = _currentIndex / _words.length;
    final currentCharPosition = (currentProgressRatio * _fullText.length).round();
    
    // Find the next chapter position
    for (int chapterPos in widget.book.chapterPositions) {
      if (chapterPos > currentCharPosition) {
        // Convert chapter character position to word index using ratio
        final chapterProgressRatio = chapterPos / _fullText.length;
        final targetWordIndex = (chapterProgressRatio * _words.length).round();
        setState(() {
          _currentIndex = targetWordIndex.clamp(0, _words.length - 1);
          _currentChapter = _getCurrentChapter();
        });
        return;
      }
    }
  }

  /// Move to the previous chapter
  void _previousChapter() {
    if (widget.book.chapterPositions.isEmpty || _currentIndex <= 0) return;
    
    // Calculate current position in the full text using ratio
    final currentProgressRatio = _currentIndex / _words.length;
    final currentCharPosition = (currentProgressRatio * _fullText.length).round();
    
    // Find the previous chapter position (skip current chapter start)
    for (int i = widget.book.chapterPositions.length - 1; i >= 0; i--) {
      int chapterPos = widget.book.chapterPositions[i];
      // Check if this chapter is before current position
      // Use a threshold to avoid jumping to current chapter start
      if (chapterPos < currentCharPosition - 100) {
        final chapterProgressRatio = chapterPos / _fullText.length;
        final targetWordIndex = (chapterProgressRatio * _words.length).round();
        setState(() {
          _currentIndex = targetWordIndex.clamp(0, _words.length - 1);
          _currentChapter = _getCurrentChapter();
        });
        return;
      }
    }
    
    // If no previous chapter found, go to start
    setState(() {
      _currentIndex = 0;
      _currentChapter = _getCurrentChapter();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;

    return Scaffold(
      backgroundColor: settings.backgroundColor,
      appBar: AppBar(
        title: Text(widget.book.title),
        actions: [
          // Chapter indicator
          if (widget.book.chapterPositions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Text(
                  'Chapter $_currentChapter',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _showSettingsDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: _getProgress(),
            minHeight: 4,
          ),
          
          // Word display
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  _getCurrentWord(),
                  style: TextStyle(
                    fontSize: settings.speedReaderFontSize,
                    color: settings.textColor,
                    fontFamily: settings.fontFamily,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          // Progress text
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '${_currentIndex + 1} / ${_words.length} words  •  ${(_getProgress() * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                color: settings.textColor.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),

          // Controls
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                // Chapter navigation
                if (widget.book.chapterPositions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Chapters:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.first_page),
                          iconSize: 28,
                          onPressed: _previousChapter,
                          tooltip: 'Previous Chapter',
                        ),
                        IconButton(
                          icon: const Icon(Icons.last_page),
                          iconSize: 28,
                          onPressed: _nextChapter,
                          tooltip: 'Next Chapter',
                        ),
                      ],
                    ),
                  ),
                
                // Sentence navigation
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Sentences:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        iconSize: 28,
                        onPressed: _previousSentence,
                        tooltip: 'Previous Sentence',
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        iconSize: 28,
                        onPressed: _nextSentence,
                        tooltip: 'Next Sentence',
                      ),
                    ],
                  ),
                ),
                
                // Main playback controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
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
                      icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
                      iconSize: 64,
                      onPressed: _togglePlayPause,
                    ),
                    const SizedBox(width: 32),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
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

          // Speed control
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
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
                    
                    // Restart timer if playing
                    if (_isPlaying) {
                      _timer?.cancel();
                      _startReading();
                    }
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
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
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Light'),
                    selected: provider.settings.backgroundColor == Colors.white,
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
                    selected: provider.settings.backgroundColor == Colors.black,
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
                    selected: provider.settings.backgroundColor == const Color(0xFFF4ECD8),
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
