import 'package:flutter/material.dart';

// Reusable input widget for adding or editing a todo
class TodoInput extends StatelessWidget {
  // Controls the text field value
  final TextEditingController controller;
   // Indicates whether the user is editing an existing todo
  final bool isEditing;
   // Called when text changes while adding a new todo
  final ValueChanged<String> onChangedWhenAdding;
   // Called when user submits the todo (Enter or button)
  final ValueChanged<String> onSubmitted;
   // Cancels edit mode
  final VoidCallback onCancelEdit;

  const TodoInput({
    super.key,
    required this.controller,
    required this.isEditing,
    required this.onChangedWhenAdding,
    required this.onSubmitted,
    required this.onCancelEdit,
  });

 // Builds the input field and action buttons
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: isEditing ? 'Edit todo' : 'Add todo',
            hintText: 'Type and press Enter',
            border: const OutlineInputBorder(),
          ),
          onChanged: (v) {
            if (!isEditing) onChangedWhenAdding(v);
          },
          onSubmitted: onSubmitted,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: () => onSubmitted(controller.text),
                child: Text(isEditing ? 'Update' : 'Add'),
              ),
            ),
            if (isEditing) ...[
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: onCancelEdit,
                child: const Text('Cancel'),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

