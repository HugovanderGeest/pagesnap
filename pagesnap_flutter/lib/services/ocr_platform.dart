import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

Future<String> performOcr(List<String> imagePaths) async {
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final buffer = StringBuffer();
  for (final path in imagePaths) {
    try {
      final inputImage = InputImage.fromFilePath(path);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      if (recognizedText.text.trim().isNotEmpty) {
        buffer.writeln(recognizedText.text.trim());
      }
    } catch (_) {
      // skip
    }
  }
  textRecognizer.close();
  
  final result = buffer.toString().trim();
  if (result.isEmpty) {
    throw Exception('No text could be detected. Try better lighting and hold the phone steady.');
  }
  return result;
}
