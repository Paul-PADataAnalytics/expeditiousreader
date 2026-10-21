import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:epubx/epubx.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:image/image.dart' as img;
import '../utils/text_processor.dart';

class BookParserService {
  /// Parse a book file and extract text and metadata
  Future<Map<String, dynamic>> parseBook(String filePath) async {
    final file = File(filePath);
    final extension = filePath.split('.').last.toLowerCase();

    switch (extension) {
      case 'epub':
        return await _parseEpub(file);
      case 'pdf':
        return await _parsePdf(file);
      case 'txt':
        return await _parseTxt(file);
      default:
        throw Exception('Unsupported file format: $extension');
    }
  }

  /// Parse a book from bytes (for web platform and Catalogue imports)
  Future<Map<String, dynamic>> parseBookFromBytes(Uint8List bytes, String fileName) async {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'epub':
        return await _parseEpubFromBytes(bytes, fileName);
      case 'pdf':
        return await _parsePdfFromBytes(bytes, fileName);
      case 'txt':
        return await _parseTxtFromBytes(bytes, fileName);
      default:
        throw Exception('Unsupported file format: $extension');
    }
  }

  List<EpubChapter> _flattenChapters(List<EpubChapter>? chapters) {
    final result = <EpubChapter>[];
    final seenFiles = <String>{};

    void visit(List<EpubChapter>? list) {
      if (list == null) return;
      for (final ch in list) {
        final htmlContent = (ch.HtmlContent ?? '').trim();
        final fileKey = (ch.ContentFileName ?? '').split('#').first.toLowerCase();
        if (htmlContent.isNotEmpty && (fileKey.isEmpty || !seenFiles.contains(fileKey))) {
          if (fileKey.isNotEmpty) {
            seenFiles.add(fileKey);
          }
          result.add(ch);
        }
        if (ch.SubChapters != null && ch.SubChapters!.isNotEmpty) {
          visit(ch.SubChapters);
        }
      }
    }

    visit(chapters);
    return result;
  }

  Map<String, dynamic> _extractEpubBodyAndChapters(EpubBook book) {
    final flatChapters = _flattenChapters(book.Chapters);
    final bodyChapters = <String>[];
    final allChaptersFallback = <String>[];

    for (final chapter in flatChapters) {
      String chapterText = _extractTextFromHtml(chapter.HtmlContent ?? '');
      chapterText = TextProcessor.cleanText(chapterText);
      if (chapterText.isEmpty) continue;

      final chTitle = (chapter.Title ?? '').trim();
      if (chTitle.isNotEmpty) {
        final firstLine = chapterText.split('\n').first.replaceAll(RegExp(r'^#+\s*'), '').trim();
        if (firstLine.toLowerCase() != chTitle.toLowerCase()) {
          chapterText = '# $chTitle\n\n$chapterText';
        }
      }

      allChaptersFallback.add(chapterText);

      // Filter out non-book front-matter and back-matter (Copyright, Title Page, TOC, Credits, etc.)
      final isBoilerplate = TextProcessor.isFrontOrBackMatterSection(
        title: chapter.Title,
        fileName: chapter.ContentFileName,
        text: chapterText,
      );
      if (!isBoilerplate) {
        bodyChapters.add(chapterText);
      }
    }

    final chosenChapters = bodyChapters.isNotEmpty ? bodyChapters : allChaptersFallback;
    final fullText = TextProcessor.cleanText(chosenChapters.join('\n\n'));
    final chapterPositions = TextProcessor.calculateChapterWordPositions(chosenChapters);

    return {
      'text': fullText,
      'chapterPositions': chapterPositions,
    };
  }

  String? _extractEpubCoverBase64(EpubBook book) {
    try {
      List<int>? coverBytes;

      if (book.CoverImage != null) {
        if (book.CoverImage is List<int>) {
          coverBytes = book.CoverImage as List<int>;
        } else if (book.CoverImage is img.Image) {
          coverBytes = img.encodePng(book.CoverImage as img.Image);
        }
      }

      if (coverBytes == null && book.Content?.Images != null) {
        final images = book.Content!.Images!;
        const coverPatterns = [
          'cover',
          'Cover',
          'COVER',
          'cover.jpg',
          'cover.png',
          'cover.jpeg',
          'Cover.jpg',
          'Cover.png',
          'titlepage',
        ];

        for (final pattern in coverPatterns) {
          final coverImage = images[pattern];
          if (coverImage != null && coverImage.Content != null) {
            coverBytes = coverImage.Content;
            break;
          }
        }

        if (coverBytes == null) {
          for (final entry in images.entries) {
            if (entry.key.toLowerCase().contains('cover') ||
                entry.value.FileName?.toLowerCase().contains('cover') == true) {
              if (entry.value.Content != null) {
                coverBytes = entry.value.Content;
                break;
              }
            }
          }
        }

        if (coverBytes == null && images.isNotEmpty) {
          final firstImage = images.values.first;
          if (firstImage.Content != null) {
            coverBytes = firstImage.Content;
          }
        }
      }

      if (coverBytes != null && coverBytes.isNotEmpty) {
        return base64Encode(coverBytes);
      }
    } catch (e) {
      debugPrint('Failed to extract cover image: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>> _parseEpub(File file) async {
    final bytes = await file.readAsBytes();
    final book = await EpubReader.readBook(bytes);
    final extracted = _extractEpubBodyAndChapters(book);

    return {
      'text': extracted['text'],
      'title': book.Title ?? 'Unknown',
      'author': book.Author ?? 'Unknown',
      'coverImageData': _extractEpubCoverBase64(book),
      'chapterPositions': extracted['chapterPositions'],
      'format': 'epub',
    };
  }

  Future<Map<String, dynamic>> _parseEpubFromBytes(Uint8List bytes, String fileName) async {
    final book = await EpubReader.readBook(bytes);
    final extracted = _extractEpubBodyAndChapters(book);

    return {
      'text': extracted['text'],
      'title': book.Title ?? fileName.replaceAll('.epub', '').replaceAll('_', ' '),
      'author': book.Author ?? 'Unknown',
      'coverImageData': _extractEpubCoverBase64(book),
      'chapterPositions': extracted['chapterPositions'],
      'format': 'epub',
    };
  }

  Future<Map<String, dynamic>> _parsePdf(File file) async {
    final bytes = await file.readAsBytes();
    return _parsePdfFromBytes(bytes, file.path.split('/').last);
  }

  Future<Map<String, dynamic>> _parsePdfFromBytes(Uint8List bytes, String fileName) async {
    final PdfDocument document = PdfDocument(inputBytes: bytes);

    final pagesText = <String>[];
    final PdfTextExtractor extractor = PdfTextExtractor(document);
    for (int i = 0; i < document.pages.count; i++) {
      final String pageText = extractor.extractText(startPageIndex: i, endPageIndex: i).trim();
      if (pageText.isEmpty) continue;
      // Skip early copyright/colophon pages in PDFs (first 5 pages)
      if (i < 5 && TextProcessor.isFrontOrBackMatterSection(text: pageText)) {
        continue;
      }
      pagesText.add(pageText);
    }

    document.dispose();

    final fullText = TextProcessor.cleanText(pagesText.join('\n\n'));
    final title = fileName.replaceAll('.pdf', '').replaceAll('_', ' ');
    final chapterPositions = TextProcessor.detectChapters(fullText);

    return {
      'text': fullText,
      'title': title,
      'author': 'Unknown',
      'coverImageData': null,
      'chapterPositions': chapterPositions,
      'format': 'pdf',
    };
  }

  Future<Map<String, dynamic>> _parseTxt(File file) async {
    final bytes = await file.readAsBytes();
    return _parseTxtFromBytes(bytes, file.path.split('/').last);
  }

  Future<Map<String, dynamic>> _parseTxtFromBytes(Uint8List bytes, String fileName) async {
    final rawText = utf8.decode(bytes, allowMalformed: true);
    final cleaned = TextProcessor.cleanText(rawText);
    final title = fileName.replaceAll('.txt', '').replaceAll('_', ' ');
    final chapterPositions = TextProcessor.detectChapters(cleaned);

    return {
      'text': cleaned,
      'title': title,
      'author': 'Unknown',
      'coverImageData': null,
      'chapterPositions': chapterPositions,
      'format': 'txt',
    };
  }

  String _extractTextFromHtml(String html) {
    String text = html;

    // Strip script, style, and head blocks completely
    text = text.replaceAll(
      RegExp(r'<\s*(script|style|head)[^>]*>.*?<\s*/\s*\1\s*>',
          caseSensitive: false, dotAll: true),
      '',
    );

    // Normalize newlines inside HTML source before converting block tags
    text = text.replaceAll(RegExp(r'\r?\n'), ' ');

    // Preserve heading levels (H1, H2, H3+) with markdown markers and paragraph breaks
    text = text.replaceAllMapped(
      RegExp(r'<\s*h1[^>]*>(.*?)<\s*/\s*h1\s*>', caseSensitive: false, dotAll: true),
      (m) => '\n\n# ${_stripInlineTags(m.group(1) ?? '')}\n\n',
    );
    text = text.replaceAllMapped(
      RegExp(r'<\s*h2[^>]*>(.*?)<\s*/\s*h2\s*>', caseSensitive: false, dotAll: true),
      (m) => '\n\n## ${_stripInlineTags(m.group(1) ?? '')}\n\n',
    );
    text = text.replaceAllMapped(
      RegExp(r'<\s*h[3-6][^>]*>(.*?)<\s*/\s*h[3-6]\s*>', caseSensitive: false, dotAll: true),
      (m) => '\n\n### ${_stripInlineTags(m.group(1) ?? '')}\n\n',
    );

    // Convert line breaks and list items to single carriage returns
    text = text.replaceAll(RegExp(r'<\s*br\s*/?\s*>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'<\s*li[^>]*>', caseSensitive: false), '\n• ');
    text = text.replaceAll(RegExp(r'<\s*/\s*li\s*>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'<\s*/\s*tr\s*>', caseSensitive: false), '\n');

    // Convert block-level elements to paragraph breaks (\n\n)
    text = text.replaceAll(
      RegExp(r'<\s*/\s*(p|div|section|article|blockquote|pre|ul|ol|table)\s*>',
          caseSensitive: false),
      '\n\n',
    );

    // Remove all remaining HTML tags
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');

    // Decode HTML entities
    text = _decodeHtmlEntities(text);

    return text.trim();
  }

  String _stripInlineTags(String fragment) {
    return _decodeHtmlEntities(fragment.replaceAll(RegExp(r'<[^>]*>'), ''))
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Comprehensive HTML entity decoder
  String _decodeHtmlEntities(String text) {
    text = text.replaceAllMapped(
      RegExp(r'&#x([0-9a-fA-F]+);'),
      (match) {
        try {
          final code = int.parse(match.group(1)!, radix: 16);
          if (code == 0x00A0 ||
              code == 0x2009 ||
              code == 0x200A ||
              code == 0x2002 ||
              code == 0x2003 ||
              code == 0x2004 ||
              code == 0x2005 ||
              code == 0x2006 ||
              code == 0x2007 ||
              code == 0x2008 ||
              code == 0x202F ||
              code == 0x205F) {
            return ' ';
          }
          if (code == 0x200B || code == 0x200C || code == 0x200D || code == 0x00AD) {
            return '';
          }
          return String.fromCharCode(code);
        } catch (e) {
          return match.group(0)!;
        }
      },
    );

    text = text.replaceAllMapped(
      RegExp(r'&#(\d+);'),
      (match) {
        try {
          final code = int.parse(match.group(1)!);
          if (code == 160 ||
              code == 8201 ||
              code == 8202 ||
              code == 8194 ||
              code == 8195 ||
              code == 8196 ||
              code == 8197 ||
              code == 8198 ||
              code == 8199 ||
              code == 8200 ||
              code == 8239 ||
              code == 8287) {
            return ' ';
          }
          if (code == 8203 || code == 8204 || code == 8205 || code == 173) {
            return '';
          }
          return String.fromCharCode(code);
        } catch (e) {
          return match.group(0)!;
        }
      },
    );

    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&ensp;', ' ')
        .replaceAll('&emsp;', ' ')
        .replaceAll('&thinsp;', ' ')
        .replaceAll('&zwnj;', '')
        .replaceAll('&zwj;', '')
        .replaceAll('&shy;', '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&mdash;', '—')
        .replaceAll('&ndash;', '–')
        .replaceAll('&hellip;', '…')
        .replaceAll('&lsquo;', '‘')
        .replaceAll('&rsquo;', '’')
        .replaceAll('&ldquo;', '“')
        .replaceAll('&rdquo;', '”')
        .replaceAll('&laquo;', '«')
        .replaceAll('&raquo;', '»')
        .replaceAll('&bull;', '•')
        .replaceAll('&middot;', '·')
        .replaceAll('&copy;', '©')
        .replaceAll('&reg;', '®')
        .replaceAll('&trade;', '™')
        .replaceAll('&deg;', '°')
        .replaceAll('&plusmn;', '±')
        .replaceAll('&frac14;', '¼')
        .replaceAll('&frac12;', '½')
        .replaceAll('&frac34;', '¾');

    return text;
  }
}
