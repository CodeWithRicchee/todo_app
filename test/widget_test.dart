// Basic widget test verifying authentication screen is shown.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:todo_app/main.dart';

void main() {
  testWidgets('App starts on authentication screen', (WidgetTester tester) async {
    await tester.pumpWidget(const TodoApp());

    // Authentication screen should be visible (look for header & input fields)
    expect(find.text('Todo App'), findsOneWidget);
    expect(find.byType(TextFormField), findsWidgets);

    // Google button should be present
    expect(find.text('Google'), findsOneWidget);
  });
}
