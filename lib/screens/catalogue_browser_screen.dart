import 'package:flutter/material.dart';
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
  List<Map<String, dynamic>> _topics = [];
  int _totalCount = 0;
  int? _selectedCollectionId;
  int? _selectedTopicId;
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
      final cols = await _catalogueService.fetchCollections();
      final tops = await _catalogueService.fetchTopics();
      cols.sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
      tops.sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
      if (!mounted) return;
      setState(() {
        _collections = cols.where((c) => c['name'] != 'Unknown').toList();
        _topics = tops.where((t) => t['name'] != 'Unknown').toList();
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
        collectionId: _selectedCollectionId,
        topicId: _selectedTopicId,
        limit: 100,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Catalogue ($_totalCount books)'),
        actions: [
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search 1,900+ books by title, author, topic, bundle...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
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
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loadBooks,
                  child: const Text('Search'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                DropdownButton<int?>(
                  value: _selectedCollectionId,
                  hint: const Text('All Bundles / Collections'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('All Bundles / Collections'),
                    ),
                    ..._collections.map(
                      (c) => DropdownMenuItem<int?>(
                        value: (c['id'] as num).toInt(),
                        child: SizedBox(
                          width: 260,
                          child: Text(
                            c['name']?.toString() ?? '',
                            overflow: TextOverflow.ellipsis,
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
                DropdownButton<int?>(
                  value: _selectedTopicId,
                  hint: const Text('All Topics'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('All Topics'),
                    ),
                    ..._topics.map(
                      (t) => DropdownMenuItem<int?>(
                        value: (t['id'] as num).toInt(),
                        child: SizedBox(
                          width: 200,
                          child: Text(
                            t['name']?.toString() ?? '',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedTopicId = val;
                    });
                    _loadBooks();
                  },
                ),
              ],
            ),
          ),
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
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final isDownloading = _downloadingBookId == item.id;
                          final sizeMb = (item.filesize / (1024 * 1024)).toStringAsFixed(1);

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                                Text(
                                  '${item.fileFormat.toUpperCase()} ($sizeMb MB)${item.topics.isNotEmpty ? " • ${item.topics.take(4).join(", ")}" : ""}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
