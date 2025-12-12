import 'package:flutter/material.dart';

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
  }) {
    // Calculate column width
    // Note: availableWidth/Height should already have padding applied in the widget tree
    // So we only subtract the gaps between columns, not the padding
    final totalGapWidth = columnGap * (numberOfColumns - 1);
    final calculatedColumnWidth = (availableWidth - totalGapWidth) / numberOfColumns;
    
    // Apply a small safety margin (5.0%) to account for TextPainter vs Text widget rendering differences
    // This prevents rare edge cases where a line is just slightly too wide
    final columnWidth = calculatedColumnWidth * 0.95;
    final contentHeight = availableHeight;

    final List<List<String>> columns = List.generate(numberOfColumns, (_) => []);
    int currentWordIndex = startWordIndex;
    int currentColumnIndex = 0;

    // Create a TextPainter for measuring
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );

    // Calculate line height and average character width ONCE
    textPainter.text = TextSpan(text: 'M', style: textStyle);
    textPainter.layout();
    final lineHeight = textPainter.height;

    // Calculate max lines per column
    // No safety margin - fill the maximum available height
    final maxLinesPerColumn = (contentHeight / lineHeight).floor().clamp(1, 1000);

    if (maxLinesPerColumn <= 0) {
      // Not enough height, return empty page
      return ColumnPage(
        startWordIndex: startWordIndex,
        endWordIndex: startWordIndex,
        columns: columns,
      );
    }

    // Fill columns using accurate TextPainter measurements
    while (currentColumnIndex < numberOfColumns && currentWordIndex < words.length) {
      final columnLines = columns[currentColumnIndex];
      String currentLine = '';
      
      while (columnLines.length < maxLinesPerColumn && currentWordIndex < words.length) {
        final word = words[currentWordIndex];
        final testLine = currentLine.isEmpty ? word : '$currentLine $word';
        
        // Measure the actual width of the test line
        textPainter.text = TextSpan(text: testLine, style: textStyle);
        textPainter.layout(maxWidth: double.infinity);
        final testWidth = textPainter.width;

        if (testWidth <= columnWidth || currentLine.isEmpty) {
          // Word fits on current line (or it's the first word - force it)
          currentLine = testLine;
          currentWordIndex++;
        } else {
          // Word doesn't fit, start new line
          if (currentLine.isNotEmpty) {
            columnLines.add(currentLine);
            currentLine = '';
          }

          // Check if we've filled this column
          if (columnLines.length >= maxLinesPerColumn) {
            break;
          }
        }
      }

      // Add any remaining text on current line
      if (currentLine.isNotEmpty && columnLines.length < maxLinesPerColumn) {
        columnLines.add(currentLine);
      }

      currentColumnIndex++;
    }

    return ColumnPage(
      startWordIndex: startWordIndex,
      endWordIndex: currentWordIndex,
      columns: columns,
    );
  }
}