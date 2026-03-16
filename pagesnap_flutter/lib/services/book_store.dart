import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';

class BookStore {
  static const String _prefix = 'book_';

  static Future<List<LocalBook>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    
    List<LocalBook> books = [];
    for (String key in keys) {
      final String? jsonStr = prefs.getString(key);
      if (jsonStr != null) {
        try {
          books.add(LocalBook.fromJson(jsonDecode(jsonStr)));
        } catch (e) {
          print('Error decoding book $key: $e');
        }
      }
    }
    
    books.sort((a, b) => b.lastRead.compareTo(a.lastRead));
    return books;
  }

  static Future<LocalBook?> getById(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('$_prefix$id');
    if (jsonStr == null) return null;
    try {
      return LocalBook.fromJson(jsonDecode(jsonStr));
    } catch (e) {
      return null;
    }
  }

  static Future<void> save(LocalBook book) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix${book.id}', jsonEncode(book.toJson()));
  }

  static Future<void> updateProgress(String id, int wordIndex, int totalWords) async {
    final book = await getById(id);
    if (book != null) {
      book.wordIndex = wordIndex;
      book.progress = totalWords > 0 ? wordIndex / totalWords : 0;
      book.lastRead = DateTime.now().millisecondsSinceEpoch;
      await save(book);
    }
  }

  static Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$id');
  }
}
