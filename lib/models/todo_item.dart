class TodoItem {
  final String id;
  String text;
  bool done;

  TodoItem({required this.id, required this.text, this.done = false});

  factory TodoItem.fromJson(String id, Map<String, dynamic> json) {
    return TodoItem(id: id, text: json['text'] as String, done: json['done'] as bool? ?? false);
  }

  Map<String, dynamic> toJson() {
    return {'text': text, 'done': done};
  }
}
