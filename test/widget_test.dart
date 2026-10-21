import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:expeditiousreader/screens/library_screen.dart';
import 'package:expeditiousreader/providers/library_provider.dart';
import 'package:expeditiousreader/providers/settings_provider.dart';
import 'package:expeditiousreader/utils/column_text_layout.dart';
import 'package:expeditiousreader/utils/text_processor.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TextProcessor tests', () {
    test('parseRichWords preserves headings, paragraph breaks, and line breaks', () {
      const sample = '# Chapter 1: The Beginning\n\nFirst line of text.\nSecond line of text.';
      final richWords = TextProcessor.parseRichWords(sample);

      expect(richWords, isNotEmpty);
      expect(richWords[0].text, 'Chapter');
      expect(richWords[0].headingLevel, 1);

      final beginningWord = richWords.firstWhere((w) => w.text == 'Beginning');
      expect(beginningWord.lineBreaksAfter, 2);

      final textWord = richWords.firstWhere((w) => w.text == 'text.');
      expect(textWord.lineBreaksAfter, 1);
    });

    test('findStartPosition skips front-matter boilerplate and finds Chapter 1', () {
      final bodyWords = List.generate(120, (i) => 'word$i').join(' ');
      final sample = '''
Title Page
Copyright 2024 All rights reserved.

# Chapter 1: Into the Wild

$bodyWords
''';
      final startIdx = TextProcessor.findStartPosition(sample);
      final words = TextProcessor.splitIntoWords(sample);
      expect(startIdx, greaterThan(0));
      expect(words[startIdx], 'Chapter');
    });

    test('isFrontOrBackMatterSection identifies copyright and TOC sections', () {
      expect(
        TextProcessor.isFrontOrBackMatterSection(
          title: 'Copyright',
          fileName: 'copyright.xhtml',
          text: 'Copyright 2024 All rights reserved. ISBN 978-1-23456-789-0.',
        ),
        isTrue,
      );
      expect(
        TextProcessor.isFrontOrBackMatterSection(
          title: 'Chapter 1',
          fileName: 'ch01.xhtml',
          text: 'It was a bright cold day in April, and the clocks were striking thirteen. '
              'Winston Smith, his chin nuzzled into his breast in an effort to escape the vile wind, '
              'slipped quickly through the glass doors of Victory Mansions, though not quickly enough '
              'to prevent a swirl of gritty dust from entering along with him.',
        ),
        isFalse,
      );
    });
  });

  group('ColumnTextLayout exact-fit typesetting tests', () {
    test('fills available column height without overflowing across arbitrary screen sizes', () {
      final paragraphs = List.generate(
        25,
        (p) =>
            'Paragraph ${p + 1} explores the art of digital typesetting across mobile, web, and desktop screens '
            'without losing a single word or overflowing the bottom boundary of any column.',
      );
      final sampleText = '# Chapter 1: Typesetting\n\n${paragraphs.join('\n\n')}';
      final richWords = TextProcessor.parseRichWords(sampleText);

      const viewports = [
        Size(360, 640), // Mobile portrait
        Size(768, 1024), // Tablet
        Size(1440, 900), // Desktop widescreen
      ];

      for (final size in viewports) {
        for (final cols in [1, 2, 3]) {
          for (final respectFormatting in [true, false]) {
            final pages = ColumnTextLayout.layoutText(
              text: '',
              availableWidth: size.width,
              availableHeight: size.height,
              textStyle: const TextStyle(fontSize: 18, height: 1.4),
              numberOfColumns: cols,
              columnGap: 24,
              horizontalPadding: 16,
              verticalPadding: 16,
              preProcessedRichWords: richWords,
              respectFormatting: respectFormatting,
            );

            expect(pages, isNotEmpty);
            // Verify lossless word coverage across all pages
            expect(pages.first.startWordIndex, 0);
            expect(pages.last.endWordIndex, richWords.length);
            for (int i = 1; i < pages.length; i++) {
              expect(pages[i].startWordIndex, pages[i - 1].endWordIndex);
            }

            // Verify every column span fits strictly inside columnHeight (zero roll-off)
            for (final page in pages) {
              for (final span in page.columnSpans) {
                final h = ColumnTextLayout.measureSpanHeight(
                  span: span,
                  columnWidth: page.columnWidth,
                  textScaler: TextScaler.noScaling,
                );
                expect(h, lessThanOrEqualTo(page.columnHeight));
              }
            }
          }
        }
      }
    });
  });

  testWidgets('LibraryScreen smoke test renders title and Catalogue Server button',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LibraryProvider()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ],
        child: const MaterialApp(
          home: LibraryScreen(),
        ),
      ),
    );

    expect(find.text('Library'), findsOneWidget);
    expect(find.byTooltip('Browse Server Catalogue'), findsOneWidget);
  });
}
