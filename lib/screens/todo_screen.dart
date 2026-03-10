import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/todo_provider.dart';
import '../providers/auth_provider.dart';
import '../models/todo_item.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // load tasks once when the screen is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TodoProvider>().loadTodos();
    });
  }

  void _addTask() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      context.read<TodoProvider>().addTodo(text);
      _controller.clear();
    }
  }

  Future<void> _editTask(BuildContext context, TodoItem item) async {
    final controller = TextEditingController(text: item.text);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit task'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Task'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Save')),
          ],
        );
      },
    );
    if (result == true && controller.text.trim().isNotEmpty) {
      await context.read<TodoProvider>().updateTodoText(item.id, controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final todoProv = context.watch<TodoProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            onPressed: () {
              context.read<AuthProvider>().signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _addTask(),
                    decoration: const InputDecoration(labelText: 'Add a task'),
                  ),
                ),
                IconButton(onPressed: _addTask, icon: const Icon(Icons.add)),
              ],
            ),
          ),
          if (todoProv.isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: todoProv.todos.isEmpty
                  ? const Center(child: Text('No tasks yet'))
                  : ListView.builder(
                      itemCount: todoProv.todos.length,
                      itemBuilder: (ctx, i) {
                        final item = todoProv.todos[i];
                        return Dismissible(
                          key: ValueKey(item.id),
                          background: Container(color: Colors.redAccent),
                          onDismissed: (_) => todoProv.deleteTodo(item.id),
                          child: ListTile(
                            leading: Checkbox(value: item.done, onChanged: (_) => todoProv.toggleDone(item.id)),
                            title: GestureDetector(
                              onTap: () => _editTask(context, item),
                              child: Text(item.text, style: TextStyle(decoration: item.done ? TextDecoration.lineThrough : null)),
                            ),
                            trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () => _editTask(context, item)),
                          ),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }
}
