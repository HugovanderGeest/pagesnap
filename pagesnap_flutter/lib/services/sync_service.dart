import 'package:supabase_flutter/supabase_flutter.dart';
import 'book_store.dart';
import '../models/book.dart';

/// SyncService handles two-way sync of reading progress with Supabase.
/// Schema required in Supabase:
///
/// CREATE TABLE reading_progress (
///   id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
///   user_id     uuid REFERENCES auth.users(id) ON DELETE CASCADE,
///   book_id     text NOT NULL,
///   book_title  text,
///   word_index  int DEFAULT 0,
///   total_words int DEFAULT 0,
///   progress    float DEFAULT 0,
///   updated_at  timestamptz DEFAULT now(),
///   UNIQUE(user_id, book_id)
/// );
/// ALTER TABLE reading_progress ENABLE ROW LEVEL SECURITY;
/// CREATE POLICY "Users can manage their own progress"
///   ON reading_progress FOR ALL USING (auth.uid() = user_id);

class SyncService {
  static final _client = Supabase.instance.client;

  static String? get _userId => _client.auth.currentUser?.id;

  /// Push local progress for a single book to Supabase.
  static Future<void> pushBook(LocalBook book) async {
    final uid = _userId;
    if (uid == null) return;

    await _client.from('reading_progress').upsert({
      'user_id': uid,
      'book_id': book.id,
      'book_title': book.title,
      'word_index': book.wordIndex,
      'total_words': book.totalWords,
      'progress': book.progress,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id, book_id');
  }

  /// Pull all remote progress and merge with local library.
  /// Remote wins if its updated_at is newer (we timestamp locally).
  static Future<void> pullAndMerge() async {
    final uid = _userId;
    if (uid == null) return;

    final remote = await _client
        .from('reading_progress')
        .select()
        .eq('user_id', uid) as List<dynamic>;

    for (final row in remote) {
      final bookId = row['book_id'] as String;
      final remoteProgress = (row['progress'] as num).toDouble();
      final remoteIndex = row['word_index'] as int;

      final local = await BookStore.getById(bookId);
      if (local == null) continue;

      // Remote wins if it has higher progress (e.g. read on another device)
      if (remoteProgress > local.progress) {
        local.progress = remoteProgress;
        local.wordIndex = remoteIndex;
        await BookStore.save(local);
      }
    }
  }

  /// Push all local books to Supabase at once (e.g. on app launch).
  static Future<void> pushAll() async {
    if (_userId == null) return;
    final books = await BookStore.getAll();
    for (final book in books) {
      await pushBook(book);
    }
  }
}
