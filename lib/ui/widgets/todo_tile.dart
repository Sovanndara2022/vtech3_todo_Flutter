import 'package:flutter/material.dart';

import '../../models/todo_item.dart';

// UI tile representing a single todo item
class TodoTile extends StatelessWidget {
   // Todo data to display
  final TodoItem item;
  // Trigger edit mode
  final VoidCallback onEdit;
   // Remove this todo
  final VoidCallback onRemove;
  // Toggle completed state
  final VoidCallback onToggleComplete;

  const TodoTile({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onRemove,
    required this.onToggleComplete,
  });

 // Builds a card with todo info and actions
  @override
  Widget build(BuildContext context) {
    final style = item.isCompleted
        ? const TextStyle(decoration: TextDecoration.lineThrough)
        : null;

    return Card(
      child: ListTile(
        title: Text(item.text, style: style),
        subtitle: Text(item.isCompleted ? 'Completed' : 'Incomplete'),
        trailing: Wrap(
          spacing: 8,
          children: [
            TextButton(
              onPressed: onToggleComplete,
              child: Text(item.isCompleted ? 'Mark Incomplete' : 'Mark Complete'),
            ),
            IconButton(
              tooltip: 'Edit',
              onPressed: onEdit,
              icon: const Icon(Icons.edit),
            ),
            IconButton(
              tooltip: 'Remove',
              onPressed: onRemove,
              icon: const Icon(Icons.delete),
            ),
          ],
        ),
      ),
    );
  }
}
