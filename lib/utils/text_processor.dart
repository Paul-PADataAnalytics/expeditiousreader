class RichWord {
  final String text;
  final int headingLevel; // 0 = body, 1 = H1, 2 = H2, 3 = H3
  final int lineBreaksAfter; // 0 = space, 1 = newline (\n), 2 = paragraph break (\n\n)

  const RichWord({
    required this.text,
    this.headingLevel = 0,
    this.lineBreaksAfter = 0,
  });
}

class ChapterInfo {
  final int number;
  final int wordIndex;
  final String title;

  const ChapterInfo({
    required this.number,
    required this.wordIndex,
    required this.title,
  });
}

class TextProcessor {
  /// Clean and normalize text while preserving carriage returns, paragraph breaks, and heading markers
  static String cleanText(String text) {
    // Normalize line breaks (handle different OS formats)
    text = text.replaceAll('\r\n', '\n');
    text = text.replaceAll('\r', '\n');

    // Remove standalone Table of Contents / Index blocks in plain-text/PDF imports
    text = _removeTableOfContents(text);

    // Trim spaces on each line while preserving line breaks
    final cleanedLines = <String>[];
    for (final rawLine in text.split('\n')) {
      final trimmed = rawLine.replaceAll(RegExp(r'[ \t]+'), ' ').trim();
      cleanedLines.add(trimmed);
    }
    text = cleanedLines.join('\n');

    // Collapse 3+ consecutive newlines down to a clean paragraph break (\n\n)
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return text.trim();
  }

  /// Determine whether an EPUB spine section is front-matter or back-matter boilerplate
  /// (e.g. Copyright, Title Page, Table of Contents, Dedication, Credits, About the Author).
  static bool isFrontOrBackMatterSection({
    String? title,
    String? fileName,
    required String text,
  }) {
    final t = (title ?? '').trim().toLowerCase();
    final fn = (fileName ?? '').trim().toLowerCase();
    final sample = text.trim();
    if (sample.isEmpty) return true;

    final lowerText =
        sample.length > 2500 ? sample.substring(0, 2500).toLowerCase() : sample.toLowerCase();

    // 1. Check filename and section title patterns for non-chapter front/back matter
    final boilerplateFileOrTitle = RegExp(
      r'(^|[/_.-])(cover|title|titlepage|halftitle|copyright|colophon|legal|dedication|epigraph|'
      r'toc|nav|contents|acknowledg|about[_ -]?the[_ -]?author|about[_ -]?the[_ -]?reviewer|'
      r'credits|imprint|frontmatter|backmatter|advert|other[_ -]?books|also[_ -]?by|index|glossary)([/_.-]|$)',
      caseSensitive: false,
    );
    if (boilerplateFileOrTitle.hasMatch(fn) || boilerplateFileOrTitle.hasMatch(t)) {
      // Make sure it isn't actually "Chapter 1"
      if (!RegExp(r'\b(chapter|part)\s+([1-9]|one|i)\b', caseSensitive: false).hasMatch(t)) {
        return true;
      }
    }

    // 2. Check content for copyright / legal / ISBN colophon pages
    int copyrightSignals = 0;
    const legalPhrases = [
      'all rights reserved',
      'no part of this publication',
      'no part of this book',
      'library of congress',
      'limit of liability',
      'disclaimer of warranty',
      'trademarks:',
      'printed in the united states',
      'printed in the uk',
      'published by',
      'copyright ©',
      'copyright (c)',
      'isbn:',
      'isbn-13',
      'isbn 978',
    ];
    for (final phrase in legalPhrases) {
      if (lowerText.contains(phrase)) {
        copyrightSignals++;
      }
    }
    final wordCount = sample.split(RegExp(r'\s+')).length;
    if (copyrightSignals >= 2 && wordCount < 1500) {
      return true;
    }

    // 3. Check if the section is a Table of Contents page (many lines of links/chapter listings)
    final firstLine = sample.split('\n').firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
    final cleanFirstLine = firstLine.replaceAll(RegExp(r'^#+\s*'), '').trim().toLowerCase();
    if (cleanFirstLine == 'contents' ||
        cleanFirstLine == 'table of contents' ||
        cleanFirstLine == 'brief contents' ||
        cleanFirstLine == 'copyright' ||
        cleanFirstLine == 'credits' ||
        cleanFirstLine == 'about the author' ||
        cleanFirstLine == 'about the authors' ||
        cleanFirstLine == 'about the reviewers' ||
        cleanFirstLine == 'acknowledgments' ||
        cleanFirstLine == 'acknowledgements' ||
        cleanFirstLine == 'dedication') {
      if (wordCount < 2500) {
        return true;
      }
    }

    // 4. Very short title/cover splash pages (< 35 words with no sentence punctuation)
    if (wordCount < 35 && !sample.contains('.')) {
      return true;
    }

    return false;
  }

