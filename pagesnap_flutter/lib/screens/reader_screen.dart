import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'reader_screen_helper_stub.dart'
    if (dart.library.html) 'reader_screen_web_helper.dart';
import '../models/book.dart';
import '../services/book_store.dart';
import '../services/sync_service.dart';
import '../widgets/rsvp_engine.dart';

class ReaderScreen extends StatefulWidget {
  final String bookId;
  const ReaderScreen({super.key, required this.bookId});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  LocalBook? book;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    // Force landscape, full bleed
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
    ));
    _loadBook();
  }

  void _enterWebFullscreen() {
    if (kIsWeb) {
      enterWebFullscreen();
    }
  }

  void _exitWebFullscreen() {
    if (kIsWeb) {
      exitWebFullscreen();
    }
  }

  void _toggleFullscreen() {
    if (_isFullscreen) {
      _exitWebFullscreen();
    } else {
      _enterWebFullscreen();
    }
    setState(() => _isFullscreen = !_isFullscreen);
  }

  @override
  void dispose() {
    if (kIsWeb) _exitWebFullscreen();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _loadBook() async {
    final b = await BookStore.getById(widget.bookId);
    if (mounted) setState(() => book = b);
  }

  void _handleProgress(int index) {
    if (book != null && index % 10 == 0) {
      BookStore.updateProgress(book!.id, index, book!.words.length)
          .then((_) { if (book != null) SyncService.pushBook(book!); });
    }
  }

  void _handleClose() {
    if (book != null) SyncService.pushBook(book!);
    if (kIsWeb) _exitWebFullscreen();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (book == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      // NO SafeArea — we want full edge-to-edge
      body: Stack(
        children: [
          RSVPEngine(
            words: book!.words,
            initialIndex: book!.wordIndex,
            onProgress: _handleProgress,
            onCompletion: _handleClose,
            onFullscreen: kIsWeb ? _toggleFullscreen : null,
          ),

          // Tiny close button — top-left corner, semi-transparent
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 24,
            child: GestureDetector(
              onTap: _handleClose,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: Text(
                  '✕  Close',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
