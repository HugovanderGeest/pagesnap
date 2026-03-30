import 'ocr_platform.dart'
    // ignore: uri_does_not_exist
    if (dart.library.html) 'ocr_platform_web.dart';

class OcrService {
  Future<String> extractTextFromImages(List<String> imagePaths) =>
      performOcr(imagePaths);

  void dispose() {}
}

