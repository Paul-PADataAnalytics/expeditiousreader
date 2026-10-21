import 'package:json_annotation/json_annotation.dart';

part 'book.g.dart';

@JsonSerializable()
class Book {
  final String id;
  final String title;
  final String author;
  final String? publicationDate;
  final String? isbn;
  final String? genre;
  final int pageCount;
  final int wordCount;
  final List<int> chapterPositions;
  final String? coverImagePath;
  final String textFilePath;
  final String originalFilePath;
  final String fileFormat; // pdf, epub, txt
  final DateTime dateAdded;
  final int currentPosition; // Current word position for speed reading
  final int currentPage; // Current page for traditional reading
  final List<String> categories;

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.publicationDate,
    this.isbn,
    this.genre,
    required this.pageCount,
    required this.wordCount,
    required this.chapterPositions,
    this.coverImagePath,
    required this.textFilePath,
    required this.originalFilePath,
    required this.fileFormat,
    required this.dateAdded,
    this.currentPosition = 0,
    this.currentPage = 0,
    this.categories = const [],
  });

  factory Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);
  Map<String, dynamic> toJson() => _$BookToJson(this);

  /// High-level library category: 'Fiction' or 'Non-Fiction'.
  String get bookCategory {
    if (categories.contains('Fiction')) return 'Fiction';
    if (categories.contains('Non-Fiction')) return 'Non-Fiction';
    final g = (genre ?? '').trim();
    if (g.startsWith('Fiction')) return 'Fiction';
    if (g.startsWith('Non-Fiction')) return 'Non-Fiction';
    return _inferCategoryAndSubject(title: title, genre: g, tags: categories).$1;
  }

  /// Curated library subject shelf (e.g. 'Linux, Cloud & DevOps', 'Science Fiction & Fantasy').
  String get bookSubject {
    final g = (genre ?? '').trim();
    if (g.contains('•')) {
      final parts = g.split('•').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      if (parts.length >= 2) {
        return parts[1];
      }
    }
    if (categories.length >= 2 &&
        (categories[0] == 'Fiction' || categories[0] == 'Non-Fiction')) {
      return categories[1];
    }
    if (g.isNotEmpty && g != 'Unknown') {
      return g;
    }
    return _inferCategoryAndSubject(title: title, genre: g, tags: categories).$2;
  }

  /// Topic tags for this book (excluding the top-level category and subject shelf).
  List<String> get bookTopics {
    final subj = bookSubject.toLowerCase();
    return categories
        .where((c) {
          final cl = c.trim().toLowerCase();
          return cl.isNotEmpty &&
              cl != 'fiction' &&
              cl != 'non-fiction' &&
              cl != 'unknown' &&
              cl != subj;
        })
        .toList();
  }

  static (String, String) _inferCategoryAndSubject({
    required String title,
    required String genre,
    required List<String> tags,
  }) {
    final hay = '$title $genre ${tags.join(' ')}'.toLowerCase();
    if (hay.contains('comic') || hay.contains('manga') || hay.contains('graphic novel')) {
      return ('Fiction', 'Comics, Manga & Graphic Novels');
    }
    if (hay.contains('sci-fi') ||
        hay.contains('science fiction') ||
        hay.contains('fantasy') ||
        hay.contains('murderbot') ||
        hay.contains('novel')) {
      return ('Fiction', 'Science Fiction & Fantasy');
    }
    if (hay.contains('fiction') && !hay.contains('non-fiction') && !hay.contains('nonfiction')) {
      return ('Fiction', 'Fiction & Literature');
    }
    if (hay.contains('linux') ||
        hay.contains('devops') ||
        hay.contains('cloud') ||
        hay.contains('unix') ||
        hay.contains('docker') ||
        hay.contains('kubernetes')) {
      return ('Non-Fiction', 'Linux, Cloud & DevOps');
    }
    if (hay.contains('machine learning') ||
        hay.contains('data science') ||
        hay.contains('artificial intelligence') ||
        hay.contains('deep learning') ||
        hay.contains('neural')) {
      return ('Non-Fiction', 'AI, Data Science & Machine Learning');
    }
    if (hay.contains('security') ||
        hay.contains('hacking') ||
        hay.contains('cyber') ||
        hay.contains('cryptography') ||
        hay.contains('network')) {
      return ('Non-Fiction', 'Cybersecurity & Networking');
    }
    if (hay.contains('arduino') ||
        hay.contains('raspberry pi') ||
        hay.contains('electronics') ||
        hay.contains('robotics') ||
        hay.contains('hardware')) {
      return ('Non-Fiction', 'Hardware, Electronics & Robotics');
    }
    if (hay.contains('game') || hay.contains('unity') || hay.contains('unreal')) {
      return ('Non-Fiction', 'Game Development & Design');
    }
    if (hay.contains('math') ||
        hay.contains('calculus') ||
        hay.contains('algebra') ||
        hay.contains('statistics')) {
      return ('Non-Fiction', 'Mathematics & Statistics');
    }
    if (hay.contains('python') ||
        hay.contains('java') ||
        hay.contains('programming') ||
        hay.contains('software') ||
        hay.contains('code') ||
        hay.contains('web') ||
        hay.contains('sql')) {
      return ('Non-Fiction', 'Programming & Software Engineering');
    }
    return ('Non-Fiction', 'General Non-Fiction');
  }

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? publicationDate,
    String? isbn,
    String? genre,
    int? pageCount,
    int? wordCount,
    List<int>? chapterPositions,
    String? coverImagePath,
    String? textFilePath,
    String? originalFilePath,
    String? fileFormat,
    DateTime? dateAdded,
    int? currentPosition,
    int? currentPage,
    List<String>? categories,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      publicationDate: publicationDate ?? this.publicationDate,
      isbn: isbn ?? this.isbn,
      genre: genre ?? this.genre,
      pageCount: pageCount ?? this.pageCount,
      wordCount: wordCount ?? this.wordCount,
      chapterPositions: chapterPositions ?? this.chapterPositions,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      textFilePath: textFilePath ?? this.textFilePath,
      originalFilePath: originalFilePath ?? this.originalFilePath,
      fileFormat: fileFormat ?? this.fileFormat,
      dateAdded: dateAdded ?? this.dateAdded,
      currentPosition: currentPosition ?? this.currentPosition,
      currentPage: currentPage ?? this.currentPage,
      categories: categories ?? this.categories,
    );
  }
}
