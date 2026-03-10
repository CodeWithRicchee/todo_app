import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/todo_provider.dart';
import 'services/auth_service.dart';
import 'services/todo_service.dart';
import 'screens/auth_screen.dart';
import 'screens/todo_screen.dart';

const firebaseApiKey = 'AIzaSyCs-qB36SDFQdbDGUW6fFWgx_uylNMK2xs';
const firebaseDatabaseUrl = 'https://todo-app-69945-default-rtdb.firebaseio.com/';

void main() {
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService: AuthService(apiKey: firebaseApiKey)),
        ),
        // TodoProvider is created later once auth info is available.
      ],
      child: const _AuthOrTodoApp(),
    );
  }
}

class _AuthOrTodoApp extends StatelessWidget {
  const _AuthOrTodoApp();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) {
      return MaterialApp(
        title: 'TODO Task',
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), useMaterial3: true),
        home: const AuthScreen(),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => TodoProvider(
        todoService: TodoService(databaseUrl: firebaseDatabaseUrl),
        userId: auth.userId!,
        authToken: auth.token!,
      ),
      child: MaterialApp(
        title: 'TODO Task',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), useMaterial3: true),
        home: const TodoScreen(),
      ),
    );
  }
}
