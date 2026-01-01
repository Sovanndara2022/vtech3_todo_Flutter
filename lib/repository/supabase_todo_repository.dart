import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/todo_item.dart';
import 'todo_repository.dart';

// Todo repository backed by Supabase (Postgres + Realtime)
class SupabaseTodoRepository implements TodoRepository {
   // Supabase table name
  static const String _table = 'todos';


  final SupabaseClient _client;
  // Stream controller for emitting todo changes to the app
  final _controller = StreamController<TodoChange>.broadcast();
  // Realtime channel subscription
  RealtimeChannel? _channel;

  SupabaseTodoRepository(this._client);

// Initialize realtime listener for database changes
  @override
  Future<void> init() async {
    _channel = _client
        .channel('public:$_table')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: _table,
          callback: (payload) {
            final event = payload.eventType;
          // Handle delete events
            if (event == PostgresChangeEvent.delete) {
              final oldRecord = payload.oldRecord;
              final id = (oldRecord['id'] as String?) ?? '';
              if (id.isNotEmpty) _controller.add(TodoDeleted(id));
              return;
            }
           // Handle insert & update events
            final record = payload.newRecord;
            final item = _fromRecord(record);
            if (item != null) _controller.add(TodoUpserted(item));
          },
        )
        .subscribe();
  }
   // Fetch all todos from Supabase
  @override
  Future<List<TodoItem>> fetchAll() async {
    final res = await _client
        .from(_table)
        .select()
        .order('created_at', ascending: true);

    final items = <TodoItem>[];
    for (final row in res) {
      final item = _fromRecord(row);
      if (item != null) items.add(item);
    }
    return items;
  }
  // Insert or update a todo in Supabase
  @override
  Future<void> upsert(TodoItem item) async {
    await _client.from(_table).upsert({
      'id': item.id,
      'text': item.text,
      'is_completed': item.isCompleted,
    });
  }
// Delete a todo by ID
  @override
  Future<void> deleteById(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }
 // Stream of realtime todo changes
  @override
  Stream<TodoChange> changes() => _controller.stream;
// Dispose realtime channel and stream controller
  @override
  Future<void> dispose() async {
    if (_channel != null) {
      await _client.removeChannel(_channel!);
    }
    await _controller.close();
  }
  // Convert Supabase record into TodoItem model
  TodoItem? _fromRecord(Map<String, dynamic> record) {
    final id = record['id']?.toString() ?? '';
    final text = record['text']?.toString() ?? '';
    if (id.isEmpty || text.isEmpty) return null;

    final isCompleted = (record['is_completed'] as bool?) ?? false;
    final createdAtRaw = record['created_at'];
    final updatedAtRaw = record['updated_at'];

    DateTime? parseTs(dynamic v) {
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    return TodoItem(
      id: id,
      text: text,
      isCompleted: isCompleted,
      createdAt: parseTs(createdAtRaw),
      updatedAt: parseTs(updatedAtRaw),
    );
  }
}
