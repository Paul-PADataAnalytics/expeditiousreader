import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../providers/library_provider.dart';
import '../services/catalogue_service.dart';
import 'speed_reader_screen.dart';
import 'traditional_reader_screen.dart';

class CatalogueBrowserScreen extends StatefulWidget {
  const CatalogueBrowserScreen({super.key});

  @override
  State<CatalogueBrowserScreen> createState() => _CatalogueBrowserScreenState();
}

class _CatalogueBrowserScreenState extends State<CatalogueBrowserScreen> {
  final CatalogueService _catalogueService = CatalogueService();
  final TextEditingController _searchController = TextEditingController();

  List<CatalogueItem> _items = [];
  List<Map<String, dynamic>> _collections = [];
  List<Map<String, dynamic>> _taxonomyCategories = [];
  List<Map<String, dynamic>> _taxonomySubjects = [];
  List<Map<String, dynamic>> _taxonomyTopics = [];
  int _totalCatalogueBooks = 0;

  int _totalCount = 0;
  String? _selectedCategory; // 'Non-Fiction' or 'Fiction'
  String? _selectedSubject; // Subject shelf name
  String? _selectedTopicName; // Topic name
  int? _selectedCollectionId;
  bool _isLoading = true;
  String? _error;
  int? _downloadingBookId;
  String _serverUrl = CatalogueService.defaultHostUrl;

