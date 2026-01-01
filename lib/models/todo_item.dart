// Used for local state and API communication
class TodoItem {
  final String id;
  final String text;
  final bool isCompleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;


  // Base constructor
  const TodoItem({
    required this.id,
    required this.text,
    required this.isCompleted,
    this.createdAt,
    this.updatedAt,
  });

 // Creates a new TodoItem with updated values
  // Commonly used when updating state immutably
  TodoItem copyWith({
    String? id,
    String? text,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TodoItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

// Convert TodoItem into JSON format
  // Used when sending data to API or saving locally
  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'is_completed': isCompleted,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  static TodoItem fromJson(Map<String, dynamic> json) {
    DateTime? parseTs(dynamic v) => v is String ? DateTime.tryParse(v) : null;

// Create TodoItem instance from JSON response
  // Safely parses date fields if they exist
    return TodoItem(
      id: json['id'] as String,
      text: json['text'] as String,
      isCompleted: (json['is_completed'] as bool?) ?? false,
      createdAt: parseTs(json['created_at']),
      updatedAt: parseTs(json['updated_at']),
    );
  }
}

