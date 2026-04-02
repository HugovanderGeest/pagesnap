import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/colors.dart';
import '../models/book.dart';
import '../services/book_store.dart';
import '../services/epub_extractor.dart';
import '../services/pdf_extractor.dart';
import 'reader_screen.dart';
import 'scanner_screen.dart';
import 'account_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<LocalBook> books = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    final saved = await BookStore.getAll();
    setState(() => books = saved);
  }

  Future<void> _handleImport() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub', 'pdf'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() => isLoading = true);
        final bytes = result.files.single.bytes!;
        final name = result.files.single.name;
        List<String> words = [];

        try {
          if (name.toLowerCase().endsWith('.epub')) {
            words = await EpubExtractor.extractNative(bytes);
          } else if (name.toLowerCase().endsWith('.pdf')) {
            words = await PdfExtractor.extractNative(bytes);
          }
        } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
          setState(() => isLoading = false);
          return;
        }

        if (words.isNotEmpty) {
          final newBook = LocalBook(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: name.replaceAll('.epub', '').replaceAll('.pdf', ''),
            progress: 0.0,
            wordIndex: 0,
            totalWords: words.length,
            lastRead: DateTime.now().millisecondsSinceEpoch,
            words: words,
          );
          await BookStore.save(newBook);
          await _loadBooks();
        }
      } else if (result != null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not read file data.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import error: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _openBook(LocalBook book) {
    Navigator.of(context).push(
      MaterialPageRoute(fullscreenDialog: true, builder: (context) => ReaderScreen(bookId: book.id)),
    ).then((_) => _loadBooks());
  }

  String _formatLastRead(int ms) {
    final diff = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms));
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final recentBooks = books.where((b) => b.progress > 0).take(5).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // ── Header ──────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Row(
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            Image.asset('assets/logo.png', height: 32, width: 32),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScannerScreen())),
                                  icon: const Icon(LucideIcons.camera, size: 16, color: AppTheme.accent),
                                  label: const Text('Scan', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 13)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppTheme.accent, width: 0.8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    backgroundColor: AppTheme.accent.withOpacity(0.08),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: isLoading ? null : _handleImport,
                                  icon: const Icon(LucideIcons.plus, size: 16, color: AppTheme.primary),
                                  label: const Text('Import', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppTheme.border),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    backgroundColor: AppTheme.surface,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AccountScreen())),
                                  borderRadius: BorderRadius.circular(24),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppTheme.border),
                                      shape: BoxShape.circle,
                                      color: AppTheme.surface,
                                    ),
                                    child: const Icon(LucideIcons.user, size: 18, color: AppTheme.text),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Continue Reading ─────────────────────────────────────────
                if (recentBooks.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                      child: Row(
                        children: [
                          Icon(LucideIcons.history, size: 14, color: AppTheme.accent),
                          const SizedBox(width: 8),
                          const Text('CONTINUE READING', style: TextStyle(color: AppTheme.accent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: recentBooks.length,
                        itemBuilder: (context, index) {
                          final book = recentBooks[index];
                          return GestureDetector(
                            onTap: () => _openBook(book),
                            child: Container(
                              width: 240,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: AppTheme.text, fontWeight: FontWeight.bold, fontSize: 14)),
                                      ),
                                      Text(_formatLastRead(book.lastRead),
                                        style: const TextStyle(color: AppTheme.textDim, fontSize: 10, fontFamily: 'Courier')),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${(book.progress * 100).round()}% complete',
                                        style: const TextStyle(color: AppTheme.textDim, fontSize: 11)),
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(2),
                                        child: LinearProgressIndicator(
                                          value: book.progress,
                                          backgroundColor: AppTheme.border.withOpacity(0.5),
                                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent),
                                          minHeight: 4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],

                // ── All Books ────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                    child: Row(
                      children: [
                        Icon(LucideIcons.bookOpen, size: 14, color: AppTheme.primary),
                        const SizedBox(width: 8),
                        Text('ALL BOOKS (${books.length})', style: const TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
                      ],
                    ),
                  ),
                ),

                if (books.isEmpty && !isLoading)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.bookOpen, color: AppTheme.primary.withOpacity(0.3), size: 64),
                          const SizedBox(height: 20),
                          const Text('YOUR LIBRARY IS EMPTY', style: TextStyle(color: AppTheme.textDim, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2)),
                          const SizedBox(height: 10),
                          const Text('Import a PDF/EPUB or tap SCAN\nto identify a physical book.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontFamily: 'Courier', color: AppTheme.textDim, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),

                if (books.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final book = books[index];
                          return GestureDetector(
                            onTap: () => _openBook(book),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(book.title,
                                            style: const TextStyle(color: AppTheme.text, fontSize: 15, fontWeight: FontWeight.bold),
                                            maxLines: 3, overflow: TextOverflow.ellipsis),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('${(book.progress * 100).round()}%',
                                                style: TextStyle(color: book.progress > 0 ? AppTheme.accent : AppTheme.textDim, fontSize: 11, fontWeight: FontWeight.bold)),
                                              Text(_formatLastRead(book.lastRead),
                                                style: const TextStyle(color: AppTheme.textDim, fontSize: 10)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                                    child: LinearProgressIndicator(
                                      value: book.progress,
                                      backgroundColor: AppTheme.border.withOpacity(0.3),
                                      valueColor: AlwaysStoppedAnimation<Color>(book.progress > 0 ? AppTheme.accent : AppTheme.primary),
                                      minHeight: 3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: books.length,
                      ),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          if (isLoading)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(color: AppTheme.primary),
                    SizedBox(height: 16),
                    Text('Extracting text...', style: TextStyle(color: AppTheme.accent, fontFamily: 'Courier', fontWeight: FontWeight.bold, letterSpacing: 2)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
