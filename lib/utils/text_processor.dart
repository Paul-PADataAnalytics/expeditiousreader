class TextProcessor {
  /// Clean and normalize text while preserving structure
  static String cleanText(String text) {
    // Remove table of contents patterns
    text = _removeTableOfContents(text);
    
    // Remove index patterns
    text = _removeIndex(text);
    
    // Normalize line breaks (handle different OS formats)
    text = text.replaceAll('\r\n', '\n'); // Windows
    text = text.replaceAll('\r', '\n');   // Old Mac
    
    // Remove excessive blank lines (more than 2 consecutive)
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    
    // Trim spaces at the end of lines but preserve the line structure
    text = text.split('\n').map((line) => line.trimRight()).join('\n');
    
    return text.trim();
  }
  
  /// Clean text for speed reading (removes all formatting)
  static String cleanTextForSpeedReading(String text) {
    // For speed reading, we want a simple word stream
    // Remove excessive whitespace and collapse to single spaces
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    return text.trim();
  }

  /// Calculate chapter start positions based on chapter texts
  static List<int> calculateChapterPositions(String fullText, List<String> chapters) {
    List<int> positions = [];
    int currentPos = 0;

    for (var chapter in chapters) {
      int index = fullText.indexOf(chapter, currentPos);
      if (index != -1) {
        positions.add(index);
        currentPos = index + chapter.length;
      }
    }

    return positions;
  }

  /// Detect chapters in text using heuristics
  static List<int> detectChapters(String text) {
    List<int> positions = [0];
    
    // Look for common chapter patterns
    final chapterPatterns = [
      RegExp(r'\bChapter\s+\d+', caseSensitive: false),
      RegExp(r'\bCHAPTER\s+[IVX]+', caseSensitive: false),
      RegExp(r'\bPart\s+\d+', caseSensitive: false),
      RegExp(r'\n\d+\.\s+[A-Z]'),
    ];

    for (var pattern in chapterPatterns) {
      for (var match in pattern.allMatches(text)) {
        positions.add(match.start);
      }
    }

    // Remove duplicates and sort
    positions = positions.toSet().toList()..sort();
    
    return positions;
  }

  /// Split text into words (for speed reading)
  static List<String> splitIntoWords(String text) {
    // For speed reading, collapse all whitespace to make a word stream
    final cleanedText = cleanTextForSpeedReading(text);
    return cleanedText.split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
  }

  /// Count words
  static int countWords(String text) {
    // Use the speed reading version for consistent word count
    return splitIntoWords(text).length;
  }

  /// Paginate text for traditional reading (preserves formatting)
  static List<String> paginateText(String text, int wordsPerPage) {
    // Split by paragraphs to preserve structure
    final paragraphs = text.split('\n');
    final pages = <String>[];
    String currentPage = '';
    int currentWordCount = 0;
    
    for (var paragraph in paragraphs) {
      if (paragraph.trim().isEmpty) {
        // Preserve blank lines
        currentPage += '\n';
        continue;
      }
      
      final words = paragraph.trim().split(RegExp(r'\s+'));
      final paragraphWordCount = words.length;
      
      // Check if adding this paragraph would exceed words per page
      if (currentWordCount > 0 && currentWordCount + paragraphWordCount > wordsPerPage) {
        // Save current page and start a new one
        pages.add(currentPage.trim());
        currentPage = paragraph + '\n\n';
        currentWordCount = paragraphWordCount;
      } else {
        // Add paragraph to current page
        currentPage += paragraph + '\n\n';
        currentWordCount += paragraphWordCount;
      }
    }
    
    // Add the last page if it has content
    if (currentPage.trim().isNotEmpty) {
      pages.add(currentPage.trim());
    }
    
    return pages.isEmpty ? [''] : pages;
  }

  /// Remove table of contents
  static String _removeTableOfContents(String text) {
    // Simple heuristic: remove section that starts with "Contents" or "Table of Contents"
    final tocPattern = RegExp(
      r'(Table of )?Contents.*?(?=Chapter|Part|\n\n[A-Z])',
      caseSensitive: false,
      dotAll: true,
    );
    
    return text.replaceAll(tocPattern, '');
  }

  /// Remove index
  static String _removeIndex(String text) {
    // Simple heuristic: remove section that starts with "Index"
    final indexPattern = RegExp(
      r'Index\s*\n.*',
      caseSensitive: false,
      dotAll: true,
    );
    
    return text.replaceAll(indexPattern, '');
  }

  /// Find the position to start reading (after TOC and front matter)
  static int findStartPosition(String text) {
    final chapterPattern = RegExp(
      r'Chapter\s+1|CHAPTER\s+I\b|Part\s+1',
      caseSensitive: false,
    );
    
    final match = chapterPattern.firstMatch(text);
    return match?.start ?? 0;
  }
}
