import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfExtractor {
  static Future<List<String>> extractNative(Uint8List bytes) async {
    try {
      PdfDocument document = PdfDocument(inputBytes: bytes);
      PdfTextExtractor extractor = PdfTextExtractor(document);
      
      String fullText = extractor.extractText();
      
      document.dispose();

      final words = fullText
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceAll(RegExp(r'[^\w\s.,!?''"-]'), '')
          .trim()
          .split(' ')
          .where((w) => w.isNotEmpty)
          .toList();

      if (words.length < 50) {
        throw Exception("Could not extract readable text from this PDF. It may be an image-based scan or heavily encoded.");
      }

      return words;
    } catch (e) {
      print('PDF Extraction Error: $e');
      throw Exception('Failed to extract text from PDF file. Native extraction requires plain text PDFs.');
    }
  }
}
