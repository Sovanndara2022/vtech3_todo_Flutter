import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repository/dummy_todo_repository.dart';
import '../repository/supabase_todo_repository.dart';
import '../repository/todo_repository.dart';
import '../util/supabase_bootstrap.dart';
import 'todo_store.dart';

// Defines which backend mode the app is running in
enum AppMode { dummy, live }


// Central app-level controller:
// - manages app mode (dummy vs live)
// - boots repositories
// - exposes TodoStore to the UI
class AppController extends ChangeNotifier {
  static const _prefsModeKey = 'vtech_mode_v1';

  TodoStore? _store;
  AppMode _mode = AppMode.dummy;
  bool _loading = true;
  String? _lastError;

// Current active TodoStore
  TodoStore get store => _store!;
  // Current app mode
  AppMode get mode => _mode;
  // Indicates app boot / switching state
  bool get isLoading => _loading;
  // Last boot or switch error (if any)
  String? get lastError => _lastError;

 // Initial app startup logic
  Future<void> init() async {
    _loading = true;
    _lastError = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final saved = (prefs.getString(_prefsModeKey) ?? '').trim();

  // Resolve mode from saved preference or environment
    _mode = saved.isNotEmpty
        ? (saved == 'live' ? AppMode.live : AppMode.dummy)
        : _modeFromEnv();

 // Try to boot selected mode, fallback to dummy if needed
    final ok = await _tryBoot(_mode);
    if (!ok && _mode != AppMode.dummy) {
      _mode = AppMode.dummy;
      await _tryBoot(_mode);
    }

    _loading = false;
    notifyListeners();
  }

// Switch app mode at runtime
  Future<bool> setMode(AppMode next) async {
    if (next == _mode) return true;

    _lastError = null;
    final ok = await _tryBoot(next);
    if (!ok) {
      notifyListeners();
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsModeKey, next == AppMode.live ? 'live' : 'dummy');

    _mode = next;
    notifyListeners();
    return true;
  }

 // Resolve app mode from .env configuration
  AppMode _modeFromEnv() {
    final raw = (dotenv.env['TODO_MODE'] ?? '').trim().toLowerCase();
    return raw == 'live' ? AppMode.live : AppMode.dummy;
  }

// Safe boot wrapper with error handling
  Future<bool> _tryBoot(AppMode mode) async {
    try {
      return await _boot(mode);
    } catch (e, st) {
      _lastError = e.toString();
      debugPrint('Boot failed for $mode: $e\n$st');
      return false;
    }
  }

// Boot the app with the selected repository
  Future<bool> _boot(AppMode mode) async {
    final repo = await _buildRepo(mode);
    if (repo == null) {
      _lastError = 'Missing SUPABASE_URL / SUPABASE_ANON_KEY in .env';
      return false;
    }

    final nextStore = TodoStore(repo);
    await nextStore.init();

    final old = _store;
    _store = nextStore;

    await old?.close();
    return true;
  }

 // Build repository based on selected app mode
  Future<TodoRepository?> _buildRepo(AppMode mode) async {
    if (mode == AppMode.dummy) return DummyTodoRepository();

 // Try multiple env keys for flexibility (Flutter / Next / etc.)
    String envFirst(List<String> keys) {
      for (final k in keys) {
        final v = (dotenv.env[k] ?? '').trim();
        if (v.isNotEmpty) return v;
      }
      return '';
    }

    final url = envFirst(['SUPABASE_URL', 'NEXT_PUBLIC_SUPABASE_URL']);
    final key = envFirst(['SUPABASE_ANON_KEY', 'NEXT_PUBLIC_SUPABASE_ANON_KEY']);
    if (url.isEmpty || key.isEmpty) return null;

    final client = await SupabaseBootstrap.ensureInitialized(url: url, anonKey: key);
    return SupabaseTodoRepository(client);
  }
}
