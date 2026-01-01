import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_controller.dart';
import '../state/todo_store.dart';
import 'widgets/todo_input.dart';
import 'widgets/todo_tile.dart';

// Main screen for displaying and managing todos
class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
   // Controller for the todo input field
  final _controller = TextEditingController();
  // Tracks the last editing todo to sync text correctly
  String? _lastEditingId;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Sync input text when switching between edit targets
  void _syncEditText(TodoStore store) {
    final editingId = store.editingId;
    if (editingId == _lastEditingId) return;

    _lastEditingId = editingId;

    final item = store.editingItem;
    if (item != null) {
      _controller.text = item.text;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    } else {
      _controller.clear();
    }
  }

 // Handle todo submission and show validation errors
  Future<void> _submit(BuildContext context, String text) async {
    final store = context.read<TodoStore>();
    final error = await store.submitText(text);

    if (error != null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    _controller.clear();
    store.setFilter('');
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final store = context.watch<TodoStore>();

 // Keep input field in sync with editing state
    _syncEditText(store);

    final visible = store.visibleTodos;
    final isEditing = store.editingId != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('VTech - Todo'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                const Text('Dummy'),
                 // Toggle between dummy and live (Supabase) modes
                Switch(
  value: app.mode == AppMode.live,
  onChanged: (v) async {
    final ok = await app.setMode(v ? AppMode.live : AppMode.dummy);
    if (!ok && context.mounted) {
      final msg = app.lastError ??
          'Live mode failed. Check SUPABASE_URL / SUPABASE_ANON_KEY, and that public.todos exists.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  },
),
                const Text('Live'),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: store.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                     // Todo input (add / edit)
                  TodoInput(
                    controller: _controller,
                    isEditing: isEditing,
                    onChangedWhenAdding: store.setFilter,
                    onSubmitted: (v) => _submit(context, v),
                    onCancelEdit: () {
                      store.cancelEdit();
                      _controller.clear();
                    },
                  ),
                  const SizedBox(height: 12),
                     // Filter label
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      store.filter.trim().isEmpty ? 'All todos' : 'Filtered by: "${store.filter}"',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                    // Todo list
                  Expanded(
                    child: visible.isEmpty && store.filter.trim().isNotEmpty
                        ? const Center(child: Text('No result. Create a new one instead'))
                        : ListView.builder(
                            itemCount: visible.length,
                            itemBuilder: (context, i) {
                              final item = visible[i];
                              return TodoTile(
                                item: item,
                                onEdit: () {
                                  store.startEdit(item.id);
                                  store.setFilter('');
                                },
                                onRemove: () async {
                                  try {
                                    await store.remove(item.id);
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to remove: $e')),
                                    );
                                  }
                                },
                                onToggleComplete: () async {
                                  try {
                                    await store.toggleComplete(item.id);
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to update: $e')),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}