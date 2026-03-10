// Basic widget test verifying authentication screen is shown.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:todo_task/main.dart';
import 'package:todo_task/services/todo_service.dart';
import 'package:todo_task/models/todo_item.dart';
import 'package:todo_task/providers/todo_provider.dart';
import 'package:todo_task/screens/todo_screen.dart';

// Fake service class placed at top‑level since Dart doesn't allow nested classes
class FakeService extends TodoService {
  FakeService() : super(databaseUrl: '');

  @override
  Future<List<TodoItem>> fetchTodos(String userId, String authToken) async => [TodoItem(id: 'a', text: 'Sample task')];

  @override
  Future<void> deleteTodo(String userId, String authToken, String id) async {}
  @override
  Future<void> addTodo(String userId, String authToken, TodoItem item) async {}
  @override
  Future<void> updateTodo(String userId, String authToken, TodoItem item) async {}
}

void main() {
  testWidgets('App starts on authentication screen', (WidgetTester tester) async {
    await tester.pumpWidget(const TodoApp());

    // Authentication screen should be visible (look for header & input fields)
    expect(find.text('TODO Task'), findsOneWidget);
    expect(find.byType(TextFormField), findsWidgets);

    // Google button should be present
    expect(find.text('Google'), findsOneWidget);
  });

  testWidgets('Adding and deleting a todo shows delete controls', (WidgetTester tester) async {
    // use fake service defined above
    final provider = TodoProvider(todoService: FakeService(), userId: 'u', authToken: 't');
    // preload todos so the widget doesn't need to fetch asynchronously
    await provider.loadTodos();

    await tester.pumpWidget(
      ChangeNotifierProvider<TodoProvider>.value(
        value: provider,
        child: const MaterialApp(home: TodoScreen()),
      ),
    );
    await tester.pump();

    // we expect the sample task to be visible
    expect(find.text('Sample task'), findsOneWidget);

    // delete button (trash icon) should exist
    expect(find.byIcon(Icons.delete_outline_rounded), findsWidgets);

    // tap the delete icon and confirm in dialog
    await tester.tap(find.byIcon(Icons.delete_outline_rounded).first);
    await tester.pump(); // start swipe animation/dialog
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Delete task'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    // allow removal animation a bit
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // the task should be removed from the UI
    expect(find.text('Sample task'), findsNothing);
  });
}
