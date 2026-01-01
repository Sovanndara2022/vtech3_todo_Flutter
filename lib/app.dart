import 'package:flutter/material.dart';
import 'ui/todo_page.dart';
// Root widget of the VTech Todo application
class VtechTodoApp extends StatelessWidget {
  const VtechTodoApp({super.key});
 // Configures app-level theme and initial route
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VTech Todo',
      theme: ThemeData(useMaterial3: true),
      home: const TodoPage(),
    );
  }
}
