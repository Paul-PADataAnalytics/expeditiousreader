import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
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

  /// Parse a book from bytes (for web platform)
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

  Future<Map<String, dynamic>> _parseEpub(File file) async {
    final bytes = await file.readAsBytes();
    final book = await EpubReader.readBook(bytes);

    String fullText = '';
    final List<String> chapters = [];

    // Extract text from all chapters
    for (var chapter in book.Chapters ?? []) {
      String chapterText = _extractTextFromHtml(chapter.HtmlContent ?? '');
      if (chapterText.isNotEmpty) {
        chapters.add(chapterText);
        fullText += chapterText + '\n\n';
      }
    }

    // Extract metadata
    String title = book.Title ?? 'Unknown';
    String author = book.Author ?? 'Unknown';
    
    // Try to find cover image
    String? coverImageData;
    try {
      // Try multiple methods to extract cover image
      List<int>? coverBytes;
      
      // Method 1: Try CoverImage property (if available as bytes)
      if (book.CoverImage != null) {
        if (book.CoverImage is List<int>) {
          coverBytes = book.CoverImage as List<int>;
        } else if (book.CoverImage is img.Image) {
          final pngBytes = img.encodePng(book.CoverImage as img.Image);
          coverBytes = pngBytes;
        }
      }
      
      // Method 2: Search in Content.Images for cover
      if (coverBytes == null && book.Content?.Images != null) {
        final images = book.Content!.Images!;
        
        // Look for common cover image names
        final coverPatterns = ['cover', 'Cover', 'COVER', 'cover.jpg', 'cover.png', 
                               'cover.jpeg', 'Cover.jpg', 'Cover.png', 'titlepage'];
        
        for (var pattern in coverPatterns) {
          var coverImage = images[pattern];
          if (coverImage != null && coverImage.Content != null) {
            coverBytes = coverImage.Content;
            break;
          }
        }
        
        // If still not found, try the first image
        if (coverBytes == null && images.isNotEmpty) {
          final firstImage = images.values.first;
          if (firstImage.Content != null) {
            coverBytes = firstImage.Content;
          }
        }
      }
      
      // Method 3: Check metadata for cover reference
      if (coverBytes == null && book.Content?.Images != null) {
        // Some EPUBs reference cover in metadata
        final meta = book.Schema?.Package?.Metadata;
        if (meta != null) {
          // Try to find cover reference in metadata
          final images = book.Content!.Images!;
          for (var entry in images.entries) {
            if (entry.key.toLowerCase().contains('cover') || 
                entry.value.FileName?.toLowerCase().contains('cover') == true) {
              if (entry.value.Content != null) {
                coverBytes = entry.value.Content;
                break;
              }
            }
          }
        }
      }
      
      // Encode cover bytes if found
      if (coverBytes != null && coverBytes.isNotEmpty) {
        coverImageData = base64Encode(coverBytes);
      }
    } catch (e) {
      print('Failed to extract cover image: $e');
    }

    // Calculate chapter positions
    List<int> chapterPositions = TextProcessor.calculateChapterPositions(fullText, chapters);

    return {
      'text': TextProcessor.cleanText(fullText),
      'title': title,
      'author': author,
      'coverImageData': coverImageData,
      'chapterPositions': chapterPositions,
      'format': 'epub',
    };
  }

  Future<Map<String, dynamic>> _parsePdf(File file) async {
    final bytes = await file.readAsBytes();
    final PdfDocument document = PdfDocument(inputBytes: bytes);

    String fullText = '';
    
    // Extract text from all pages
    for (int i = 0; i < document.pages.count; i++) {
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      final String pageText = extractor.extractText(startPageIndex: i, endPageIndex: i);
      fullText += pageText + '\n';
    }

    document.dispose();

    // Try to extract title from filename
    String filename = file.path.split('/').last;
    String title = filename.replaceAll('.pdf', '').replaceAll('_', ' ');

    // Calculate chapter positions (simple heuristic)
    List<int> chapterPositions = TextProcessor.detectChapters(fullText);

    return {
      'text': TextProcessor.cleanText(fullText),
      'title': title,
      'author': 'Unknown',
      'coverImageData': null,
      'chapterPositions': chapterPositions,
      'format': 'pdf',
    };
  }

  Future<Map<String, dynamic>> _parseTxt(File file) async {
    String fullText = await file.readAsString();

    // Try to extract title from filename
    String filename = file.path.split('/').last;
    String title = filename.replaceAll('.txt', '').replaceAll('_', ' ');

    // Calculate chapter positions
    List<int> chapterPositions = TextProcessor.detectChapters(fullText);

    return {
      'text': TextProcessor.cleanText(fullText),
      'title': title,
      'author': 'Unknown',
      'coverImageData': null,
      'chapterPositions': chapterPositions,
      'format': 'txt',
    };
  }

  String _extractTextFromHtml(String html) {
    // Convert common HTML elements to preserve structure
    String text = html;
    
    // Convert block-level elements to line breaks
    text = text.replaceAll(RegExp(r'<\s*br\s*/?\s*>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'<\s*/\s*p\s*>', caseSensitive: false), '\n\n');
    text = text.replaceAll(RegExp(r'<\s*/\s*div\s*>', caseSensitive: false), '\n\n');
    text = text.replaceAll(RegExp(r'<\s*/\s*h[1-6]\s*>', caseSensitive: false), '\n\n');
    text = text.replaceAll(RegExp(r'<\s*/\s*li\s*>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'<\s*/\s*tr\s*>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'<\s*/\s*blockquote\s*>', caseSensitive: false), '\n\n');
    
    // Remove all other HTML tags
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Decode HTML entities - do this BEFORE numeric entities to avoid double-decoding
    text = _decodeHtmlEntities(text);
    
    return text.trim();
  }

  /// Comprehensive HTML entity decoder
  String _decodeHtmlEntities(String text) {
    // First, decode hexadecimal HTML entities (e.g., &#x2009; &#xA0;)
    text = text.replaceAllMapped(
      RegExp(r'&#x([0-9a-fA-F]+);'),
      (match) {
        try {
          final code = int.parse(match.group(1)!, radix: 16);
          // Convert common whitespace entities to regular spaces
          if (code == 0x00A0 || code == 0x2009 || code == 0x200A || 
              code == 0x2002 || code == 0x2003 || code == 0x2004 ||
              code == 0x2005 || code == 0x2006 || code == 0x2007 ||
              code == 0x2008 || code == 0x202F || code == 0x205F) {
            return ' '; // Convert various space characters to regular space
          }
          // Convert zero-width spaces and soft hyphens to empty string
          if (code == 0x200B || code == 0x200C || code == 0x200D || code == 0x00AD) {
            return '';
          }
          return String.fromCharCode(code);
        } catch (e) {
          return match.group(0)!;
        }
      },
    );
    
    // Decode decimal numeric entities (e.g., &#8201; &#160;)
    text = text.replaceAllMapped(
      RegExp(r'&#(\d+);'),
      (match) {
        try {
          final code = int.parse(match.group(1)!);
          // Convert common whitespace entities to regular spaces
          if (code == 160 || code == 8201 || code == 8202 || 
              code == 8194 || code == 8195 || code == 8196 ||
              code == 8197 || code == 8198 || code == 8199 ||
              code == 8200 || code == 8239 || code == 8287) {
            return ' '; // Convert various space characters to regular space
          }
          // Convert zero-width spaces and soft hyphens to empty string
          if (code == 8203 || code == 8204 || code == 8205 || code == 173) {
            return '';
          }
          return String.fromCharCode(code);
        } catch (e) {
          return match.group(0)!;
        }
      },
    );
    
    // Decode named HTML entities
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
        .replaceAll('&lsquo;', ''')
        .replaceAll('&rsquo;', ''')
        .replaceAll('&ldquo;', '"')
        .replaceAll('&rdquo;', '"')
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

  // Byte-based parsing methods for web platform

  Future<Map<String, dynamic>> _parseEpubFromBytes(Uint8List bytes, String fileName) async {
    final book = await EpubReader.readBook(bytes);

    String fullText = '';
    final List<String> chapters = [];

    // Extract text from all chapters
    for (var chapter in book.Chapters ?? []) {
      String chapterText = _extractTextFromHtml(chapter.HtmlContent ?? '');
      if (chapterText.isNotEmpty) {
        chapters.add(chapterText);
        fullText += chapterText + '\n\n';
      }
    }

    // Extract metadata
    String title = book.Title ?? fileName.replaceAll('.epub', '').replaceAll('_', ' ');
    String author = book.Author ?? 'Unknown';
    
    // Try to find cover image
    String? coverImageData;
    try {
      List<int>? coverBytes;
      
      if (book.CoverImage != null) {
        if (book.CoverImage is List<int>) {
          coverBytes = book.CoverImage as List<int>;
        } else if (book.CoverImage is img.Image) {
          final pngBytes = img.encodePng(book.CoverImage as img.Image);
          coverBytes = pngBytes;
        }
      }
      
      if (coverBytes == null && book.Content?.Images != null) {
        final images = book.Content!.Images!;
        final coverPatterns = ['cover', 'Cover', 'COVER', 'cover.jpg', 'cover.png', 
                               'cover.jpeg', 'Cover.jpg', 'Cover.png', 'titlepage'];
        
        for (var pattern in coverPatterns) {
          var coverImage = images[pattern];
          if (coverImage != null && coverImage.Content != null) {
            coverBytes = coverImage.Content;
            break;
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
        coverImageData = base64Encode(coverBytes);
      }
    } catch (e) {
      print('Failed to extract cover image: $e');
    }

    List<int> chapterPositions = TextProcessor.calculateChapterPositions(fullText, chapters);

    return {
      'text': TextProcessor.cleanText(fullText),
      'title': title,
      'author': author,
      'coverImageData': coverImageData,
      'chapterPositions': chapterPositions,
      'format': 'epub',
    };
  }

  Future<Map<String, dynamic>> _parsePdfFromBytes(Uint8List bytes, String fileName) async {
    final PdfDocument document = PdfDocument(inputBytes: bytes);

    String fullText = '';
    
    // Extract text from all pages
    for (int i = 0; i < document.pages.count; i++) {
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      final String pageText = extractor.extractText(startPageIndex: i, endPageIndex: i);
      fullText += pageText + '\n';
    }

    document.dispose();

    String title = fileName.replaceAll('.pdf', '').replaceAll('_', ' ');
    List<int> chapterPositions = TextProcessor.detectChapters(fullText);

    return {
      'text': TextProcessor.cleanText(fullText),
      'title': title,
      'author': 'Unknown',
      'coverImageData': null,
      'chapterPositions': chapterPositions,
      'format': 'pdf',
    };
  }

  Future<Map<String, dynamic>> _parseTxtFromBytes(Uint8List bytes, String fileName) async {
    String fullText = utf8.decode(bytes);

    String title = fileName.replaceAll('.txt', '').replaceAll('_', ' ');
    List<int> chapterPositions = TextProcessor.detectChapters(fullText);

    return {
      'text': TextProcessor.cleanText(fullText),
      'title': title,
      'author': 'Unknown',
      'coverImageData': null,
      'chapterPositions': chapterPositions,
      'format': 'txt',
    };
  }
}
