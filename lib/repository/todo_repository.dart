import '../models/todo_item.dart';

// Base class for representing todo-related changes
// Used to notify the app about data updates
sealed class TodoChange {
  const TodoChange();
}

// Emitted when a todo is added or updated
class TodoUpserted extends TodoChange {
  final TodoItem item;
  const TodoUpserted(this.item);
}

// Emitted when a todo is deleted
class TodoDeleted extends TodoChange {
  final String id;
  const TodoDeleted(this.id);
}

// Contract for todo data sources (local or remote)
// Allows switching implementations without changing the app logic

abstract interface class TodoRepository {
  // Initialize the repository (connections, local storage, etc.)

  Future<void> init();
   // Fetch all todos
  Future<List<TodoItem>> fetchAll();
 // Create or update a todo
  Future<void> upsert(TodoItem item);
   // Delete a todo by ID
  Future<void> deleteById(String id);
  // Stream of todo changes for reactive updates
  Stream<TodoChange> changes();
   // Release resources when no longer needed
  Future<void> dispose();
}
