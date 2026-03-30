/// Stub for native platforms — camera OCR via Tesseract.js only works on web.
Future<String> performOcr(List<String> imagePaths) async {
  throw UnsupportedError('Camera OCR only works on web for now.');
}
