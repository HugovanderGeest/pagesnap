import 'package:flutter/material.dart';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:image_cropper/image_cropper.dart';
import '../services/ocr_service.dart';
import '../services/scan_counter.dart';
import '../services/book_store.dart';
import '../models/book.dart';
import '../theme/colors.dart';
import 'reader_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({Key? key}) : super(key: key);

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0; // which camera is active
  final List<String> _capturedPaths = [];
  final OcrService _ocr = OcrService();

  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _showTips = true;
  String _status = 'Align the page inside the frame and tap the shutter';

  // After OCR succeeds:
  List<String> _extractedWords = [];
  bool _showSaveView = false;
  final TextEditingController _bookTitleCtrl = TextEditingController();

  // Fallback: user pastes text manually
  bool _showPasteView = false;
  final TextEditingController _pasteCtrl = TextEditingController();

  int _totalScanned = 0;

  static const int _maxPages = 10;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _loadScanCount();
    _startTipsTimer();
  }

  Timer? _tipsTimer;

  void _startTipsTimer() {
    _tipsTimer?.cancel();
    _tipsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showTips = false);
    });
  }

  Future<void> _loadScanCount() async {
    final count = await ScanCounter.getCount();
    if (mounted) setState(() => _totalScanned = count);
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      setState(() => _status = 'No camera found on this device.');
      return;
    }
    await _startCamera(_cameraIndex);
  }

  Future<void> _startCamera(int index) async {
    await _controller?.dispose();
    _controller = CameraController(
      _cameras[index],
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _controller!.initialize();
    if (mounted)
      setState(() {
        _isInitialized = true;
        _cameraIndex = index;
      });
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    final next = (_cameraIndex + 1) % _cameras.length;
    setState(() => _isInitialized = false);
    await _startCamera(next);
  }

  @override
  void dispose() {
    _tipsTimer?.cancel();
    _controller?.dispose();
    _ocr.dispose();
    _bookTitleCtrl.dispose();
    _pasteCtrl.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_capturedPaths.length >= _maxPages) return;

    // Enforce free-tier limit for guests
    if (!ScanCounter.isLoggedIn && _totalScanned >= ScanCounter.freeLimit) {
      _showPaywall();
      return;
    }

    final file = await _controller!.takePicture();

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: file.path,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 90,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Text Area',
          toolbarColor: AppTheme.background,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
             title: 'Crop Text Area',
             aspectRatioPickerButtonHidden: false,
             resetButtonHidden: false,
             doneButtonTitle: 'Done',
             cancelButtonTitle: 'Cancel',
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _capturedPaths.add(croppedFile.path);
        _showTips = false;
        _status =
            '${_capturedPaths.length}/$_maxPages pages captured. '
            '${_capturedPaths.length < _maxPages ? 'Scan another or tap Identify.' : 'Tap Identify to find your book!'}';
      });

      // Count only scans by guests
      if (!ScanCounter.isLoggedIn) {
        await ScanCounter.increment();
        final updated = await ScanCounter.getCount();
        if (mounted) setState(() => _totalScanned = updated);
      }
    }
  }

  void _showPaywall() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Free scans used up',
          style: TextStyle(color: AppTheme.text, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'You\'ve used all 10 free scans.\n\n'
          'Create a free account to keep scanning and sync your reading progress.',
          style: TextStyle(color: AppTheme.textDim, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Not now',
              style: TextStyle(color: AppTheme.textDim),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // close dialog
              Navigator.pop(context); // close scanner — Account tab is waiting
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text('Create free account →'),
          ),
        ],
      ),
    );
  }

  Future<void> _identify() async {
    if (_capturedPaths.isEmpty) return;
    setState(() {
      _isProcessing = true;
      _status = 'Reading text from images…';
    });
    try {
      final text = await _ocr.extractTextFromImages(_capturedPaths);
      final words = text
          .split(RegExp(r'\s+'))
          .map((w) => w.trim())
          .where(
            (w) =>
                w.isNotEmpty && w.contains(RegExp(r'[a-zA-Z0-9\u00C0-\u024F]')),
          )
          .toList();
      setState(() {
        _isProcessing = false;
        _extractedWords = words;
        _showSaveView = true;
        _status =
            '${words.length} words extracted from ${_capturedPaths.length} pages';
      });
    } on UnsupportedError {
      setState(() {
        _isProcessing = false;
        _showPasteView = true;
        _status = 'Paste the text you want to read';
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _status = 'Could not read text: $e';
      });
    }
  }

  Future<void> _saveAndRead(List<String> words) async {
    if (words.isEmpty) return;
    final rawTitle = _bookTitleCtrl.text.trim();
    final now = DateTime.now();
    final title = rawTitle.isNotEmpty
        ? rawTitle
        : 'Scan ${now.day}/${now.month}/${now.year}';
    final book = LocalBook(
      id: now.millisecondsSinceEpoch.toString(),
      title: title,
      progress: 0.0,
      wordIndex: 0,
      totalWords: words.length,
      lastRead: now.millisecondsSinceEpoch,
      words: words,
    );
    await BookStore.save(book);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ReaderScreen(bookId: book.id)),
    );
  }

  void _reset() {
    setState(() {
      _capturedPaths.clear();
      _extractedWords = [];
      _showSaveView = false;
      _showPasteView = false;
      _showTips = true;
      _bookTitleCtrl.clear();
      _pasteCtrl.clear();
      _status = 'Align the page inside the frame and tap the shutter';
    });
    _startTipsTimer();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_showPasteView) {
      body = _buildPasteTextView();
    } else if (_showSaveView) {
      body = _buildSaveBookView();
    } else {
      body = _buildScannerView();
    }
    return Scaffold(backgroundColor: Colors.black, body: body);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildScannerView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Camera Preview (full-screen, cover-fit) ───────────────────────────
        if (_isInitialized && _controller != null)
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.contain, // NOT cover — avoids zoom
              child: SizedBox(
                width: _controller!.value.previewSize?.height ?? 1,
                height: _controller!.value.previewSize?.width ?? 1,
                child: CameraPreview(_controller!),
              ),
            ),
          )
        else
          Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),

        // ── Frame guide ───────────────────────────────────────────────────────
        CustomPaint(painter: _ScanOverlayPainter()),

        // ── Tips banner ───────────────────────────────────────────────────────
        if (_showTips)
          Positioned(
            top: MediaQuery.of(context).padding.top + 72,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.78),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.accent.withOpacity(0.5)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Color(0xFFF59E0B),
                        size: 15,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'SCANNING TIPS',
                        style: TextStyle(
                          color: Color(0xFFF59E0B),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Good lighting — avoid shadows\n'
                    '• Hold the phone steady above the page\n'
                    '• Scan text-heavy pages (not the cover)\n'
                    '• Latin/European alphabet works best',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ── Top bar ───────────────────────────────────────────────────────────
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              right: 16,
              bottom: 10,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(19),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Book Scanner',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showTips = !_showTips;
                      if (_showTips) _startTipsTimer();
                    });
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(19),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Icon(
                      Icons.lightbulb_outline,
                      color: _showTips ? const Color(0xFFF59E0B) : Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                if (_cameras.length > 1) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _switchCamera,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(
                        Icons.flip_camera_ios,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // ── Bottom controls ───────────────────────────────────────────────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.only(
              top: 20,
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 24,
              right: 24,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black.withOpacity(0.88)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    _status,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 14),

                // Page dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _maxPages,
                    (i) => Container(
                      width: 16,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: i < _capturedPaths.length
                            ? const Color(0xFFF59E0B)
                            : Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _actionButton(
                      Icons.refresh,
                      'Reset',
                      Colors.white10,
                      _capturedPaths.isNotEmpty ? _reset : null,
                    ),

                    GestureDetector(
                      onTap: _isProcessing || _capturedPaths.length >= _maxPages
                          ? null
                          : _capture,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primary,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.5),
                              blurRadius: 18,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),

                    _actionButton(
                      Icons.search,
                      'Identify',
                      AppTheme.accent.withOpacity(0.2),
                      _capturedPaths.isNotEmpty && !_isProcessing
                          ? _identify
                          : null,
                      textColor: AppTheme.accent,
                      iconColor: AppTheme.accent,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Processing overlay ────────────────────────────────────────────────
        if (_isProcessing)
          Container(
            color: Colors.black87,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppTheme.accent),
                const SizedBox(height: 20),
                Text(
                  _status,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Save Book view — shown after OCR succeeds ────────────────────────────
  Widget _buildSaveBookView() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _reset,
                child: const Row(
                  children: [
                    Icon(Icons.arrow_back, color: AppTheme.textDim, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Scan Again',
                      style: TextStyle(color: AppTheme.textDim, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Stats card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.text_snippet_outlined,
                      color: AppTheme.accent,
                      size: 28,
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_extractedWords.length} words extracted',
                          style: const TextStyle(
                            color: AppTheme.text,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'from ${_capturedPaths.length} scanned ${_capturedPaths.length == 1 ? 'page' : 'pages'}',
                          style: const TextStyle(
                            color: AppTheme.textDim,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Title input
              const Text(
                'BOOK TITLE',
                style: TextStyle(
                  color: AppTheme.textDim,
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _bookTitleCtrl,
                style: const TextStyle(color: AppTheme.text),
                decoration: InputDecoration(
                  hintText: 'Optional — leave blank for auto title',
                  hintStyle: const TextStyle(color: AppTheme.textDim),
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: AppTheme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: AppTheme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: AppTheme.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Text preview
              if (_extractedWords.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    _extractedWords.take(40).join(' ') +
                        (_extractedWords.length > 40 ? '…' : ''),
                    style: const TextStyle(
                      color: AppTheme.textDim,
                      fontSize: 12,
                      height: 1.6,
                      fontFamily: 'Georgia',
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _saveAndRead(_extractedWords),
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text(
                    'SAVE & READ NOW',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    await _saveAndRead(_extractedWords);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.text,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppTheme.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'ADD TO LIBRARY ONLY',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Paste text fallback — when camera OCR not available ───────────────────
  Widget _buildPasteTextView() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _reset,
                child: const Row(
                  children: [
                    Icon(Icons.arrow_back, color: AppTheme.textDim, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Back to Scanner',
                      style: TextStyle(color: AppTheme.textDim, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Icon(
                Icons.edit_note_rounded,
                color: AppTheme.accent,
                size: 40,
              ),
              const SizedBox(height: 10),
              const Text(
                'Camera OCR not available',
                style: TextStyle(
                  color: AppTheme.text,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Paste or type the text you want to read at speed:',
                style: TextStyle(
                  color: AppTheme.textDim,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TextField(
                  controller: _pasteCtrl,
                  maxLines: null,
                  expands: true,
                  autofocus: true,
                  style: const TextStyle(
                    color: AppTheme.text,
                    fontSize: 14,
                    height: 1.7,
                  ),
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText: 'Paste your text here…',
                    hintStyle: const TextStyle(color: AppTheme.textDim),
                    filled: true,
                    fillColor: AppTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppTheme.primary,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final text = _pasteCtrl.text.trim();
                    if (text.isEmpty) return;
                    final words = text
                        .split(RegExp(r'\s+'))
                        .map((w) => w.trim())
                        .where(
                          (w) =>
                              w.isNotEmpty &&
                              w.contains(RegExp(r'[a-zA-Z0-9\u00C0-\u024F]')),
                        )
                        .toList();
                    setState(() {
                      _extractedWords = words;
                      _showPasteView = false;
                      _showSaveView = true;
                    });
                  },
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text(
                    'CONTINUE',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton(
    IconData icon,
    String label,
    Color bg,
    VoidCallback? onTap, {
    Color? textColor,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap != null ? 1.0 : 0.3,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            children: [
              Icon(icon, color: iconColor ?? Colors.white54, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: textColor ?? Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rect = Rect.fromLTWH(
      size.width * 0.05,
      size.height * 0.14,
      size.width * 0.9,
      size.height * 0.6,
    );

    const cornerLen = 26.0;
    for (final corner
        in [
              [
                rect.topLeft,
                const Offset(cornerLen, 0),
                const Offset(0, cornerLen),
              ],
              [
                rect.topRight,
                const Offset(-cornerLen, 0),
                const Offset(0, cornerLen),
              ],
              [
                rect.bottomLeft,
                const Offset(cornerLen, 0),
                const Offset(0, -cornerLen),
              ],
              [
                rect.bottomRight,
                const Offset(-cornerLen, 0),
                const Offset(0, -cornerLen),
              ],
            ]
            as List<List<Offset>>) {
      canvas.drawLine(corner[0], corner[0] + corner[1], paint);
      canvas.drawLine(corner[0], corner[0] + corner[2], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
