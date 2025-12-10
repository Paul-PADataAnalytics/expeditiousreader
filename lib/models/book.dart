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
