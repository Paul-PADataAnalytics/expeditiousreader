import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../services/library_service.dart';

class LibraryProvider extends ChangeNotifier {
  final LibraryService _libraryService = LibraryService();
  List<Book> _books = [];
  bool _isLoading = false;
  String _searchQuery = '';
  List<String> _selectedCategories = [];

  List<Book> get books {
    var filtered = _books;
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((book) {
        final query = _searchQuery.toLowerCase();
        return book.title.toLowerCase().contains(query) ||
               book.author.toLowerCase().contains(query);
      }).toList();
    }
    
    // Apply category filter
    if (_selectedCategories.isNotEmpty) {
      filtered = filtered.where((book) {
        return book.categories.any((cat) => _selectedCategories.contains(cat));
      }).toList();
    }
    
    return filtered;
  }

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  /// Load library from disk
  Future<void> loadLibrary() async {
    _isLoading = true;
    notifyListeners();

    try {
      _books = await _libraryService.loadLibrary();
    } catch (e) {
      print('Error loading library: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Import a new book
  Future<void> importBook(String filePath) async {
    try {
      final book = await _libraryService.importBook(filePath);
      _books.add(book);
      await _saveLibrary();
      notifyListeners();
    } catch (e) {
      print('Error importing book: $e');
      rethrow;
    }
  }

  /// Import multiple books at once
  /// Returns a map with 'success', 'failed' counts and 'errors' list
  Future<Map<String, dynamic>> importBooks(List<String> filePaths) async {
    int successCount = 0;
    int failedCount = 0;
    List<String> errors = [];

    for (final filePath in filePaths) {
      try {
        final book = await _libraryService.importBook(filePath);
        _books.add(book);
        successCount++;
      } catch (e) {
        failedCount++;
        final fileName = filePath.split('/').last;
        errors.add('$fileName: ${e.toString()}');
        print('Error importing book $filePath: $e');
      }
    }

    if (successCount > 0) {
      await _saveLibrary();
      notifyListeners();
    }

    return {
      'success': successCount,
      'failed': failedCount,
      'errors': errors,
    };
  }

  /// Import multiple books from bytes (for web platform)
  /// fileDataList contains maps with 'bytes' and 'name' keys
  /// Returns a map with 'success', 'failed' counts, 'errors' list, and 'warnings' list
  Future<Map<String, dynamic>> importBooksFromBytes(List<Map<String, dynamic>> fileDataList) async {
    int successCount = 0;
    int failedCount = 0;
    List<String> errors = [];
    List<String> warnings = [];

    for (final fileData in fileDataList) {
      try {
        final bytes = fileData['bytes'] as List<int>;
        final fileName = fileData['name'] as String;
        
        final result = await _libraryService.importBookFromBytes(bytes, fileName);
        final book = result['book'] as Book;
        _books.add(book);
        successCount++;
        
        // Collect any warnings (e.g., cover images skipped)
        if (result.containsKey('warning')) {
          warnings.add('$fileName: ${result['warning']}');
        }
      } catch (e) {
        failedCount++;
        final fileName = fileData['name'] as String;
        errors.add('$fileName: ${e.toString()}');
        print('Error importing book $fileName: $e');
      }
    }

    if (successCount > 0) {
      await _saveLibrary();
      notifyListeners();
    }

    return {
      'success': successCount,
      'failed': failedCount,
      'errors': errors,
      'warnings': warnings,
    };
  }

  /// Delete books
  Future<void> deleteBooks(List<Book> booksToDelete) async {
    for (var book in booksToDelete) {
      await _libraryService.deleteBook(book);
      _books.remove(book);
    }
    await _saveLibrary();
    notifyListeners();
  }

  /// Update book
  Future<void> updateBook(Book updatedBook) async {
    final index = _books.indexWhere((b) => b.id == updatedBook.id);
    if (index != -1) {
      _books[index] = updatedBook;
      await _saveLibrary();
      notifyListeners();
    }
  }

  /// Update book progress
  Future<void> updateProgress(String bookId, {int? position, int? page}) async {
    final index = _books.indexWhere((b) => b.id == bookId);
    if (index != -1) {
      _books[index] = _books[index].copyWith(
        currentPosition: position ?? _books[index].currentPosition,
        currentPage: page ?? _books[index].currentPage,
      );
      await _saveLibrary();
      notifyListeners();
    }
  }

  /// Update cover image
  Future<void> updateCoverImage(Book book, String imagePath) async {
    final newCoverPath = await _libraryService.updateCoverImage(book, imagePath);
    if (newCoverPath != null) {
      await updateBook(book.copyWith(coverImagePath: newCoverPath));
    }
  }

  /// Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Set category filter
  void setCategoryFilter(List<String> categories) {
    _selectedCategories = categories;
    notifyListeners();
  }

  /// Save library to disk
  Future<void> _saveLibrary() async {
    await _libraryService.saveLibrary(_books);
  }

  /// Get book by ID
  Book? getBookById(String id) {
    try {
      return _books.firstWhere((book) => book.id == id);
    } catch (e) {
      return null;
    }
  }
}
