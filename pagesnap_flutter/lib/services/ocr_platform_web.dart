// ignore: avoid_web_libraries_in_flutter, uri_does_not_exist
import 'dart:js_util' as js_util;
// ignore: avoid_web_libraries_in_flutter, uri_does_not_exist
import 'dart:js' as js;

/// Web OCR — calls window._runOcr() (Tesseract.js, loaded in index.html).
Future<String> performOcr(List<String> imagePaths) async {
  final runOcr = js.context['_runOcr'];
  if (runOcr == null) {
    throw UnsupportedError('Tesseract.js not loaded — check index.html.');
  }

  final buffer = StringBuffer();
  for (final path in imagePaths) {
    try {
      final text = await js_util.promiseToFuture<String>(
        js_util.callMethod(runOcr, 'call', [js.context, path]),
      );
      if (text.trim().isNotEmpty) buffer.writeln(text.trim());
    } catch (_) {
      // skip failed image
    }
  }

  final result = buffer.toString().trim();
  if (result.isEmpty) {
    throw Exception('No text could be detected. Try better lighting and hold the phone steady.');
  }
  return result;
}
