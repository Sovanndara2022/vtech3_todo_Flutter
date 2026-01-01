import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/todo_item.dart';
import '../repository/todo_repository.dart';
import '../util/text_norm.dart';

// Central state manager for todos.
// Handles business logic, optimistic updates, and filtering.
class TodoStore extends ChangeNotifier {
  final TodoRepository _repo;
  final _uuid = const Uuid();

 // Local cache of all todos (keyed by id)
  final Map<String, TodoItem> _all = {};
  // Subscription to repository change stream
  StreamSubscription<TodoChange>? _sub;

 
  bool _loading = true;
  String _filter = '';
  String? _editingId;

  TodoStore(this._repo);
// Loading state during initialization
  bool get isLoading => _loading;
    // Current search/filter text
  String get filter => _filter;
  // ID of the todo currently being edited
  String? get editingId => _editingId;

// All todos sorted by creation time
  List<TodoItem> get allTodos {
    final list = _all.values.toList();
    list.sort((a, b) => (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));
    return list;
  }

 // Todos filtered by search query
  List<TodoItem> get visibleTodos {
    final q = _filter.trim();
    if (q.isEmpty) return allTodos;

    final lower = q.toLowerCase();
    return allTodos.where((t) => t.text.toLowerCase().contains(lower)).toList();
  }

 // Currently edited todo item (if any)
  TodoItem? get editingItem => _editingId == null ? null : _all[_editingId!];

 // Initialize store, load data, and start listening to repo changes
  Future<void> init() async {
    try {
      await _repo.init();

      final items = await _repo.fetchAll();
      _all
        ..clear()
        ..addEntries(items.map((e) => MapEntry(e.id, e)));

      _sub = _repo.changes().listen(_applyRemoteChange);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Update search filter
  void setFilter(String value) {
    _filter = value;
    notifyListeners();
  }

// Start editing an existing todo
  void startEdit(String id) {
    if (!_all.containsKey(id)) return;
    _editingId = id;
    notifyListeners();
  }

 // Cancel current edit session
  void cancelEdit() {
    _editingId = null;
    notifyListeners();
  }

// Create a new todo or update an existing one
  // Returns an error message if validation fails
  Future<String?> submitText(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty) return 'Todo cannot be empty.';

    final normalized = normalizeTodoText(text);
    final isEditing = _editingId != null;

// Prevent duplicate todos
    final duplicateExists = _all.values.any((t) {
      if (isEditing && t.id == _editingId) return false;
      return normalizeTodoText(t.text) == normalized;
    });

    if (duplicateExists) return 'Duplicate todo is not allowed.';

 // Editing existing todo
    if (isEditing) {
      final id = _editingId!;
      final current = _all[id];
      if (current == null) return 'Item no longer exists.';

      final previous = current;
      final updated = current.copyWith(text: text, updatedAt: DateTime.now());

      _optimisticUpsert(updated);
      _editingId = null;
      notifyListeners();

      try {
        await _repo.upsert(updated);
        return null;
      } catch (e) {
        _optimisticUpsert(previous);
        notifyListeners();
        return 'Failed to update: $e';
      }
    }

 // Creating new todo
    final now = DateTime.now();
    final item = TodoItem(
      id: _uuid.v4(),
      text: text,
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
    );

    _optimisticUpsert(item);
    notifyListeners();

    try {
      await _repo.upsert(item);
      return null;
    } catch (e) {
      _all.remove(item.id);
      notifyListeners();
      return 'Failed to save: $e';
    }
  }

 // Remove a todo with optimistic rollback
  Future<void> remove(String id) async {
    final previous = _all[id];
    if (previous == null) return;

    if (_editingId == id) _editingId = null;

    _all.remove(id);
    notifyListeners();

    try {
      await _repo.deleteById(id);
    } catch (e) {
      _all[id] = previous;
      notifyListeners();
      rethrow;
    }
  }

// Toggle completion state with optimistic update
  Future<void> toggleComplete(String id) async {
    final previous = _all[id];
    if (previous == null) return;

    final updated = previous.copyWith(
      isCompleted: !previous.isCompleted,
      updatedAt: DateTime.now(),
    );

    _optimisticUpsert(updated);
    notifyListeners();

    try {
      await _repo.upsert(updated);
    } catch (e) {
      _optimisticUpsert(previous);
      notifyListeners();
      rethrow;
    }
  }

// Apply optimistic change locally
  void _optimisticUpsert(TodoItem item) {
    _all[item.id] = item;
  }

  // Handle realtime updates from repository
  void _applyRemoteChange(TodoChange change) {
    switch (change) {
      case TodoUpserted():
        _all[change.item.id] = change.item;
        notifyListeners();
      case TodoDeleted():
        _all.remove(change.id);
        if (_editingId == change.id) _editingId = null;
        notifyListeners();
    }
  }

// Dispose store and cleanup resources
  @override
  void dispose() {
    unawaited(close());
    super.dispose();
  }

// Close subscriptions and repository
  Future<void> close() async {
    await _sub?.cancel();
    _sub = null;
    await _repo.dispose();
  }
}
