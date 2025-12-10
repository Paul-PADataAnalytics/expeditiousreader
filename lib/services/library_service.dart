import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/book.dart';
import 'book_parser_service.dart';
import '../utils/text_processor.dart';

class LibraryService {
  final BookParserService _parser = BookParserService();
  final Uuid _uuid = const Uuid();
  
  static const String _libraryFileName = 'library.json';
  static const String _booksDir = 'books';
  static const String _coversDir = 'covers';
  static const String _webBookTextPrefix = 'book_text_';
  static const String _webBookCoverPrefix = 'book_cover_';

  /// Get application documents directory (not used on web)
  Future<Directory> _getAppDirectory() async {
    if (kIsWeb) {
      throw UnsupportedError('File system not available on web');
    }
    final appDir = await getApplicationDocumentsDirectory();
    final libDir = Directory('${appDir.path}/expeditiousreader');
    if (!await libDir.exists()) {
      await libDir.create(recursive: true);
    }
    return libDir;
  }

  /// Get books directory (not used on web)
  Future<Directory> _getBooksDirectory() async {
    if (kIsWeb) {
      throw UnsupportedError('File system not available on web');
    }
    final appDir = await _getAppDirectory();
    final booksDir = Directory('${appDir.path}/$_booksDir');
    if (!await booksDir.exists()) {
      await booksDir.create(recursive: true);
    }
    return booksDir;
  }

  /// Get covers directory (not used on web)
  Future<Directory> _getCoversDirectory() async {
    if (kIsWeb) {
      throw UnsupportedError('File system not available on web');
    }
    final appDir = await _getAppDirectory();
    final coversDir = Directory('${appDir.path}/$_coversDir');
    if (!await coversDir.exists()) {
      await coversDir.create(recursive: true);
    }
    return coversDir;
  }