  /// Parse structured book text into a list of RichWord objects that preserve:
  /// - Heading level (from `# `, `## `, `### ` line prefixes or ALL-CAPS chapter headers)
  /// - Single carriage returns (`\n`) and paragraph breaks (`\n\n`)
  /// While maintaining exact 1-to-1 indexing with `splitIntoWords(text)`.
  static List<RichWord> parseRichWords(String text) {
    if (text.trim().isEmpty) return [];

    final normalized = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
    final rawLines = normalized.split('\n');
    final result = <RichWord>[];

    int i = 0;
    while (i < rawLines.length) {
      String line = rawLines[i].trim();
      if (line.isEmpty) {
        i++;
        continue;
      }

      // Detect heading marker prefix (`# `, `## `, `### `)
      int headingLevel = 0;
      if (line.startsWith('### ')) {
        headingLevel = 3;
        line = line.substring(4).trim();
      } else if (line.startsWith('## ')) {
        headingLevel = 2;
        line = line.substring(3).trim();
      } else if (line.startsWith('# ')) {
        headingLevel = 1;
        line = line.substring(2).trim();
      } else if (RegExp(
        r'^(Chapter\s+\d+|CHAPTER\s+[IVXLC\d]+|Part\s+[IVXLC\d]+|Prologue|Introduction)\b',
        caseSensitive: false,
      ).hasMatch(line) &&
          line.length < 90) {
        headingLevel = 1;
      }

      // Count how many consecutive newlines follow this line
      int nextNonEmpty = i + 1;
      while (nextNonEmpty < rawLines.length && rawLines[nextNonEmpty].trim().isEmpty) {
        nextNonEmpty++;
      }
      final blankLinesBetween = nextNonEmpty - (i + 1);
      final int lineBreaksAfter = nextNonEmpty >= rawLines.length
          ? 0
          : (blankLinesBetween >= 1 || headingLevel > 0 ? 2 : 1);

      final lineWords = line.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      for (int wIdx = 0; wIdx < lineWords.length; wIdx++) {
        final isLastWordOnLine = wIdx == lineWords.length - 1;
        result.add(
          RichWord(
            text: lineWords[wIdx],
            headingLevel: headingLevel,
            lineBreaksAfter: isLastWordOnLine ? lineBreaksAfter : 0,
          ),
        );
      }

      i = nextNonEmpty;
    }

    return result;
  }

  /// Split text into display words (1-to-1 with parseRichWords)
  static List<String> splitIntoWords(String text) {
    return parseRichWords(text).map((rw) => rw.text).toList();
  }

  /// Count words
  static int countWords(String text) {
    return splitIntoWords(text).length;
  }

  /// Calculate exact word-index chapter positions from a list of chapter text blocks
  static List<int> calculateChapterWordPositions(List<String> chapters) {
    final positions = <int>[];
    int cumulativeWords = 0;

    for (final chapter in chapters) {
      final chapterWordCount = countWords(chapter);
      if (chapterWordCount > 0) {
        positions.add(cumulativeWords);
        cumulativeWords += chapterWordCount;
      }
    }
    return positions;
  }

  /// Backwards-compatible wrapper that returns word indices for chapters
  static List<int> calculateChapterPositions(String fullText, List<String> chapters) {
    return calculateChapterWordPositions(chapters);
  }

