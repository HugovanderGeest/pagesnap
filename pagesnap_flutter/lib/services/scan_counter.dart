import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tracks total pages scanned so we can enforce the free-tier limit.
/// Logged-in users bypass the limit entirely.
class ScanCounter {
  static const String _key = 'total_pages_scanned';
  static const int freeLimit = 10;

  static Future<int> getCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key) ?? 0;
  }

  static Future<void> increment({int pages = 1}) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_key) ?? 0;
    await prefs.setInt(_key, current + pages);
  }

  static bool get isLoggedIn =>
      Supabase.instance.client.auth.currentSession != null;
}
