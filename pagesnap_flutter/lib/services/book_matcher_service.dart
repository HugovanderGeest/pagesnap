import 'dart:convert';
import 'package:http/http.dart' as http;

class BookMatch {
  final String title;
  final String author;
  final String? coverUrl;
  final String? isbn;
  final String? description;
  final String? googleBooksId;

  BookMatch({
    required this.title,
    required this.author,
    this.coverUrl,
    this.isbn,
    this.description,
    this.googleBooksId,
  });
}

class BookMatcherService {
  static const _apiBase = 'https://www.googleapis.com/books/v1/volumes';

  /// Extracts a short meaningful phrase from raw OCR text and queries Google Books API.
  /// Returns the best matching book or null if nothing is found.
  Future<BookMatch?> matchBook(String rawText) async {
    final phrase = _extractSearchPhrase(rawText);
    if (phrase.isEmpty) return null;

    final uri = Uri.parse('$_apiBase?q=${Uri.encodeQueryComponent(phrase)}&maxResults=5');
    final response = await http.get(uri);

    if (response.statusCode != 200) return null;

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final items = json['items'] as List<dynamic>?;
    if (items == null || items.isEmpty) return null;

    final best = items.first as Map<String, dynamic>;
    final info = best['volumeInfo'] as Map<String, dynamic>;
    final imageLinks = info['imageLinks'] as Map<String, dynamic>?;
    final identifiers = info['industryIdentifiers'] as List<dynamic>?;

    String? isbn;
    if (identifiers != null) {
      final isbnEntry = identifiers.firstWhere(
        (e) => (e as Map)['type'] == 'ISBN_13',
        orElse: () => null,
      );
      isbn = isbnEntry != null ? (isbnEntry as Map)['identifier'] as String? : null;
    }

    return BookMatch(
      title: info['title'] as String? ?? 'Unknown Title',
      author: (info['authors'] as List<dynamic>?)?.join(', ') ?? 'Unknown Author',
      coverUrl: imageLinks != null
          ? (imageLinks['thumbnail'] as String?)?.replaceAll('http:', 'https:')
          : null,
      isbn: isbn,
      description: info['description'] as String?,
      googleBooksId: best['id'] as String?,
    );
  }

  /// Extracts a high-signal phrase from raw OCR text (a unique sentence cluster).
  String _extractSearchPhrase(String text) {
    // Split text into sentences; pick a mid-section sentence likely to be prose
    final sentences = text
        .split(RegExp(r'[.!?]+'))
        .map((s) => s.trim())
        .where((s) => s.split(' ').length >= 5 && s.split(' ').length <= 15)
        .toList();

    if (sentences.isEmpty) {
      // Fallback: take the first 60 chars of text
      return text.length > 60 ? text.substring(0, 60) : text;
    }

    // Use a middle sentence for best specificity
    final mid = sentences[sentences.length ~/ 2];
    return '"$mid"'; // wrap in quotes for exact phrase search
  }
}
