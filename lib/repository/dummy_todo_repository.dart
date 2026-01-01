import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/todo_item.dart';
import 'todo_repository.dart';

// Simple local "dummy" repository:
// - stores todos in memory
// - persists them into SharedPreferences so they survive app restart
//
// Useful for demos / offline mode / no-backend testing.
class DummyTodoRepository implements TodoRepository {
  // Storage key for SharedPreferences 
  static const _prefsKey = 'vtech_todos_v1';

// In-memory cache (fast reads)
  final Map<String, TodoItem> _items = {};
  final _controller = StreamController<TodoChange>.broadcast();
  SharedPreferences? _prefs;

  // Initialize repository and load saved todos
  @override
  Future<void> init() async {
    // SharedPreferences is async, so we grab it once and reuse.
    _prefs = await SharedPreferences.getInstance();
    await _loadFromPrefs();
  }

 // Fetch all todos (sorted by creation time)
  @override
  Future<List<TodoItem>> fetchAll() async {
    // Return a sorted list so UI is stable/predictable.
    // Older items appear first (or DateTime(0) if createdAt is missing).
    final list = _items.values.toList();
    list.sort((a, b) => (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));
    return list;
  }

 // Insert or update a todo item
  @override
  Future<void> upsert(TodoItem item) async {
    _items[item.id] = item;
    _controller.add(TodoUpserted(item));
    await _saveToPrefs();
  }

// Delete a todo by its ID
  @override
  Future<void> deleteById(String id) async {
    _items.remove(id);
    _controller.add(TodoDeleted(id));
    await _saveToPrefs();
  }

 // Stream of todo changes for reactive updates
  @override
  Stream<TodoChange> changes() => _controller.stream;

 // Clean up resources
  @override
  Future<void> dispose() async {
    await _controller.close();
  }

// Load todos from SharedPreferences into memory
  Future<void> _loadFromPrefs() async {
    final prefs = _prefs;
    if (prefs == null) return;

    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return;

    final decoded = jsonDecode(raw);
    if (decoded is! List) return;

    _items
      ..clear()
      ..addEntries(
        decoded
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .map((m) => TodoItem.fromJson(m))
            .map((t) => MapEntry(t.id, t)),
      );
  }

// Save current todos into SharedPreferences
  Future<void> _saveToPrefs() async {
    final prefs = _prefs;
    if (prefs == null) return;

    final list = _items.values
        .map((t) => t.toJson())
        .toList()
      ..sort((a, b) {
        final ca = a['created_at'] as String?;
        final cb = b['created_at'] as String?;
        return (ca ?? '').compareTo(cb ?? '');
      });

    await prefs.setString(_prefsKey, jsonEncode(list));
  }
}