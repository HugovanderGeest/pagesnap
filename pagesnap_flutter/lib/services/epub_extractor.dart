import 'dart:typed_data';
import 'package:epubx/epubx.dart';
import 'package:html/parser.dart' show parse;

class EpubExtractor {
  static Future<List<String>> extractNative(Uint8List bytes) async {
    try {
      EpubBook epubBook = await EpubReader.readBook(bytes);

      String fullText = '';
      
      // Extract from chapters
      if (epubBook.Chapters != null) {
        for (var chapter in epubBook.Chapters!) {
          fullText += '${_extractTextFromHtml(chapter.HtmlContent)} \n';
          
          if (chapter.SubChapters != null) {
            for (var subChapter in chapter.SubChapters!) {
               fullText += '${_extractTextFromHtml(subChapter.HtmlContent)} \n';
            }
          }
        }
      }

      // If Chapters are somehow empty, extract from raw HTML files
      if (fullText.trim().isEmpty && epubBook.Content?.Html != null) {
        for (var htmlContent in epubBook.Content!.Html!.values) {
           fullText += '${_extractTextFromHtml(htmlContent.Content)} \n';
        }
      }

      final words = fullText
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceAll(RegExp(r'[^\w\s.,!?''"-]'), '')
          .trim()
          .split(' ')
          .where((w) => w.isNotEmpty)
          .toList();

      return words;
    } catch (e) {
      print('EPUB Extraction Error: $e');
      throw Exception('Failed to extract text from EPUB file');
    }
  }

  static String _extractTextFromHtml(String? htmlString) {
    if (htmlString == null) return '';
    final document = parse(htmlString);
    final text = document.body?.text ?? '';
    return text.replaceAll('\n', ' ').replaceAll('\r', '');
  }
}
