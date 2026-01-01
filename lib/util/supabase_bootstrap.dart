// FILE: lib/util/supabase_bootstrap.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseBootstrap {
  static SupabaseClient? _client;

  static Future<SupabaseClient> ensureInitialized({
    required String url,
    required String anonKey,
  }) async {
    if (_client != null) return _client!;

    await Supabase.initialize(url: url, anonKey: anonKey);
    _client = Supabase.instance.client;
    return _client!;
  }
}
