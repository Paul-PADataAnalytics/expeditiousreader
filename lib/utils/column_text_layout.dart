import 'package:flutter/material.dart';
import 'dart:ui' as ui;

// ignore: avoid_print
void debugLog(String message) {
  debugPrint('[ColumnTextLayout] $message');
}

/// Represents a single page with its word range
class ColumnPage {
  final int startWordIndex;
  final int endWordIndex;
  final List<List<String>> columns; // Each column contains lines of text

  ColumnPage({
    required this.startWordIndex,
    required this.endWordIndex,
    required this.columns,
  });

  int get wordCount => endWordIndex - startWordIndex;
}

/// Layout engine for multi-column text with dynamic fitting
class ColumnTextLayout {
  /// Calculates pages with text laid out in columns
  /// Returns a list of ColumnPage objects
  ///
  /// To prevent UI freezing on large books, this can optionally limit
  /// the number of pages to calculate, and start from a specific word index
  static List<ColumnPage> layoutText({
    required String text,
    required double availableWidth,
    required double availableHeight,
    required TextStyle textStyle,
    required int numberOfColumns,
    required double columnGap,
    required double horizontalPadding,
    required double verticalPadding,
    int? maxPages, // Optional limit on pages to calculate
    int startWordIndex = 0, // Where to start laying out from
    List<String>? preProcessedWords, // Optional pre-split words array
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    final List<ColumnPage> pages = [];
    final words = preProcessedWords ?? text.split(RegExp(r'\s+'));

    if (words.isEmpty || startWordIndex >= words.length) return pages;

    int currentWordIndex = startWordIndex;
    int pageCount = 0;

    while (currentWordIndex < words.length) {
      // Check if we've hit the page limit
      if (maxPages != null && pageCount >= maxPages) {
        break;
      }

      final page = _layoutSinglePage(
        words: words,
        startWordIndex: currentWordIndex,
        availableWidth: availableWidth,
        availableHeight: availableHeight,
        textStyle: textStyle,
        numberOfColumns: numberOfColumns,
        columnGap: columnGap,
        horizontalPadding: horizontalPadding,
        verticalPadding: verticalPadding,
        textScaler: textScaler,
      );

      pages.add(page);
      currentWordIndex = page.endWordIndex;
      pageCount++;

      // Safety check to prevent infinite loops
      if (page.wordCount == 0) {
        currentWordIndex++;
      }
    }

    return pages;
  }

  static ColumnPage _layoutSinglePage({
    required List<String> words,
    required int startWordIndex,
    required double availableWidth,
    required double availableHeight,
    required TextStyle textStyle,
    required int numberOfColumns,
    required double columnGap,
    required double horizontalPadding,
    required double verticalPadding,
    required TextScaler textScaler,
  }) {
    // Calculate column width - gaps are subtracted, padding handled by widget tree
    final totalGapWidth = columnGap * (numberOfColumns - 1);
    final columnWidth = (availableWidth - totalGapWidth) / numberOfColumns;
    // More aggressive safety margin accounting for text scale and line height
    final textScaleFactor = textScaler.scale(1.0);
    // Base margin of 8px, scaled by text factor, plus an additional line's worth of safety
    final estimatedLineHeight =
        textStyle.fontSize! * (textStyle.height ?? 1.0) * textScaleFactor;
    final safetyMargin = (8.0 * textScaleFactor) + (estimatedLineHeight * 0.5);
    final contentHeight = availableHeight - safetyMargin;

    debugLog(
      'Layout params: textScale=$textScaleFactor, fontSize=${textStyle.fontSize}, '
      'lineHeight=${textStyle.height}, estimatedLineHeight=$estimatedLineHeight, '
      'safetyMargin=$safetyMargin, availableHeight=$availableHeight, contentHeight=$contentHeight',
    );

    /*
      PARAGRAPH-BASED LAYOUT STRATEGY:
      Instead of measuring line-by-line (which accumulates wrapping errors),
      we dump a large chunk of text into the TextPainter and let the native engine
      determine line breaks. We then check how many lines fit vertically.
    */

    final List<List<String>> columns = List.generate(
      numberOfColumns,
      (_) => [],
    );
    int currentWordIndex = startWordIndex;
    int currentColumnIndex = 0;

    // Create a generic TextPainter
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    );

    while (currentColumnIndex < numberOfColumns &&
        currentWordIndex < words.length) {
      // 1. Prepare Chunk
      // We take a slice of words that is definitely larger than what fits in one column,
      // but small enough to be efficient.
      int endChunkIndex = (currentWordIndex + 500 < words.length)
          ? currentWordIndex + 500
          : words.length;

      // If previous chunk wasn't enough, expand range (rare)
      // For now, simpler logic: verify sufficiency after layout.

      // Join words simply. Note: this loses custom spacing if original had double spaces.
      // But standard 'split' logic implies single space.
      final chunkWords = words.sublist(currentWordIndex, endChunkIndex);
      final String chunkText = chunkWords.join(' ');

      // 2. Layout Full Chunk
      textPainter.text = TextSpan(text: chunkText, style: textStyle);
      textPainter.layout(maxWidth: columnWidth);

      // 3. Find Vertical Cutoff
      final List<ui.LineMetrics> lines = textPainter.computeLineMetrics();
      double occupiedHeight = 0;
      int linesThatFit = 0;

      for (final line in lines) {
        if (occupiedHeight + line.height >= contentHeight) {
          break;
        }
        occupiedHeight += line.height;
        linesThatFit++;
      }

      debugLog(
        'Column $currentColumnIndex: total lines=${lines.length}, fit=$linesThatFit, '
        'occupiedHeight=$occupiedHeight, contentHeight=$contentHeight',
      );

      // Universal: Reduce line count by 1 for extra safety across all platforms
      // This accounts for subtle rendering differences and estimation errors
      if (linesThatFit > 1) {
        // Keep at least 1 line
        linesThatFit--;
        debugLog('Reduced linesThatFit to $linesThatFit for safety');
      }

      // 4. Extract Content for this Column
      if (linesThatFit == 0 && lines.isNotEmpty) {
        // Edge Case: First line doesn't fit?
        // Force one line to avoid infinite loop (or just render what we can)
        linesThatFit = 1;
      }

      String columnContent;
      int wordsConsumed = 0;

      if (linesThatFit >= lines.length) {
        // All words in the chunk fit!
        // We might have under-filled the column if chunk was too small.
        // But for 500 words, that's unlikely unless font is tiny.
        // If we strictly need to fill, we should loop and add more.
        // For this implementation, we assume 500 words is enough for one column.
        columnContent = chunkText;
        wordsConsumed = chunkWords.length;
      } else {
        // We have a vertical overflow.
        // Get the boundary of the last fitting line.
        final lastLineMetrics = lines[linesThatFit - 1];

        // The character index where this line ends (exclusive) is technically hard to get directly from metrics.
        // We use getPositionForOffset to find the end of the line.
        // Offset: rightmost edge (columnWidth - 4 for safety), bottom of the line.
        final endPos = textPainter.getPositionForOffset(
          Offset(
            columnWidth -
                4.0, // More conservative offset to prevent horizontal overflow
            lastLineMetrics.baseline + lastLineMetrics.descent,
          ),
        );
        int splitIndex = endPos.offset;

        // Verify splitIndex is valid
        if (splitIndex > chunkText.length) splitIndex = chunkText.length;

        // SNAP TO WORD BOUNDARY
        // If splitIndex is in middle of a word, backtrack to space.
        while (splitIndex > 0 &&
            splitIndex < chunkText.length &&
            chunkText[splitIndex] != ' ') {
          splitIndex--;
        }

        if (splitIndex == 0) {
          // Fallback: force take the whole first word if it was huge
          splitIndex = chunkText.indexOf(' ');
          if (splitIndex == -1) splitIndex = chunkText.length;
        }

        columnContent = chunkText.substring(0, splitIndex).trim();

        // Count words consumed
        // Recalculating from the substring is safer than index math
        if (columnContent.isNotEmpty) {
          wordsConsumed = columnContent.split(RegExp(r'\s+')).length;
        }
      }

      // 5. Store and Advance
      // We store the raw string (joined by newlines? or just the block?)
      // User renderer expects "lines".
      // But we just calculated a block.
      // We can split the block back into lines if needed, or change the ColumnPage definition.
      // Getting strict lines from TextPainter is possible but we just need the text.
      // The renderer does `Text(columnLines.join('\n'))`.
      // So we can just put the whole content as one item in the list if we want,
      // or split by newline if there were any (there aren't).
      // Let's just put it as one "line" which is the whole paragraph.

      columns[currentColumnIndex].add(columnContent);

      currentWordIndex += wordsConsumed;
      currentColumnIndex++;
    }

    return ColumnPage(
      startWordIndex: startWordIndex,
      endWordIndex: currentWordIndex,
      columns: columns,
    );
  }
}
