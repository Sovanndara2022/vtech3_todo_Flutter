// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'state/app_controller.dart';
import 'state/todo_store.dart';

// Application entry point
Future<void> main() async {
    // Ensure Flutter bindings are ready before async work
  WidgetsFlutterBinding.ensureInitialized();
   // Load environment variables (.env)
  await dotenv.load(fileName: '.env');

 // Initialize app-level controller
  final app = AppController();
  await app.init();

  runApp(
     // Provide AppController to the widget tree
    ChangeNotifierProvider.value(
      value: app,
      child: Builder(
        builder: (context) {
          final controller = context.watch<AppController>();

    // Show loading UI while app is booting
          if (controller.isLoading) {
            return const MaterialApp(
              home: Scaffold(body: Center(child: CircularProgressIndicator())),
            );
          }

          // When switching mode we swap the TodoStore instance.
          // Use a key so Flutter/Provider fully rewire listeners to the new store.
          return ChangeNotifierProvider<TodoStore>.value(
            key: ValueKey('${controller.mode}-${controller.store.hashCode}'),
            value: controller.store,
            child: const VtechTodoApp(),
          );
        },
      ),
    ),
  );
}
