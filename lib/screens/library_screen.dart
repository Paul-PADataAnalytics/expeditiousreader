import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import '../providers/library_provider.dart';
import '../models/book.dart';
import 'speed_reader_screen.dart';
import 'traditional_reader_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final Set<String> _selectedBooks = {};
  bool _isSelectionMode = false;
  LibraryProvider? _libraryProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _libraryProvider = context.read<LibraryProvider>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelected,
            ),
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSelectionMode = false;
                  _selectedBooks.clear();
                });
              },
            ),
          if (!_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _importBook,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by title or author...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                context.read<LibraryProvider>().setSearchQuery(value);
              },
            ),
          ),
          Expanded(
            child: Consumer<LibraryProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final books = provider.books;

                if (books.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.book, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No books in library',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Import Books'),
                          onPressed: _importBook,
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index];
                    final isSelected = _selectedBooks.contains(book.id);

                    return GestureDetector(
                      onLongPress: () {
                        setState(() {
                          _isSelectionMode = true;
                          _selectedBooks.add(book.id);
                        });
                      },
                      onTap: () {
                        if (_isSelectionMode) {
                          setState(() {
                            if (isSelected) {
                              _selectedBooks.remove(book.id);
                              if (_selectedBooks.isEmpty) {
                                _isSelectionMode = false;
                              }
                            } else {
                              _selectedBooks.add(book.id);
                            }
                          });
                        } else {
                          _showBookOptions(context, book);
                        }
                      },
                      child: Card(
                        elevation: isSelected ? 8 : 2,
                        color: isSelected ? Colors.blue.shade100 : null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Stack(
                                children: [
                                  _buildCoverImage(book),
                                  // Progress indicator badge
                                  if (book.currentPosition > 0 || book.currentPage > 0)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${_calculateProgress(book)}%',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      book.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      book.author,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    // Progress bar with percentage
                                    if (book.currentPosition > 0 || book.currentPage > 0) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            '${_calculateProgress(book)}%',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(2),
                                              child: LinearProgressIndicator(
                                                value: _calculateProgress(book) / 100,
                                                minHeight: 3,
                                                backgroundColor: Colors.grey[300],
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  Colors.blue.shade600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImage(Book book) {
    if (book.coverImagePath == null) {
      return _buildPlaceholderCover(book);
    }

    if (kIsWeb) {
      // On web, load cover from SharedPreferences
      return FutureBuilder<String?>(
        future: SharedPreferences.getInstance().then((prefs) => prefs.getString(book.coverImagePath!)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData && snapshot.data != null) {
            try {
              // Cover is stored as base64
              final bytes = base64Decode(snapshot.data!);
              return Image.memory(
                bytes,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) => _buildPlaceholderCover(book),
              );
            } catch (e) {
              return _buildPlaceholderCover(book);
            }
          }
          return _buildPlaceholderCover(book);
        },
      );
    } else {
      // On desktop/mobile, load from file
      return Image.file(
        File(book.coverImagePath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholderCover(book),
      );
    }
  }

  Widget _buildPlaceholderCover(Book book) {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.book, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                book.title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookOptions(BuildContext context, Book book) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.speed),
            title: const Text('Speed Read'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SpeedReaderScreen(book: book),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.menu_book),
            title: const Text('Traditional Read'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TraditionalReaderScreen(book: book),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text('Change Cover'),
            onTap: () {
              Navigator.pop(context);
              _changeCover(book);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _deleteBook(book);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _importBook() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'epub', 'txt'],
        allowMultiple: true, // Enable multiple file selection
        withData: kIsWeb, // Load file bytes on web platform
      );

      if (result != null && result.files.isNotEmpty) {
        if (!mounted) return;
        
        // Show loading dialog with progress
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Importing ${result.files.length} book(s)...'),
              ],
            ),
          ),
        );

        Map<String, dynamic>? results;
        
        if (kIsWeb) {
          // On web, use file bytes
          final fileDataList = result.files
              .where((file) => file.bytes != null && file.name.isNotEmpty)
              .map((file) => {
                'bytes': file.bytes!,
                'name': file.name,
              })
              .toList();
          
          if (fileDataList.isEmpty) {
            if (!mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No valid files selected')),
            );
            return;
          }
          
          results = await _libraryProvider?.importBooksFromBytes(fileDataList);
        } else {
          // On desktop/mobile, use file paths
          final filePaths = result.files
              .where((file) => file.path != null)
              .map((file) => file.path!)
              .toList();
          
          if (filePaths.isEmpty) {
            if (!mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No valid files selected')),
            );
            return;
          }
          
          results = await _libraryProvider?.importBooks(filePaths);
        }

        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog

        if (results != null) {
          final successCount = results['success'] as int;
          final failedCount = results['failed'] as int;
          final errors = results['errors'] as List<String>;
          final warnings = results.containsKey('warnings') 
              ? results['warnings'] as List<String> 
              : <String>[];
          
          if (failedCount == 0 && warnings.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Successfully imported $successCount book(s)'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            // Show detailed results
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Import Results'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('✓ Successfully imported: $successCount'),
                      if (failedCount > 0) ...[
                        const SizedBox(height: 8),
                        Text('✗ Failed to import: $failedCount'),
                        const SizedBox(height: 8),
                        const Text('Errors:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ...errors.map((error) => Padding(
                          padding: const EdgeInsets.only(left: 8, top: 4),
                          child: Text('• $error', style: const TextStyle(fontSize: 12)),
                        )),
                      ],
                      if (warnings.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text('⚠️ Warnings:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                        ...warnings.map((warning) => Padding(
                          padding: const EdgeInsets.only(left: 8, top: 4),
                          child: Text('• $warning', style: const TextStyle(fontSize: 12, color: Colors.orange)),
                        )),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      // Try to close loading dialog if open
      Navigator.of(context).popUntil((route) => route.isFirst);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error importing books: $e')),
      );
    }
  }

  Future<void> _deleteSelected() async {
    if (_libraryProvider == null) return;
    
    final booksToDelete = _libraryProvider!.books
        .where((book) => _selectedBooks.contains(book.id))
        .toList();

    await _libraryProvider!.deleteBooks(booksToDelete);

    setState(() {
      _selectedBooks.clear();
      _isSelectionMode = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted ${booksToDelete.length} book(s)')),
    );
  }

  Future<void> _deleteBook(Book book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text('Are you sure you want to delete "${book.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted && _libraryProvider != null) {
      await _libraryProvider!.deleteBooks([book]);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book deleted')),
      );
    }
  }

  Future<void> _changeCover(Book book) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.single.path != null) {
        if (!mounted || _libraryProvider == null) return;
        await _libraryProvider!
            .updateCoverImage(book, result.files.single.path!);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cover updated')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating cover: $e')),
      );
    }
  }

  int _calculateProgress(Book book) {
    // Use the maximum progress from either speed reading position or traditional page
    int speedProgress = 0;
    int pageProgress = 0;

    if (book.wordCount > 0 && book.currentPosition > 0) {
      speedProgress = ((book.currentPosition / book.wordCount) * 100).round();
    }

    if (book.pageCount > 0 && book.currentPage > 0) {
      pageProgress = ((book.currentPage / book.pageCount) * 100).round();
    }

    // Return the higher of the two progress values
    return speedProgress > pageProgress ? speedProgress : pageProgress;
  }
}