  /// Detect chapters in plain-text or PDF books and return their exact WORD indices
  static List<int> detectChapters(String text) {
    final richWords = parseRichWords(text);
    if (richWords.isEmpty) return [0];

    final positions = <int>[];
    for (int i = 0; i < richWords.length; i++) {
      final rw = richWords[i];
      final isLineStart = i == 0 || richWords[i - 1].lineBreaksAfter > 0;
      if (!isLineStart) continue;

      if (rw.headingLevel == 1) {
        positions.add(i);
        continue;
      }

      final wLower = rw.text.toLowerCase();
      if ((wLower == 'chapter' || wLower == 'part' || wLower == 'prologue') &&
          i + 1 < richWords.length) {
        final nextWord = richWords[i + 1].text;
        if (RegExp(r'^(\d+|[IVXLC]+|one|two|three|four|five|six|seven|eight|nine|ten)\b',
                caseSensitive: false)
            .hasMatch(nextWord)) {
          positions.add(i);
        }
      }
    }

    if (positions.isEmpty || positions.first != 0) {
      positions.insert(0, 0);
    }
    return positions;
  }

  /// Normalize stored chapterPositions (converting legacy character offsets to word indices if needed)
  static List<int> normalizeChapterWordPositions(
    List<int> storedPositions,
    int totalWords,
    int fullTextLength,
  ) {
    if (storedPositions.isEmpty || totalWords <= 0) return [0];

    // If any stored position exceeds totalWords, the list was stored as legacy character offsets
    final isLegacyCharOffsets = storedPositions.any((p) => p >= totalWords);
    if (!isLegacyCharOffsets) {
      return storedPositions.map((p) => p.clamp(0, totalWords - 1)).toSet().toList()..sort();
    }

    if (fullTextLength <= 0) return [0];
    return storedPositions
        .map((charPos) => ((charPos / fullTextLength) * totalWords).round().clamp(0, totalWords - 1))
        .toSet()
        .toList()
      ..sort();
  }

  /// Build human-readable ChapterInfo list with titles/previews for the chapter jump menu
  static List<ChapterInfo> buildChapterInfoList(
    List<RichWord> richWords,
    List<int> chapterWordPositions,
  ) {
    if (richWords.isEmpty) return [];
    final positions = chapterWordPositions.isEmpty ? [0] : chapterWordPositions;
    final chapters = <ChapterInfo>[];

    for (int idx = 0; idx < positions.length; idx++) {
      final start = positions[idx].clamp(0, richWords.length - 1);
      final previewWords = <String>[];
      for (int w = start; w < richWords.length && previewWords.length < 10; w++) {
        previewWords.add(richWords[w].text);
        if (richWords[w].lineBreaksAfter > 0 && previewWords.length >= 2) {
          break;
        }
      }
      final title = previewWords.isEmpty
          ? 'Chapter ${idx + 1}'
          : previewWords.join(' ');
      chapters.add(
        ChapterInfo(
          number: idx + 1,
          wordIndex: start,
          title: title,
        ),
      );
    }
    return chapters;
  }

  /// Find the exact WORD index to start reading (skipping any remaining front-matter / copyright)
  static int findStartPosition(String text, {List<int>? chapterPositions}) {
    final richWords = parseRichWords(text);
    if (richWords.isEmpty) return 0;

    // Look for an explicit Chapter 1 / Prologue / Introduction heading in the first 25% of the book
    final searchLimit = (richWords.length * 0.25).round().clamp(1, richWords.length);
    for (int i = 0; i < searchLimit - 1; i++) {
      final isLineStart = i == 0 || richWords[i - 1].lineBreaksAfter > 0;
      if (!isLineStart) continue;

      final w = richWords[i].text.toLowerCase();
      final nextW = richWords[i + 1].text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (w == 'chapter' && (nextW == '1' || nextW == 'one' || nextW == 'i' || nextW == '01')) {
        return i;
      }
      if ((w == 'prologue' || w == 'introduction') && richWords[i].headingLevel > 0) {
        return i;
      }
    }

    if (chapterPositions != null && chapterPositions.isNotEmpty) {
      return chapterPositions.first.clamp(0, richWords.length - 1);
    }
    return 0;
  }

  /// Remove standalone Table of Contents block in plain text / PDF
  static String _removeTableOfContents(String text) {
    final tocPattern = RegExp(
      r'^(Table of )?Contents\s*\n(?:[^\n]*\.{3,}\s*\d+\s*\n)+',
      caseSensitive: false,
      multiLine: true,
    );
    return text.replaceAll(tocPattern, '');
  }
}
