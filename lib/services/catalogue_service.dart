import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CatalogueItem {
  final int id;
  final String title;
  final String filepath;
  final int filesize;
  final String datecreated;
  final String publisher;
  final String description;
  final String isbn;
  final String coverUrl;
  final int readingProgress;
  final String category;
  final String subject;
  final String collectionName;
  final String fileFormat;
  final String fileExtension;
  final List<String> authors;
  final List<String> topics;

  CatalogueItem({
    required this.id,
    required this.title,
    required this.filepath,
    required this.filesize,
    required this.datecreated,
    required this.publisher,
    required this.description,
    required this.isbn,
    required this.coverUrl,
    required this.readingProgress,
    this.category = 'Non-Fiction',
    this.subject = 'Programming & Software Engineering',
    required this.collectionName,
    required this.fileFormat,
    required this.fileExtension,
    required this.authors,
    required this.topics,
  });

  factory CatalogueItem.fromJson(Map<String, dynamic> json) {
    final collection = json['collection'] as Map<String, dynamic>?;
    final filetype = json['filetype'] as Map<String, dynamic>?;
    final rawAuthors = (json['authors'] as List<dynamic>?) ?? [];
    final rawTopics = (json['topics'] as List<dynamic>?) ?? [];

    final authorNames = rawAuthors
        .map((a) => (a as Map<String, dynamic>)['fullname']?.toString() ?? '')
        .where((name) => name.isNotEmpty && name != 'Unknown')
        .toList();

    final topicNames = rawTopics
        .map((t) => (t as Map<String, dynamic>)['name']?.toString() ?? '')
        .where((name) => name.isNotEmpty && name != 'Unknown')
        .toList();

    final ext = (filetype?['filetypeextension']?.toString() ?? '.epub')
        .replaceAll('.', '')
        .toLowerCase();

    return CatalogueItem(
      id: (json['id'] as num).toInt(),
      title: json['title']?.toString() ?? 'Untitled',
      filepath: json['filepath']?.toString() ?? '',
      filesize: (json['filesize'] as num?)?.toInt() ?? 0,
      datecreated: json['datecreated']?.toString() ?? '',
      publisher: json['publisher']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      isbn: json['isbn']?.toString() ?? '',
      coverUrl: json['cover_url']?.toString() ?? '',
      readingProgress: (json['reading_progress'] as num?)?.toInt() ?? 0,
      category: json['category']?.toString() ?? 'Non-Fiction',
      subject: json['subject']?.toString() ?? 'Programming & Software Engineering',
      collectionName: collection?['name']?.toString() ?? 'Unknown',
      fileFormat: ext.isEmpty ? 'epub' : ext,
      fileExtension: filetype?['filetypeextension']?.toString() ?? '.epub',
      authors: authorNames,
      topics: topicNames,
    );
  }

  String get displayAuthor {
    if (authors.isNotEmpty) {
      return authors.join(', ');
    }
    if (publisher.isNotEmpty) {
      return publisher;
    }
    return 'Unknown Author';
  }

  String get fileName {
    if (filepath.contains('/')) {
      return filepath.split('/').last;
    }
    return '$id.$fileFormat';
  }
}

class CatalogueService {
  static const String _serverUrlPrefKey = 'catalogue_server_url';
  static const String _envServerUrl = String.fromEnvironment('CATALOGUE_URL', defaultValue: '');
  static const String defaultHostUrl = 'http://localhost:8000';

  bool _lastKnownAvailable = false;
  bool get lastKnownAvailable => _lastKnownAvailable;

