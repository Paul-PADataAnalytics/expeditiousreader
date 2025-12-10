// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Book _$BookFromJson(Map<String, dynamic> json) => Book(
  id: json['id'] as String,
  title: json['title'] as String,
  author: json['author'] as String,
  publicationDate: json['publicationDate'] as String?,
  isbn: json['isbn'] as String?,
  genre: json['genre'] as String?,
  pageCount: (json['pageCount'] as num).toInt(),
  wordCount: (json['wordCount'] as num).toInt(),
  chapterPositions: (json['chapterPositions'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
  coverImagePath: json['coverImagePath'] as String?,
  textFilePath: json['textFilePath'] as String,
  originalFilePath: json['originalFilePath'] as String,
  fileFormat: json['fileFormat'] as String,
  dateAdded: DateTime.parse(json['dateAdded'] as String),
  currentPosition: (json['currentPosition'] as num?)?.toInt() ?? 0,
  currentPage: (json['currentPage'] as num?)?.toInt() ?? 0,
  categories:
      (json['categories'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
);

Map<String, dynamic> _$BookToJson(Book instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'author': instance.author,
  'publicationDate': instance.publicationDate,
  'isbn': instance.isbn,
  'genre': instance.genre,
  'pageCount': instance.pageCount,
  'wordCount': instance.wordCount,
  'chapterPositions': instance.chapterPositions,
  'coverImagePath': instance.coverImagePath,
  'textFilePath': instance.textFilePath,
  'originalFilePath': instance.originalFilePath,
  'fileFormat': instance.fileFormat,
  'dateAdded': instance.dateAdded.toIso8601String(),
  'currentPosition': instance.currentPosition,
  'currentPage': instance.currentPage,
  'categories': instance.categories,
};
