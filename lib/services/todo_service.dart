import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/todo_item.dart';

class TodoService {
  final String databaseUrl; // e.g. https://<project>.firebaseio.com

  TodoService({required this.databaseUrl});

  Future<List<TodoItem>> fetchTodos(String userId, String authToken) async {
    final url = Uri.parse('$databaseUrl/tasks/$userId.json?auth=$authToken');
    final resp = await http.get(url);
    if (resp.statusCode != 200) {
      throw Exception('Failed to load tasks');
    }
    final Map<String, dynamic>? data = jsonDecode(resp.body);
    if (data == null) return [];
    final todos = data.entries.map((entry) => TodoItem.fromJson(entry.key, entry.value)).toList();
    return todos;
  }

  Future<void> addTodo(String userId, String authToken, TodoItem item) async {
    final url = Uri.parse('$databaseUrl/tasks/$userId.json?auth=$authToken');
    final resp = await http.post(url, body: jsonEncode(item.toJson()), headers: {'Content-Type': 'application/json'});
    if (resp.statusCode != 200) {
      throw Exception('Failed to add task');
    }
    // Response contains name of new child as 'name'.
  }

  Future<void> updateTodo(String userId, String authToken, TodoItem item) async {
    final url = Uri.parse('$databaseUrl/tasks/$userId/${item.id}.json?auth=$authToken');
    final resp = await http.patch(url, body: jsonEncode(item.toJson()), headers: {'Content-Type': 'application/json'});
    if (resp.statusCode != 200) {
      throw Exception('Failed to update task');
    }
  }

  Future<void> deleteTodo(String userId, String authToken, String id) async {
    final url = Uri.parse('$databaseUrl/tasks/$userId/$id.json?auth=$authToken');
    final resp = await http.delete(url);
    if (resp.statusCode != 200) {
      throw Exception('Failed to delete task');
    }
  }
}
