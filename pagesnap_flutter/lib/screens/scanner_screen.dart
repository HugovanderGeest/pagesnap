import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/ocr_service.dart';
import '../services/book_matcher_service.dart';
import '../theme/colors.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({Key? key}) : super(key: key);

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;          // which camera is active
  final List<String> _capturedPaths = [];
  final OcrService _ocr = OcrService();
  final BookMatcherService _matcher = BookMatcherService();

  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _showTips = true;
  String _status = 'Align the page inside the frame and tap the shutter';
  BookMatch? _result;
  bool _noMatch = false;
  bool _webOcrUnavailable = false;  // show manual input fallback
  final TextEditingController _manualTitle = TextEditingController();

  static const int _maxPages = 10;

  @override
  void initState() {
    super.initState();
    _initCamera();
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
    _controller = CameraController(_cameras[index], ResolutionPreset.medium, enableAudio: false);
    await _controller!.initialize();
    if (mounted) setState(() { _isInitialized = true; _cameraIndex = index; });
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    final next = (_cameraIndex + 1) % _cameras.length;
    setState(() => _isInitialized = false);
    await _startCamera(next);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _ocr.dispose();
    _manualTitle.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_capturedPaths.length >= _maxPages) return;
    final file = await _controller!.takePicture();
    setState(() {
      _capturedPaths.add(file.path);
      _showTips = false;
      _noMatch = false;
      _status = '${_capturedPaths.length}/$_maxPages pages captured. '
          '${_capturedPaths.length < _maxPages ? 'Scan another or tap Identify.' : 'Tap Identify to find your book!'}';
    });
  }

  Future<void> _identify() async {
    if (_capturedPaths.isEmpty) return;
    setState(() { _isProcessing = true; _status = 'Reading text from pages…'; });
    try {
      final text = await _ocr.extractTextFromImages(_capturedPaths);
      setState(() => _status = 'Matching from ${text.split(' ').length} words…');
      final match = await _matcher.matchBook(text);
      setState(() {
        _isProcessing = false;
        _result = match;
        _noMatch = match == null;
        _status = match != null ? 'Book identified!' : 'No match. Try scanning 2–3 more pages.';
      });
    } on UnsupportedError {
      // OCR not available on web — let user search by title
      setState(() {
        _isProcessing = false;
        _webOcrUnavailable = true;
        _status = 'Enter the book title to search manually';
      });
    } catch (e) {
      setState(() { _isProcessing = false; _status = 'Error: $e'; });
    }
  }

  void _reset() {
    setState(() {
      _capturedPaths.clear();
      _result = null;
      _noMatch = false;
      _showTips = true;
      _webOcrUnavailable = false;
      _manualTitle.clear();
      _status = 'Align the page inside the frame and tap the shutter';
    });
  }

  Future<void> _openStore(String query) async {
    final uri = Uri.parse('https://www.google.com/search?q=${Uri.encodeQueryComponent(query)}+buy+ebook');
    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _webOcrUnavailable
          ? _buildManualSearchView()
          : (_result != null
              ? _buildResultView()
              : (_noMatch ? _buildNoMatchView() : _buildScannerView())),
    );
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
              fit: BoxFit.contain,          // NOT cover — avoids zoom
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
            child: const Center(child: CircularProgressIndicator(color: Colors.white)),
          ),

        // ── Frame guide ───────────────────────────────────────────────────────
        CustomPaint(painter: _ScanOverlayPainter()),

        // ── Tips banner ───────────────────────────────────────────────────────
        if (_showTips)
          Positioned(
            top: MediaQuery.of(context).padding.top + 72,
            left: 24, right: 24,
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
                  Row(children: [
                    Icon(Icons.lightbulb_outline, color: Color(0xFFF59E0B), size: 15),
                    SizedBox(width: 8),
                    Text('SCANNING TIPS', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  ]),
                  SizedBox(height: 8),
                  Text(
                    '• Good lighting — avoid shadows\n'
                    '• Hold the phone steady above the page\n'
                    '• Scan text-heavy pages (not the cover)\n'
                    '• Latin/European alphabet works best',
                    style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.6)),
                ],
              ),
            ),
          ),

        // ── Top bar ───────────────────────────────────────────────────────────
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16, right: 16, bottom: 10,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(19),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text('Book Scanner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                ),
                // Camera switch button
                if (_cameras.length > 1)
                  GestureDetector(
                    onTap: _switchCamera,
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 18),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // ── Bottom controls ───────────────────────────────────────────────────
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: EdgeInsets.only(
              top: 20,
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 24, right: 24,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black.withOpacity(0.88)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(_status, textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ),
                const SizedBox(height: 14),

                // Page dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_maxPages, (i) => Container(
                    width: 16, height: 4, margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i < _capturedPaths.length ? const Color(0xFFF59E0B) : Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )),
                ),
                const SizedBox(height: 18),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _actionButton(Icons.refresh, 'Reset', Colors.white10,
                      _capturedPaths.isNotEmpty ? _reset : null),

                    GestureDetector(
                      onTap: _isProcessing || _capturedPaths.length >= _maxPages ? null : _capture,
                      child: Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primary,
                          boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.5), blurRadius: 18, spreadRadius: 3)],
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
                      ),
                    ),

                    _actionButton(Icons.search, 'Identify',
                      AppTheme.accent.withOpacity(0.2),
                      _capturedPaths.isNotEmpty && !_isProcessing ? _identify : null,
                      textColor: AppTheme.accent, iconColor: AppTheme.accent),
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
                Text(_status, style: const TextStyle(color: Colors.white, fontSize: 15),
                  textAlign: TextAlign.center),
              ],
            ),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildManualSearchView() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_rounded, size: 64, color: Color(0xFFF59E0B)),
            const SizedBox(height: 20),
            const Text('Text scanning not available in browser',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
            const SizedBox(height: 10),
            const Text('Search the book by title instead:',
              style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 24),
            TextField(
              controller: _manualTitle,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. Atomic Habits',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                suffixIcon: const Icon(Icons.search, color: Color(0xFFF59E0B)),
              ),
              onSubmitted: (v) => _openStore(v),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _openStore(_manualTitle.text),
              icon: const Icon(Icons.menu_book_rounded),
              label: const Text('FIND & BUY E-BOOK'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
            const SizedBox(height: 14),
            TextButton(onPressed: _reset, child: const Text('Back to Scanner', style: TextStyle(color: Colors.white38))),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildNoMatchView() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 72, color: Colors.white12),
            const SizedBox(height: 24),
            const Text("Couldn't identify the book",
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              'The scanned text didn\'t match any book.\n\n'
              'Tips:\n• Scan text-heavy pages (chapters, not cover)\n'
              '• Good lighting, no blur\n'
              '• Latin/European alphabet works best\n'
              '• Try 2–3 additional pages',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.7)),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => setState(() {
                _noMatch = false;
                _showTips = false;
                _status = '${_capturedPaths.length}/$_maxPages pages. Add more or identify.';
              }),
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('SCAN MORE PAGES'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: _reset,
              child: const Text('Start Over', style: TextStyle(color: Colors.white38)),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildResultView() {
    final book = _result!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _reset,
              child: Row(children: [
                const Icon(Icons.arrow_back, color: Colors.white54),
                const SizedBox(width: 8),
                const Text('Scan Again', style: TextStyle(color: Colors.white54, fontSize: 14)),
              ]),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: book.coverUrl != null
                        ? Image.network(book.coverUrl!, width: 76, height: 106, fit: BoxFit.cover)
                        : Container(width: 76, height: 106, color: AppTheme.surfaceHighlight,
                            child: const Icon(Icons.book, color: Colors.white24, size: 32)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(book.title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(book.author, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                        if (book.isbn != null) ...[
                          const SizedBox(height: 4),
                          Text('ISBN: ${book.isbn}', style: const TextStyle(color: Colors.white30, fontSize: 10, fontFamily: 'monospace')),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (book.description != null) ...[
              const SizedBox(height: 14),
              Text(
                book.description!.length > 300 ? '${book.description!.substring(0, 300)}…' : book.description!,
                style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.6)),
            ],

            const Spacer(),

            const Text('GET THE DIGITAL VERSION',
              style: TextStyle(color: Colors.white30, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _buyButton('Buy E-Book', Icons.menu_book_rounded, AppTheme.primary,
                () => _openStore('${book.title} ${book.author} ebook'))),
              const SizedBox(width: 12),
              Expanded(child: _buyButton('Audiobook', Icons.headphones, AppTheme.accent,
                () => _openStore('${book.title} ${book.author} audiobook'))),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buyButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ]),
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, Color bg, VoidCallback? onTap,
      {Color? textColor, Color? iconColor}) {
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
          child: Column(children: [
            Icon(icon, color: iconColor ?? Colors.white54, size: 20),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: textColor ?? Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
          ]),
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
    for (final corner in [
      [rect.topLeft, const Offset(cornerLen, 0), const Offset(0, cornerLen)],
      [rect.topRight, const Offset(-cornerLen, 0), const Offset(0, cornerLen)],
      [rect.bottomLeft, const Offset(cornerLen, 0), const Offset(0, -cornerLen)],
      [rect.bottomRight, const Offset(-cornerLen, 0), const Offset(0, -cornerLen)],
    ] as List<List<Offset>>) {
      canvas.drawLine(corner[0], corner[0] + corner[1], paint);
      canvas.drawLine(corner[0], corner[0] + corner[2], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