  Future<String> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_serverUrlPrefKey);
    if (saved != null && saved.trim().isNotEmpty) {
      return saved.trim().replaceAll(RegExp(r'/+$'), '');
    }
    if (_envServerUrl.trim().isNotEmpty) {
      return _envServerUrl.trim().replaceAll(RegExp(r'/+$'), '');
    }
    if (kIsWeb) {
      final origin = Uri.base.origin;
      if (origin.startsWith('http')) {
        return origin;
      }
    }
    return defaultHostUrl;
  }

  Future<void> setServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final cleaned = url.trim().replaceAll(RegExp(r'/+$'), '');
    if (cleaned.isEmpty) {
      await prefs.remove(_serverUrlPrefKey);
    } else {
      await prefs.setString(_serverUrlPrefKey, cleaned);
    }
  }

  /// Probe whether a Catalogue backend is reachable at the configured URL.
  /// Completes quickly without throwing so the app works seamlessly in standalone mode.
  Future<bool> checkAvailability({Duration timeout = const Duration(seconds: 2)}) async {
    try {
      final baseUrl = await getServerUrl();
      final response = await http
          .get(Uri.parse('$baseUrl/api/stats'))
          .timeout(timeout);
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data is Map<String, dynamic> && data.containsKey('files')) {
          _lastKnownAvailable = true;
          return true;
        }
      }
    } catch (_) {
      // Offline or standalone deployment without a Catalogue server
    }
    _lastKnownAvailable = false;
    return false;
  }

  Future<Map<String, dynamic>> fetchFiles({
    String query = '',
    String? category,
    String? subject,
    String? topic,
    int? collectionId,
    int? topicId,
    int limit = 60,
    int offset = 0,
  }) async {
    final baseUrl = await getServerUrl();
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (query.trim().isNotEmpty) {
      queryParams['q'] = query.trim();
    }
    if (category != null && category.trim().isNotEmpty) {
      queryParams['category'] = category.trim();
    }
    if (subject != null && subject.trim().isNotEmpty) {
      queryParams['subject'] = subject.trim();
    }
    if (topic != null && topic.trim().isNotEmpty) {
      queryParams['topic'] = topic.trim();
    }
    if (collectionId != null) {
      queryParams['collection_id'] = collectionId.toString();
    }
    if (topicId != null) {
      queryParams['topic_id'] = topicId.toString();
    }

    final uri = Uri.parse('$baseUrl/api/files').replace(queryParameters: queryParams);
    final response = await http.get(uri).timeout(const Duration(seconds: 6));
    if (response.statusCode != 200) {
      throw Exception('Catalogue server returned HTTP ${response.statusCode}');
    }
    _lastKnownAvailable = true;
    final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final rawItems = (data['items'] as List<dynamic>?) ?? [];
    return {
      'total': (data['total'] as num?)?.toInt() ?? rawItems.length,
      'items': rawItems
          .map((e) => CatalogueItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    };
  }

  Future<Map<String, dynamic>> fetchTaxonomy() async {
    final baseUrl = await getServerUrl();
    final response = await http
        .get(Uri.parse('$baseUrl/api/taxonomy'))
        .timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) {
      return {'total_books': 0, 'categories': [], 'subjects': [], 'topics': []};
    }
    return json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> fetchCollections() async {
    final baseUrl = await getServerUrl();
    final response = await http
        .get(Uri.parse('$baseUrl/api/collections'))
        .timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) return [];
    final list = json.decode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchTopics() async {
    final baseUrl = await getServerUrl();
    final response = await http
        .get(Uri.parse('$baseUrl/api/topics'))
        .timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) return [];
    final list = json.decode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  Future<Uint8List> downloadBookBytes(int fileId) async {
    final baseUrl = await getServerUrl();
    final response = await http
        .get(Uri.parse('$baseUrl/api/files/$fileId/download'))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception('Failed to download book ($fileId): HTTP ${response.statusCode}');
    }
    return response.bodyBytes;
  }

  Future<void> syncReadingProgress(int fileId, int wordPosition) async {
    if (!_lastKnownAvailable) return;
    try {
      final baseUrl = await getServerUrl();
      await http
          .put(
            Uri.parse('$baseUrl/api/files/$fileId/progress'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'reading_progress': wordPosition}),
          )
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      // Non-fatal if offline or standalone
    }
  }
}
