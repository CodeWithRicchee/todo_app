import 'package:flutter/foundation.dart';

import '../models/todo_item.dart';
import '../services/todo_service.dart';

class TodoProvider with ChangeNotifier {
  final TodoService _todoService;
  final String userId;
  final String authToken;

  List<TodoItem> _todos = [];
  bool _isLoading = false;

  TodoProvider({required TodoService todoService, required this.userId, required this.authToken}) : _todoService = todoService;

  List<TodoItem> get todos => [..._todos];
  bool get isLoading => _isLoading;

  Future<void> loadTodos() async {
    _isLoading = true;
    notifyListeners();
    _todos = await _todoService.fetchTodos(userId, authToken);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTodo(String text) async {
    final newItem = TodoItem(id: '', text: text);
    await _todoService.addTodo(userId, authToken, newItem);
    await loadTodos();
  }

  Future<void> toggleDone(String id) async {
    final idx = _todos.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    _todos[idx].done = !_todos[idx].done;
    await _todoService.updateTodo(userId, authToken, _todos[idx]);
    notifyListeners();
  }

  Future<void> updateTodoText(String id, String newText) async {
    final idx = _todos.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    _todos[idx].text = newText;
    await _todoService.updateTodo(userId, authToken, _todos[idx]);
    notifyListeners();
  }

  Future<void> deleteTodo(String id) async {
    await _todoService.deleteTodo(userId, authToken, id);
    _todos.removeWhere((t) => t.id == id);
    notifyListeners();
  }
}
