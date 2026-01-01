// test/widget_test.dart
//
// Why: Flutter template test expects MyApp/counter. Our challenge app is VtechTodoApp.
// This test validates the core requirement: Enter key adds a todo.


import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:vtech_todo/app.dart';
import 'package:vtech_todo/repository/dummy_todo_repository.dart';
import 'package:vtech_todo/state/todo_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpApp(WidgetTester tester) async {
    final store = TodoStore(DummyTodoRepository());
    await store.init();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: store,
        child: const VtechTodoApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Enter key adds a new todo item', (tester) async {
    await pumpApp(tester);

    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);

    await tester.tap(textField);
    await tester.enterText(textField, 'Buy milk');

    // Why: triggers TextField.onSubmitted (Enter/Done on keyboard)
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Buy milk'), findsOneWidget);
  });

  testWidgets('Empty todo is rejected (snack)', (tester) async {
    await pumpApp(tester);

    final textField = find.byType(TextField);
    await tester.tap(textField);
    await tester.enterText(textField, '   ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Todo cannot be empty.'), findsOneWidget);
  });

  testWidgets('Duplicate todo is rejected (snack)', (tester) async {
    await pumpApp(tester);

    final textField = find.byType(TextField);

    await tester.tap(textField);
    await tester.enterText(textField, 'Read book');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    await tester.tap(textField);
    await tester.enterText(textField, '  read BOOK  ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Duplicate todo is not allowed.'), findsOneWidget);
  });
}