  /// Load all books from library
  Future<List<Book>> loadLibrary() async {
    try {
      if (kIsWeb) {
        // On web, load from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final jsonString = prefs.getString(_libraryFileName);
        
        if (jsonString == null || jsonString.isEmpty) {
          return [];
        }
        
        final List<dynamic> jsonList = json.decode(jsonString);
        return jsonList.map((json) => Book.fromJson(json)).toList();
      } else {
        // On desktop/mobile, load from file
        final appDir = await _getAppDirectory();
        final libraryFile = File('${appDir.path}/$_libraryFileName');
        
        if (!await libraryFile.exists()) {
          return [];
        }

        final jsonString = await libraryFile.readAsString();
        final List<dynamic> jsonList = json.decode(jsonString);
        
        return jsonList.map((json) => Book.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error loading library: $e');
      return [];
    }
  }

  /// Save library to disk
  Future<void> saveLibrary(List<Book> books) async {
    try {
      final jsonList = books.map((book) => book.toJson()).toList();
      final jsonString = json.encode(jsonList);
      
      if (kIsWeb) {
        // On web, save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_libraryFileName, jsonString);
      } else {
        // On desktop/mobile, save to file
        final appDir = await _getAppDirectory();
        final libraryFile = File('${appDir.path}/$_libraryFileName');
        await libraryFile.writeAsString(jsonString);
      }
    } catch (e) {
      print('Error saving library: $e');
      throw Exception('Failed to save library');
    }
  }

  /// Import a book file into the library
  Future<Book> importBook(String filePath) async {
    try {
      // Parse the book
      final bookData = await _parser.parseBook(filePath);
      
      final bookId = _uuid.v4();
      final booksDir = await _getBooksDirectory();
      
      // Save text file
      final textFile = File('${booksDir.path}/$bookId.txt');
      await textFile.writeAsString(bookData['text']);
      
      // Save cover image if available
      String? coverPath;
      if (bookData['coverImageData'] != null) {
        final coversDir = await _getCoversDirectory();
        coverPath = '${coversDir.path}/$bookId.png';
        final coverFile = File(coverPath);
        final imageBytes = base64Decode(bookData['coverImageData']);
        await coverFile.writeAsBytes(imageBytes);
      }
      
      // Count words and pages
      final text = bookData['text'] as String;
      final wordCount = TextProcessor.countWords(text);
      final pageCount = (wordCount / 300).ceil(); // Assuming ~300 words per page
      
      // Create Book object
      final book = Book(
        id: bookId,
        title: bookData['title'],
        author: bookData['author'],
        wordCount: wordCount,
        pageCount: pageCount,
        chapterPositions: List<int>.from(bookData['chapterPositions']),
        coverImagePath: coverPath,
        textFilePath: textFile.path,
        originalFilePath: filePath,
        fileFormat: bookData['format'],
        dateAdded: DateTime.now(),
        currentPosition: TextProcessor.findStartPosition(text),
      );
      
      return book;
    } catch (e) {
      print('Error importing book: $e');
      throw Exception('Failed to import book: $e');
    }
  }

  /// Import a book from bytes (for web platform)
  /// Returns a map with 'book' and optional 'warning' message
  Future<Map<String, dynamic>> importBookFromBytes(List<int> fileBytes, String fileName) async {
    try {
      // Parse the book from bytes
      final bookData = await _parser.parseBookFromBytes(Uint8List.fromList(fileBytes), fileName);
      
      final bookId = _uuid.v4();
      final text = bookData['text'] as String;
      
      String textFilePath;
      String? coverPath;
      String? warning;
      
      if (kIsWeb) {
        // On web, store text and cover in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        
        // Store book text
        textFilePath = '$_webBookTextPrefix$bookId';
        await prefs.setString(textFilePath, text);
        
        // Store cover image if available (with quota handling)
        if (bookData['coverImageData'] != null) {
          coverPath = '$_webBookCoverPrefix$bookId';
          final coverData = bookData['coverImageData'] as String;
          
          // Check if cover data is too large (base64 strings can be huge)
          // Estimate: base64 is ~1.33x original size, keep under 500KB
          if (coverData.length > 500000) {
            // Skip cover image if too large to avoid quota errors
            coverPath = null;
            warning = 'Cover image skipped (too large for web storage)';
          } else {
            try {
              await prefs.setString(coverPath, coverData);
            } catch (e) {
              // If quota exceeded, skip cover and continue
              if (e.toString().contains('QuotaExceededError') || 
                  e.toString().contains('quota')) {
                coverPath = null;
                warning = 'Cover image skipped (storage quota exceeded)';
              } else {
                rethrow;
              }
            }
          }
        }
      } else {
        // On desktop/mobile, use file system
        final booksDir = await _getBooksDirectory();
        textFilePath = '${booksDir.path}/$bookId.txt';
        final textFile = File(textFilePath);
        await textFile.writeAsString(text);
        
        if (bookData['coverImageData'] != null) {
          final coversDir = await _getCoversDirectory();
          coverPath = '${coversDir.path}/$bookId.png';
          final coverFile = File(coverPath);
          final imageBytes = base64Decode(bookData['coverImageData']);
          await coverFile.writeAsBytes(imageBytes);
        }
      }
      
      // Count words and pages
      final wordCount = TextProcessor.countWords(text);
      final pageCount = (wordCount / 300).ceil(); // Assuming ~300 words per page
      
      // Create Book object
      final book = Book(
        id: bookId,
        title: bookData['title'],
        author: bookData['author'],
        wordCount: wordCount,
        pageCount: pageCount,
        chapterPositions: List<int>.from(bookData['chapterPositions']),
        coverImagePath: coverPath,
        textFilePath: textFilePath,
        originalFilePath: fileName, // Store the filename instead of path on web
        fileFormat: bookData['format'],
        dateAdded: DateTime.now(),
        currentPosition: TextProcessor.findStartPosition(text),
      );
      
      return {
        'book': book,
        if (warning != null) 'warning': warning,
      };
    } catch (e) {
      print('Error importing book from bytes: $e');
      throw Exception('Failed to import book: $e');
    }
  }

  /// Delete a book from the library
  Future<void> deleteBook(Book book) async {
    try {
      if (kIsWeb) {
        // On web, delete from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(book.textFilePath);
        if (book.coverImagePath != null) {
          await prefs.remove(book.coverImagePath!);
        }
      } else {
        // On desktop/mobile, delete files
        // Delete text file
        final textFile = File(book.textFilePath);
        if (await textFile.exists()) {
          await textFile.delete();
        }
        
        // Delete cover image
        if (book.coverImagePath != null) {
          final coverFile = File(book.coverImagePath!);
          if (await coverFile.exists()) {
            await coverFile.delete();
          }
        }
      }
    } catch (e) {
      print('Error deleting book files: $e');
    }
  }

  /// Read text content of a book
  Future<String> readBookText(Book book) async {
    try {
      if (kIsWeb) {
        // On web, read from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final text = prefs.getString(book.textFilePath);
        if (text == null) {
          throw Exception('Book text not found in storage');
        }
        return text;
      } else {
        // On desktop/mobile, read from file
        final textFile = File(book.textFilePath);
        return await textFile.readAsString();
      }
    } catch (e) {
      print('Error reading book text: $e');
      throw Exception('Failed to read book text');
    }
  }

  /// Update book cover image
  Future<String?> updateCoverImage(Book book, String imagePath) async {
    try {
      if (kIsWeb) {
        // On web, imagePath is actually the key in SharedPreferences or base64 data
        // For now, web cover update is not supported via file picker
        // This would need to be handled differently with bytes
        print('Cover image update not yet supported on web');
        return null;
      } else {
        // On desktop/mobile, use file system
        final coversDir = await _getCoversDirectory();
        final newCoverPath = '${coversDir.path}/${book.id}.png';
        
        // Delete old cover if exists
        if (book.coverImagePath != null) {
          final oldCover = File(book.coverImagePath!);
          if (await oldCover.exists()) {
            await oldCover.delete();
          }
        }
        
        // Copy new cover
        final sourceFile = File(imagePath);
        await sourceFile.copy(newCoverPath);
        
        return newCoverPath;
      }
    } catch (e) {
      print('Error updating cover image: $e');
      return null;
    }
  }
}