  @override
  void initState() {
    super.initState();
    _initCatalogue();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initCatalogue() async {
    final url = await _catalogueService.getServerUrl();
    setState(() {
      _serverUrl = url;
    });
    await Future.wait([
      _loadFilters(),
      _loadBooks(),
    ]);
  }

  Future<void> _loadFilters() async {
    try {
      final results = await Future.wait([
        _catalogueService.fetchCollections(),
        _catalogueService.fetchTaxonomy(),
      ]);
      final cols = results[0] as List<Map<String, dynamic>>;
      final tax = results[1] as Map<String, dynamic>;
      cols.sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));

      final rawCats = (tax['categories'] as List<dynamic>?) ?? [];
      final rawSubjs = (tax['subjects'] as List<dynamic>?) ?? [];
      final rawTops = (tax['topics'] as List<dynamic>?) ?? [];

      if (!mounted) return;
      setState(() {
        _collections = cols.where((c) => c['name'] != 'Unknown').toList();
        _totalCatalogueBooks = (tax['total_books'] as num?)?.toInt() ?? 0;
        _taxonomyCategories = rawCats.cast<Map<String, dynamic>>();
        _taxonomySubjects = rawSubjs.cast<Map<String, dynamic>>();
        _taxonomyTopics = rawTops.cast<Map<String, dynamic>>();
      });
    } catch (_) {}
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await _catalogueService.fetchFiles(
        query: _searchController.text,
        category: _selectedCategory,
        subject: _selectedSubject,
        topic: _selectedTopicName,
        collectionId: _selectedCollectionId,
        limit: 120,
      );
      if (!mounted) return;
      setState(() {
        _items = res['items'] as List<CatalogueItem>;
        _totalCount = res['total'] as int;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  bool get _hasActiveFilters =>
      _selectedCategory != null ||
      _selectedSubject != null ||
      _selectedTopicName != null ||
      _selectedCollectionId != null ||
      _searchController.text.isNotEmpty;

  void _clearAllFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedSubject = null;
      _selectedTopicName = null;
      _selectedCollectionId = null;
      _searchController.clear();
    });
    _loadBooks();
  }

  List<Map<String, dynamic>> get _visibleSubjects {
    if (_selectedCategory == null) {
      return _taxonomySubjects;
    }
    return _taxonomySubjects
        .where((s) => s['category']?.toString() == _selectedCategory)
        .toList();
  }

  List<Map<String, dynamic>> get _visibleTopics {
    if (_selectedSubject != null) {
      final subjEntry = _taxonomySubjects.firstWhere(
        (s) => s['name']?.toString() == _selectedSubject,
        orElse: () => <String, dynamic>{},
      );
      final nested = (subjEntry['topics'] as List<dynamic>?) ?? [];
      if (nested.isNotEmpty) {
        return nested.cast<Map<String, dynamic>>();
      }
    }
    if (_selectedCategory != null) {
      final merged = <String, int>{};
      for (final s in _visibleSubjects) {
        final nested = (s['topics'] as List<dynamic>?) ?? [];
        for (final rawT in nested) {
          final t = rawT as Map<String, dynamic>;
          final name = t['name']?.toString() ?? '';
          final count = (t['count'] as num?)?.toInt() ?? 0;
          if (name.isNotEmpty) {
            merged[name] = (merged[name] ?? 0) + count;
          }
        }
      }
      final list = merged.entries
          .map((e) => <String, dynamic>{'name': e.key, 'count': e.value})
          .toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
      return list.take(25).toList();
    }
    return _taxonomyTopics.take(25).toList();
  }

  Future<void> _editServerUrl() async {
    final controller = TextEditingController(text: _serverUrl);
    final updated = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Catalogue Server URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'http://localhost:8000',
            labelText: 'Server URL',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (updated != null && updated.trim().isNotEmpty) {
      if (!mounted) return;
      await context.read<LibraryProvider>().updateCatalogueServerUrl(updated);
      await _initCatalogue();
    }
  }

  Future<void> _showAndroidApkDialog() async {
    final apkUrl = await _catalogueService.getApkDownloadUrl();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.android, color: Colors.green),
            SizedBox(width: 8),
            Text('Download Android App (.APK)'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Open this URL in your Android browser (or visit the Server Portal at /kindle) to download and install Expeditious Reader:',
            ),
            const SizedBox(height: 12),
            SelectableText(
              apkUrl,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy Link'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: apkUrl));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Copied $apkUrl to clipboard')),
              );
            },
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _importAndOpenBook(CatalogueItem item, {String? mode}) async {
    setState(() {
      _downloadingBookId = item.id;
    });
    try {
      final bytes = await _catalogueService.downloadBookBytes(item.id);
      if (!mounted) return;
      final provider = context.read<LibraryProvider>();
      final Book imported = await provider.importBookFromCatalogue(item, bytes);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported "${imported.title}" into Library')),
      );

      if (mode == 'speed') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SpeedReaderScreen(book: imported)),
        );
      } else if (mode == 'traditional') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TraditionalReaderScreen(book: imported)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to import "${item.title}": $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _downloadingBookId = null;
        });
      }
    }
  }

  Widget _buildLibraryTaxonomyHeader(BuildContext context) {
    final visibleSubjects = _visibleSubjects;
    final visibleTopics = _visibleTopics;

    int nonFictionCount = 0;
    int fictionCount = 0;
    for (final c in _taxonomyCategories) {
      if (c['name'] == 'Non-Fiction') {
        nonFictionCount = (c['count'] as num?)?.toInt() ?? 0;
      } else if (c['name'] == 'Fiction') {
        fictionCount = (c['count'] as num?)?.toInt() ?? 0;
      }
    }

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Search + Collection Filter + Clear
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search books by title, author, subject, topic, bundle...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _loadBooks();
                              },
                            )
                          : null,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _loadBooks(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _loadBooks,
                child: const Text('Search'),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Fiction vs Non-Fiction Category Wing Selector + Bundle Dropdown
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Icon(Icons.account_balance, size: 18, color: Colors.blueGrey),
              ChoiceChip(
                label: Text(
                  _totalCatalogueBooks > 0
                      ? 'All Books ($_totalCatalogueBooks)'
                      : 'All Books',
                ),
                selected: _selectedCategory == null,
                onSelected: (_) {
                  setState(() {
                    _selectedCategory = null;
                    _selectedSubject = null;
                    _selectedTopicName = null;
                  });
                  _loadBooks();
                },
              ),
              ChoiceChip(
                avatar: const Icon(Icons.school, size: 16),
                label: Text(
                  nonFictionCount > 0 ? 'Non-Fiction ($nonFictionCount)' : 'Non-Fiction',
                ),
                selected: _selectedCategory == 'Non-Fiction',
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = selected ? 'Non-Fiction' : null;
                    _selectedSubject = null;
                    _selectedTopicName = null;
                  });
                  _loadBooks();
                },
              ),
              ChoiceChip(
                avatar: const Icon(Icons.auto_stories, size: 16),
                label: Text(
                  fictionCount > 0 ? 'Fiction ($fictionCount)' : 'Fiction',
                ),
                selected: _selectedCategory == 'Fiction',
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = selected ? 'Fiction' : null;
                    _selectedSubject = null;
                    _selectedTopicName = null;
                  });
                  _loadBooks();
                },
              ),
              const SizedBox(width: 8),
              DropdownButton<int?>(
                value: _selectedCollectionId,
                isDense: true,
                hint: const Text('All Bundles'),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('All Bundles / Collections'),
                  ),
                  ..._collections.map(
                    (c) => DropdownMenuItem<int?>(
                      value: (c['id'] as num).toInt(),
                      child: SizedBox(
                        width: 240,
                        child: Text(
                          c['name']?.toString() ?? '',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedCollectionId = val;
                  });
                  _loadBooks();
                },
              ),
              if (_hasActiveFilters)
                TextButton.icon(
                  icon: const Icon(Icons.filter_alt_off, size: 16),
                  label: const Text('Reset Filters'),
                  onPressed: _clearAllFilters,
                ),
            ],
          ),

          // Row 3: Subject Shelves (Horizontal scrollable bar)
          if (visibleSubjects.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: visibleSubjects.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return FilterChip(
                      label: const Text('All Subject Shelves'),
                      selected: _selectedSubject == null,
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) {
                        setState(() {
                          _selectedSubject = null;
                          _selectedTopicName = null;
                        });
                        _loadBooks();
                      },
                    );
                  }
                  final subj = visibleSubjects[index - 1];
                  final name = subj['name']?.toString() ?? '';
                  final count = (subj['count'] as num?)?.toInt() ?? 0;
                  final isSelected = _selectedSubject == name;
                  return FilterChip(
                    label: Text('$name ($count)'),
                    selected: isSelected,
                    visualDensity: VisualDensity.compact,
                    onSelected: (selected) {
                      setState(() {
                        _selectedSubject = selected ? name : null;
                        _selectedTopicName = null;
                      });
                      _loadBooks();
                    },
                  );
                },
              ),
            ),
          ],

          // Row 4: Contextual Topics (Horizontal scrollable bar)
          if (visibleTopics.isNotEmpty) ...[
            const SizedBox(height: 6),
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: visibleTopics.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ActionChip(
                      avatar: const Icon(Icons.local_offer_outlined, size: 14),
                      label: Text(
                        _selectedTopicName == null
                            ? 'Topics'
                            : 'All Topics',
                        style: const TextStyle(fontSize: 12),
                      ),
                      visualDensity: VisualDensity.compact,
                      onPressed: _selectedTopicName == null
                          ? null
                          : () {
                              setState(() {
                                _selectedTopicName = null;
                              });
                              _loadBooks();
                            },
                    );
                  }
                  final topic = visibleTopics[index - 1];
                  final tName = topic['name']?.toString() ?? '';
                  final tCount = (topic['count'] as num?)?.toInt() ?? 0;
                  final isSelected = _selectedTopicName == tName;
                  return FilterChip(
                    label: Text(
                      tCount > 0 ? '$tName ($tCount)' : tName,
                      style: const TextStyle(fontSize: 12),
                    ),
                    selected: isSelected,
                    visualDensity: VisualDensity.compact,
                    onSelected: (selected) {
                      setState(() {
                        _selectedTopicName = selected ? tName : null;
                      });
                      _loadBooks();
                    },
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Library Catalogue ($_totalCount matching)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.android),
            tooltip: 'Download Android App (.APK)',
            onPressed: _showAndroidApkDialog,
          ),
          IconButton(
            icon: const Icon(Icons.dns),
            tooltip: 'Catalogue Server URL ($_serverUrl)',
            onPressed: _editServerUrl,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Catalogue',
            onPressed: _initCatalogue,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildLibraryTaxonomyHeader(context),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.cloud_off, size: 56, color: Colors.redAccent),
                              const SizedBox(height: 12),
                              Text(
                                'Catalogue Server is not reachable at $_serverUrl\n'
                                'You can continue reading and importing local files in standalone mode, '
                                'or configure a Catalogue Server URL below.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                alignment: WrapAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.settings_ethernet),
                                    label: const Text('Configure Server URL'),
                                    onPressed: _editServerUrl,
                                  ),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.arrow_back),
                                    label: const Text('Use Local Library Only'),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                    : _items.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.search_off, size: 48, color: Colors.grey),
                                const SizedBox(height: 12),
                                const Text('No books match the selected library filters.'),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.filter_alt_off),
                                  label: const Text('Reset Filters'),
                                  onPressed: _clearAllFilters,
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: _items.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              final isDownloading = _downloadingBookId == item.id;
                              final sizeMb = (item.filesize / (1024 * 1024)).toStringAsFixed(1);
                              final isFiction = item.category == 'Fiction';

                              return ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                leading: item.coverUrl.isNotEmpty
                                    ? Image.network(
                                        item.coverUrl,
                                        width: 44,
                                        height: 64,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) =>
                                            const Icon(Icons.menu_book, size: 40),
                                      )
                                    : const Icon(Icons.menu_book, size: 40),
                                title: Text(
                                  item.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${item.displayAuthor} • ${item.collectionName}'),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              _selectedCategory = item.category;
                                              _selectedSubject = null;
                                              _selectedTopicName = null;
                                            });
                                            _loadBooks();
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isFiction
                                                  ? Colors.deepPurple.withValues(alpha: 0.12)
                                                  : Colors.teal.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              item.category,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: isFiction
                                                    ? Colors.deepPurple.shade700
                                                    : Colors.teal.shade800,
                                              ),
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              _selectedCategory = item.category;
                                              _selectedSubject = item.subject;
                                              _selectedTopicName = null;
                                            });
                                            _loadBooks();
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blueGrey.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              item.subject,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.blueGrey.shade800,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${item.fileFormat.toUpperCase()} ($sizeMb MB)'
                                          '${item.topics.isNotEmpty ? " • ${item.topics.take(4).join(", ")}" : ""}',
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: isDownloading
                                    ? const SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: CircularProgressIndicator(strokeWidth: 2.5),
                                      )
                                    : Wrap(
                                        spacing: 6,
                                        children: [
                                          OutlinedButton.icon(
                                            icon: const Icon(Icons.download, size: 16),
                                            label: const Text('Add'),
                                            onPressed: () => _importAndOpenBook(item),
                                          ),
                                          ElevatedButton.icon(
                                            icon: const Icon(Icons.chrome_reader_mode, size: 16),
                                            label: const Text('Read'),
                                            onPressed: () =>
                                                _importAndOpenBook(item, mode: 'traditional'),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.speed),
                                            tooltip: 'Speed Read',
                                            onPressed: () =>
                                                _importAndOpenBook(item, mode: 'speed'),
                                          ),
                                        ],
                                      ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
