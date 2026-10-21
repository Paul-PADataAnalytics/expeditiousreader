import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'text_processor.dart';

/// Represents a single typeset page with its exact word range, column spans, and measured geometry
class ColumnPage {
  final int startWordIndex;
  final int endWordIndex;
  final List<List<String>> columns; // Plain text fallback per column
  final List<TextSpan> columnSpans; // Rich formatted spans (headings + carriage returns)
  final double columnWidth;
  final double columnHeight;

  ColumnPage({
    required this.startWordIndex,
    required this.endWordIndex,
    required this.columns,
    this.columnSpans = const [],
    this.columnWidth = 0.0,
    this.columnHeight = 0.0,
  });

  int get wordCount => endWordIndex - startWordIndex;
}

class _BuiltChunkSpan {
  final TextSpan span;
  final String plainText;
  final List<int> wordEndOffsets;

  const _BuiltChunkSpan({
    required this.span,
    required this.plainText,
    required this.wordEndOffsets,
  });
}

/// Deterministic, exact-fitting multi-column typesetting engine.
/// Uses identical TextPainter parameters for both measurement and painting so that
/// text fills the maximum possible vertical/horizontal space without ever clipping or rolling off.
class ColumnTextLayout {
  /// Shared TextHeightBehavior used during both layout measurement and canvas painting.
  /// Disabling extra leading on first ascent and last descent allows the first line to sit
  /// flush at the top of the column and the last line's descent to sit flush at the bottom.
  static const TextHeightBehavior kTextHeightBehavior = TextHeightBehavior(
    applyHeightToFirstAscent: false,
    applyHeightToLastDescent: false,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Normalize the base TextStyle so ambient DefaultTextStyle properties (like M3 letterSpacing)
  /// can never cause measurement and rendering to diverge.
  static TextStyle normalizeBaseStyle(TextStyle style) {
    return style.copyWith(
      inherit: false,
      letterSpacing: style.letterSpacing ?? 0.0,
      wordSpacing: style.wordSpacing ?? 0.0,
      textBaseline: TextBaseline.alphabetic,
    );
  }

  static List<ColumnPage> layoutText({
    required String text,
    required double availableWidth,
    required double availableHeight,
    required TextStyle textStyle,
    required int numberOfColumns,
    required double columnGap,
    required double horizontalPadding,
    required double verticalPadding,
    int? maxPages,
    int startWordIndex = 0,
    List<String>? preProcessedWords,
    List<RichWord>? preProcessedRichWords,
    bool respectFormatting = true,
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    final List<ColumnPage> pages = [];
    final List<RichWord> richWords = preProcessedRichWords ??
        (preProcessedWords != null
            ? preProcessedWords.map((w) => RichWord(text: w)).toList()
            : TextProcessor.parseRichWords(text));

    final effectiveWidth = (availableWidth - (horizontalPadding * 2)).floorToDouble();
    final effectiveHeight = (availableHeight - (verticalPadding * 2)).floorToDouble();

    if (richWords.isEmpty ||
        startWordIndex >= richWords.length ||
        effectiveWidth <= 20 ||
        effectiveHeight <= 20) {
      return pages;
    }

    final normalizedStyle = normalizeBaseStyle(textStyle);
    int currentWordIndex = startWordIndex;
    int pageCount = 0;

    while (currentWordIndex < richWords.length) {
      if (maxPages != null && pageCount >= maxPages) {
        break;
      }

      final page = _layoutSinglePage(
        richWords: richWords,
        startWordIndex: currentWordIndex,
        availableWidth: effectiveWidth,
        availableHeight: effectiveHeight,
        textStyle: normalizedStyle,
        numberOfColumns: numberOfColumns,
        columnGap: columnGap,
        respectFormatting: respectFormatting,
        textScaler: textScaler,
      );

      pages.add(page);
      currentWordIndex = page.endWordIndex;
      pageCount++;

      if (page.wordCount == 0) {
        currentWordIndex++;
      }
    }

    return pages;
  }

  static TextStyle _styleForHeading(
    TextStyle baseStyle,
    int headingLevel,
    bool respectFormatting,
  ) {
    if (!respectFormatting || headingLevel <= 0) {
      return baseStyle;
    }
    final baseFontSize = baseStyle.fontSize ?? 18.0;
    switch (headingLevel) {
      case 1:
        return baseStyle.copyWith(
          fontSize: baseFontSize * 1.38,
          fontWeight: FontWeight.bold,
          height: 1.28,
        );
      case 2:
        return baseStyle.copyWith(
          fontSize: baseFontSize * 1.22,
          fontWeight: FontWeight.bold,
          height: 1.3,
        );
      default:
        return baseStyle.copyWith(
          fontSize: baseFontSize * 1.10,
          fontWeight: FontWeight.w600,
          height: 1.32,
        );
    }
  }

  static _BuiltChunkSpan _buildSpanForSlice(
    List<RichWord> slice,
    TextStyle baseStyle,
    bool respectFormatting,
  ) {
    final children = <InlineSpan>[];
    final buffer = StringBuffer();
    final wordEndOffsets = <int>[];

    final baseFontSize = baseStyle.fontSize ?? 18.0;
    final paragraphGapStyle = baseStyle.copyWith(
      fontSize: baseFontSize * 0.42,
      height: 1.0,
    );

    int currentHeading = slice.isNotEmpty ? (respectFormatting ? slice.first.headingLevel : 0) : 0;
    final runBuffer = StringBuffer();

    void flushRun(int heading) {
      if (runBuffer.isEmpty) return;
      children.add(
        TextSpan(
          text: runBuffer.toString(),
          style: _styleForHeading(baseStyle, heading, respectFormatting),
        ),
      );
      runBuffer.clear();
    }

    for (int i = 0; i < slice.length; i++) {
      final rw = slice[i];
      final effectiveHeading = respectFormatting ? rw.headingLevel : 0;
      if (effectiveHeading != currentHeading) {
        flushRun(currentHeading);
        currentHeading = effectiveHeading;
      }

      runBuffer.write(rw.text);
      buffer.write(rw.text);
      wordEndOffsets.add(buffer.length);

      if (i < slice.length - 1) {
        if (!respectFormatting || rw.lineBreaksAfter <= 0) {
          runBuffer.write(' ');
          buffer.write(' ');
        } else if (rw.lineBreaksAfter == 1) {
          runBuffer.write('\n');
          buffer.write('\n');
        } else {
          // Paragraph break: newline at end of current paragraph + compact typographic gap line
          runBuffer.write('\n');
          buffer.write('\n');
          flushRun(currentHeading);
          children.add(TextSpan(text: '\n', style: paragraphGapStyle));
          buffer.write('\n');
        }
      }
    }
    flushRun(currentHeading);

    return _BuiltChunkSpan(
      span: TextSpan(style: baseStyle, children: children),
      plainText: buffer.toString(),
      wordEndOffsets: wordEndOffsets,
    );
  }

  static double measureSpanHeight({
    required TextSpan span,
    required double columnWidth,
    required TextScaler textScaler,
  }) {
    final painter = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
      textHeightBehavior: kTextHeightBehavior,
    )..layout(maxWidth: columnWidth);
    return painter.height;
  }

  static ColumnPage _layoutSinglePage({
    required List<RichWord> richWords,
    required int startWordIndex,
    required double availableWidth,
    required double availableHeight,
    required TextStyle textStyle,
    required int numberOfColumns,
    required double columnGap,
    required bool respectFormatting,
    required TextScaler textScaler,
  }) {
    final totalGapWidth = columnGap * (numberOfColumns - 1);
    final columnWidth = math.max(
      40.0,
      ((availableWidth - totalGapWidth) / numberOfColumns).floorToDouble(),
    );
    final targetHeight = math.max(40.0, availableHeight.floorToDouble());

    // Dynamically size the candidate chunk window so even large desktop screens at small font sizes
    // never run out of words before filling the column.
    final baseFontSize = (textStyle.fontSize ?? 18.0) * textScaler.scale(1.0);
    final estCharsPerLine = math.max(15, (columnWidth / (baseFontSize * 0.42)).ceil());
    final estMaxLines = math.max(8, (targetHeight / (baseFontSize * 1.05)).ceil());
    final maxChunkWords = ((estCharsPerLine * estMaxLines) / 3.2).ceil().clamp(600, 3200);

    final List<List<String>> columns = List.generate(numberOfColumns, (_) => []);
    final List<TextSpan> columnSpans = [];
    int currentWordIndex = startWordIndex;
    int currentColumnIndex = 0;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
      textHeightBehavior: kTextHeightBehavior,
    );

    double measureSlice(List<RichWord> chunkSlice, int wordCount) {
      final candidateBuilt = _buildSpanForSlice(
        chunkSlice.sublist(0, wordCount),
        textStyle,
        respectFormatting,
      );
      textPainter.text = candidateBuilt.span;
      textPainter.layout(maxWidth: columnWidth);
      return textPainter.height;
    }

    while (currentColumnIndex < numberOfColumns && currentWordIndex < richWords.length) {
      final int endChunkIndex = math.min(currentWordIndex + maxChunkWords, richWords.length);
      final chunkSlice = richWords.sublist(currentWordIndex, endChunkIndex);
      final builtChunk = _buildSpanForSlice(chunkSlice, textStyle, respectFormatting);

      textPainter.text = builtChunk.span;
      textPainter.layout(maxWidth: columnWidth);

      int wordsConsumed = 0;

      if (textPainter.height <= targetHeight) {
        wordsConsumed = chunkSlice.length;
      } else {
        final List<ui.LineMetrics> lines = textPainter.computeLineMetrics();
        double cumulativeHeight = 0.0;
        int linesThatFit = 0;

        for (final line in lines) {
          if (cumulativeHeight + line.height > targetHeight + 0.5) {
            break;
          }
          cumulativeHeight += line.height;
          linesThatFit++;
        }

        if (linesThatFit <= 0) {
          wordsConsumed = 1;
        } else if (linesThatFit >= lines.length) {
          wordsConsumed = chunkSlice.length;
        } else {
          final lastFittingLine = lines[linesThatFit - 1];
          // Sample near the vertical middle of the last fitting line at the right edge of the column
          final lineMidY = lastFittingLine.baseline - (lastFittingLine.ascent * 0.45);
          final endPos = textPainter.getPositionForOffset(
            Offset(columnWidth, lineMidY),
          );
          final int splitOffset = endPos.offset.clamp(0, builtChunk.plainText.length);

          // Binary search for the last word whose end offset is <= splitOffset
          int low = 0;
          int high = builtChunk.wordEndOffsets.length - 1;
          int bestIdx = -1;
          while (low <= high) {
            final mid = (low + high) >> 1;
            if (builtChunk.wordEndOffsets[mid] <= splitOffset) {
              bestIdx = mid;
              low = mid + 1;
            } else {
              high = mid - 1;
            }
          }
          wordsConsumed = bestIdx >= 0 ? bestIdx + 1 : 1;
        }

        // Exact post-slice verification & greedy packing:
        // 1. If the sliced span exceeds targetHeight (e.g. due to word wrap boundary), step down.
        while (wordsConsumed > 1 && measureSlice(chunkSlice, wordsConsumed) > targetHeight) {
          wordsConsumed--;
        }
        // 2. Greedily add words as long as they still fit within targetHeight.
        while (wordsConsumed < chunkSlice.length &&
            measureSlice(chunkSlice, wordsConsumed + 1) <= targetHeight) {
          wordsConsumed++;
        }

        // 3. Prevent dangling/widow headings at the very bottom of a column:
        // If the column ends with a heading (headingLevel > 0) preceded by normal body text,
        // move that heading to the top of the next column.
        if (respectFormatting && wordsConsumed > 1 && wordsConsumed < chunkSlice.length) {
          int headingStart = wordsConsumed;
          while (headingStart > 0 && chunkSlice[headingStart - 1].headingLevel > 0) {
            headingStart--;
          }
          if (headingStart > 0 && headingStart < wordsConsumed) {
            wordsConsumed = headingStart;
          }
        }
      }

      final fittedSlice = chunkSlice.sublist(0, wordsConsumed);
      final fittedBuilt = _buildSpanForSlice(fittedSlice, textStyle, respectFormatting);

      columns[currentColumnIndex].add(fittedBuilt.plainText);
      columnSpans.add(fittedBuilt.span);

      currentWordIndex += wordsConsumed;
      currentColumnIndex++;
    }

    return ColumnPage(
      startWordIndex: startWordIndex,
      endWordIndex: currentWordIndex,
      columns: columns,
      columnSpans: columnSpans,
      columnWidth: columnWidth,
      columnHeight: targetHeight,
    );
  }
}
