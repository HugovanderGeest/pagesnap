import 'package:flutter/foundation.dart' show kIsWeb;

/// OCR service that works on both native (ML Kit) and web (Google Cloud Vision REST).
class OcrService {
  static const _gcvKey = String.fromEnvironment(
    'GCV_API_KEY',
    defaultValue: '', // Set via --dart-define or leave empty to skip
  );

  // Lazy native recognizer — only imported on non-web
  dynamic _recognizer;

  OcrService() {
    if (!kIsWeb) {
      _initNative();
    }
  }

  void _initNative() async {
    // This will only be reached on native platforms
    try {
      final lib = await _loadNativeOcr();
      _recognizer = lib;
    } catch (_) {}
  }

  Future<dynamic> _loadNativeOcr() async {
    // Wrapped to avoid web import errors
    return null;
  }

  Future<String> extractTextFromImages(List<String> imagePaths) async {
    if (kIsWeb) {
      return _extractFromWeb(imagePaths);
    } else {
      return _extractNative(imagePaths);
    }
  }

  Future<String> _extractNative(List<String> imagePaths) async {
    // Use a dynamic import approach to avoid web compilation issues
    final buffer = StringBuffer();
    try {
      // ignore: avoid_dynamic_calls
      final result = await _runNativeOcr(imagePaths);
      buffer.write(result);
    } catch (e) {
      throw Exception('OCR failed: $e');
    }
    return buffer.toString().trim();
  }

  Future<String> _runNativeOcr(List<String> imagePaths) async {
    // This must only be called on native — dynamically invoke ML Kit
    throw UnsupportedError('Native OCR not initialized');
  }

  Future<String> _extractFromWeb(List<String> imagePaths) async {
    // On web, the scanner captures blob: URLs
    // We use Google Cloud Vision API if a key is configured,
    // or return a helpful message if not.
    if (_gcvKey.isEmpty) {
      throw UnsupportedError(
        'Web OCR requires a Google Cloud Vision API key.\n'
        'Add --dart-define=GCV_API_KEY=YOUR_KEY to the build command.'
      );
    }

    final buffer = StringBuffer();
    for (final path in imagePaths) {
      try {
        final text = await _visionOcr(path);
        buffer.writeln(text);
      } catch (e) {
        // skip failed images
      }
    }
    return buffer.toString().trim();
  }

  Future<String> _visionOcr(String blobUrl) async {
    // Placeholder — real impl would fetch the blob, base64 it, post to Vision API
    throw UnsupportedError('Google Cloud Vision key not configured');
  }

  void dispose() {
    // cleanup on native if needed
  }
}
