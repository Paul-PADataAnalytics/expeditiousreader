import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../services/catalogue_service.dart';
import '../services/library_service.dart';

class LibraryProvider extends ChangeNotifier {
  final LibraryService _libraryService = LibraryService();
  final CatalogueService _catalogueService = CatalogueService();
  List<Book> _books = [];
  bool _isLoading = false;
  bool _isCatalogueAvailable = false;
  String _catalogueServerUrl = CatalogueService.defaultHostUrl;
  String _searchQuery = '';
  String? _selectedBookCategory; // 'Fiction' or 'Non-Fiction'
  String? _selectedSubject;
  String? _selectedTopic;
  List<String> _selectedCategories = [];

  int get totalBookCount => _books.length;
  String? get selectedBookCategory => _selectedBookCategory;
  String? get selectedSubject => _selectedSubject;
  String? get selectedTopic => _selectedTopic;

  int countForCategory(String category) {
    return _books.where((b) => b.bookCategory == category).length;
  }

  List<MapEntry<String, int>> get availableSubjects {
    final counts = <String, int>{};
    for (final b in _books) {
      if (_selectedBookCategory != null && b.bookCategory != _selectedBookCategory) {
        continue;
      }
      final subj = b.bookSubject;
      if (subj.isNotEmpty) {
        counts[subj] = (counts[subj] ?? 0) + 1;
      }
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value != a.value ? b.value.compareTo(a.value) : a.key.compareTo(b.key));
    return entries;
  }

  List<MapEntry<String, int>> get availableTopics {
    final counts = <String, int>{};
    for (final b in _books) {
      if (_selectedBookCategory != null && b.bookCategory != _selectedBookCategory) {
        continue;
      }
      if (_selectedSubject != null && b.bookSubject != _selectedSubject) {
        continue;
      }
      for (final t in b.bookTopics) {
        counts[t] = (counts[t] ?? 0) + 1;
      }
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value != a.value ? b.value.compareTo(a.value) : a.key.compareTo(b.key));
    return entries;
  }

  List<Book> get books {
    var filtered = _books;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((book) {
        final query = _searchQuery.toLowerCase();
        return book.title.toLowerCase().contains(query) ||
            book.author.toLowerCase().contains(query) ||
            book.bookSubject.toLowerCase().contains(query) ||
            book.bookTopics.any((t) => t.toLowerCase().contains(query));
      }).toList();
    }

    // Apply Fiction / Non-Fiction filter
    if (_selectedBookCategory != null) {
      filtered = filtered.where((book) => book.bookCategory == _selectedBookCategory).toList();
    }

    // Apply Subject Shelf filter
    if (_selectedSubject != null) {
      filtered = filtered.where((book) => book.bookSubject == _selectedSubject).toList();
    }

    // Apply Topic filter
    if (_selectedTopic != null) {
      filtered = filtered.where((book) => book.bookTopics.contains(_selectedTopic)).toList();
    }

    // Apply legacy multi-category filter if set
    if (_selectedCategories.isNotEmpty) {
      filtered = filtered.where((book) {
        return book.categories.any((cat) => _selectedCategories.contains(cat));
      }).toList();
    }

    return filtered;
  }

  bool get isLoading => _isLoading;
  bool get isCatalogueAvailable => _isCatalogueAvailable;
  String get catalogueServerUrl => _catalogueServerUrl;
  String get searchQuery => _searchQuery;

  /// Load library from disk and probe optional Catalogue Server availability in the background
  Future<void> loadLibrary() async {
    _isLoading = true;
    notifyListeners();

    try {
      _books = await _libraryService.loadLibrary();
    } catch (e) {
      debugPrint('Error loading library: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    // Non-blocking check for optional Catalogue Server
    refreshCatalogueStatus();
  }

  /// Probe whether a Catalogue Server is reachable and update status
  Future<bool> refreshCatalogueStatus() async {
    try {
      _catalogueServerUrl = await _catalogueService.getServerUrl();
      _isCatalogueAvailable = await _catalogueService.checkAvailability();
    } catch (_) {
      _isCatalogueAvailable = false;
    }
    notifyListeners();
    return _isCatalogueAvailable;
  }

  /// Update the Catalogue Server URL and re-probe availability
  Future<bool> updateCatalogueServerUrl(String url) async {
    await _catalogueService.setServerUrl(url);
    return refreshCatalogueStatus();
  }

  /// Import a new book
  Future<void> importBook(String filePath) async {
    try {
      final book = await _libraryService.importBook(filePath);
      _books.add(book);
      await _saveLibrary();
      notifyListeners();
    } catch (e) {
      debugPrint('Error importing book: $e');
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
        debugPrint('Error importing book $filePath: $e');
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
        debugPrint('Error importing book $fileName: $e');
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

  /// Import a single book from the Catalogue Server and enrich it with Catalogue metadata
  Future<Book> importBookFromCatalogue(CatalogueItem item, Uint8List bytes) async {
    final existingIdx = _books.indexWhere(
      (b) => b.originalFilePath == 'catalogue:${item.id}' || b.title == item.title,
    );
    if (existingIdx != -1) {
      return _books[existingIdx];
    }

    final result = await _libraryService.importBookFromBytes(bytes, item.fileName);
    final parsedBook = result['book'] as Book;
    final combinedTags = <String>[
      item.category,
      item.subject,
      ...item.topics,
    ];
    final enriched = parsedBook.copyWith(
      title: item.title.isNotEmpty ? item.title : parsedBook.title,
      author: item.displayAuthor != 'Unknown Author' ? item.displayAuthor : parsedBook.author,
      isbn: item.isbn.isNotEmpty ? item.isbn : parsedBook.isbn,
      publicationDate: item.datecreated.isNotEmpty ? item.datecreated : parsedBook.publicationDate,
      genre: '${item.category} • ${item.subject}',
      categories: combinedTags,
      originalFilePath: 'catalogue:${item.id}',
      currentPosition: item.readingProgress > 0 ? item.readingProgress : parsedBook.currentPosition,
    );
    _books.add(enriched);
    await _saveLibrary();
    notifyListeners();
    return enriched;
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
      final newPos = position ?? _books[index].currentPosition;
      _books[index] = _books[index].copyWith(
        currentPosition: newPos,
        currentPage: page ?? _books[index].currentPage,
      );
      await _saveLibrary();
      notifyListeners();

      if (_isCatalogueAvailable) {
        final orig = _books[index].originalFilePath;
        if (orig.startsWith('catalogue:')) {
          final catId = int.tryParse(orig.substring('catalogue:'.length));
          if (catId != null) {
            await _catalogueService.syncReadingProgress(catId, newPos);
          }
        }
      }
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

  /// Filter by Fiction / Non-Fiction category
  void setBookCategoryFilter(String? category) {
    _selectedBookCategory = category;
    _selectedSubject = null;
    _selectedTopic = null;
    notifyListeners();
  }

  /// Filter by Subject Shelf
  void setSubjectFilter(String? subject) {
    _selectedSubject = subject;
    _selectedTopic = null;
    notifyListeners();
  }

  /// Filter by Topic
  void setTopicFilter(String? topic) {
    _selectedTopic = topic;
    notifyListeners();
  }

  /// Clear all library filters
  void clearFilters() {
    _selectedBookCategory = null;
    _selectedSubject = null;
    _selectedTopic = null;
    _selectedCategories = [];
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
