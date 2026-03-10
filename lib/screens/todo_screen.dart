import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/todo_provider.dart';
import '../providers/auth_provider.dart';
import '../models/todo_item.dart';

// ── Palette (matches AuthScreen luxury dark theme) ─────────────────────────
class _C {
  static const bg = Color(0xFF0D0F14);
  static const surface = Color(0xFF151820);
  static const card = Color(0xFF1C2030);
  static const cardHover = Color(0xFF222840);
  static const gold = Color(0xFFCCA84B);
  static const goldLight = Color(0xFFE8C870);
  static const textPrimary = Color(0xFFF0EDE6);
  static const textMuted = Color(0xFF7A8099);
  static const border = Color(0xFF2A2F42);
  static const danger = Color(0xFFE05252);
  static const success = Color(0xFF4CAF8A);
}

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _inputFocused = false;

  // Animated list key for item add/remove
  final _listKey = GlobalKey<AnimatedListState>();

  // Track local copy length for AnimatedList inserts
  int _previousCount = 0;

  late AnimationController _emptyStateController;
  late Animation<double> _emptyFadeAnim;
  late Animation<double> _emptyFloatAnim;

  late AnimationController _headerController;
  late Animation<double> _headerFadeAnim;
  late Animation<Offset> _headerSlideAnim;

  @override
  void initState() {
    super.initState();

    // Empty state pulsing float
    _emptyStateController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);

    _emptyFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _emptyStateController,
        curve: const Interval(0, 0.3, curve: Curves.easeOut),
      ),
    );
    _emptyFloatAnim = Tween<double>(begin: 0.0, end: 10.0).animate(CurvedAnimation(parent: _emptyStateController, curve: Curves.easeInOut));

    // Header reveal on load
    _headerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
    _headerFadeAnim = CurvedAnimation(parent: _headerController, curve: Curves.easeOut);
    _headerSlideAnim = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerController, curve: Curves.easeOut));

    _focusNode.addListener(() => setState(() => _inputFocused = _focusNode.hasFocus));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TodoProvider>().loadTodos();
    });
  }

  @override
  void dispose() {
    _emptyStateController.dispose();
    _headerController.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addTask() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final todoProv = context.read<TodoProvider>();
    todoProv.addTodo(text);
    _controller.clear();
    // AnimatedList insert at position 0
    _listKey.currentState?.insertItem(0, duration: const Duration(milliseconds: 420));
  }

  Future<void> _editTask(BuildContext context, TodoItem item) async {
    final editCtrl = TextEditingController(text: item.text);
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.65),
      transitionDuration: const Duration(milliseconds: 320),
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curved,
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (ctx, _, __) => _EditDialog(controller: editCtrl),
    );
    if (result == true && editCtrl.text.trim().isNotEmpty) {
      await context.read<TodoProvider>().updateTodoText(item.id, editCtrl.text.trim());
    }
  }

  void _deleteItem(int index, TodoItem item) {
    context.read<TodoProvider>().deleteTodo(item.id);
    _listKey.currentState?.removeItem(index, (ctx, anim) => _buildRemovedItem(item, anim), duration: const Duration(milliseconds: 300));
  }

  Widget _buildRemovedItem(TodoItem item, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: _TodoCard(item: item, onToggle: () {}, onEdit: () {}, onDelete: () {}, isRemoving: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todoProv = context.watch<TodoProvider>();
    final todos = todoProv.todos;

    // Sync animated list when external loads happen
    if (!todoProv.isLoading && todos.length > _previousCount) {
      final diff = todos.length - _previousCount;
      for (int i = 0; i < diff; i++) {
        _listKey.currentState?.insertItem(i, duration: const Duration(milliseconds: 400));
      }
    }
    _previousCount = todos.length;

    final completed = todos.where((t) => t.done).length;
    final progress = todos.isEmpty ? 0.0 : completed / todos.length;

    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          // ── Background orbs ──────────────────────────────────────────
          Positioned(top: -100, right: -60, child: _Orb(color: _C.gold.withOpacity(0.06), size: 340)),
          Positioned(bottom: 80, left: -80, child: _Orb(color: const Color(0xFF3A4AFF).withOpacity(0.05), size: 280)),
          Positioned(top: 200, left: -40, child: _Orb(color: _C.success.withOpacity(0.04), size: 200)),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ─────────────────────────────────────────────
                FadeTransition(
                  opacity: _headerFadeAnim,
                  child: SlideTransition(
                    position: _headerSlideAnim,
                    child: _Header(todos: todos, completed: completed, progress: progress, onSignOut: () => context.read<AuthProvider>().signOut()),
                  ),
                ),

                // ── Input bar ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    decoration: BoxDecoration(
                      color: _C.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _inputFocused ? _C.gold.withOpacity(0.7) : _C.border, width: _inputFocused ? 1.5 : 1.0),
                      boxShadow: _inputFocused ? [BoxShadow(color: _C.gold.withOpacity(0.12), blurRadius: 20, spreadRadius: 1)] : [],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.add_task_rounded, color: _C.textMuted, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            onSubmitted: (_) => _addTask(),
                            style: const TextStyle(color: _C.textPrimary, fontSize: 14, letterSpacing: 0.2),
                            cursorColor: _C.gold,
                            decoration: const InputDecoration(
                              hintText: 'What needs to be done?',
                              hintStyle: TextStyle(color: _C.textMuted, fontSize: 14),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _AddButton(onPressed: _addTask),
                      ],
                    ),
                  ),
                ),

                // ── List / Empty state ──────────────────────────────────
                Expanded(
                  child: todoProv.isLoading
                      ? const Center(child: CircularProgressIndicator(color: _C.gold, strokeWidth: 2))
                      : todos.isEmpty
                      ? _EmptyState(floatAnim: _emptyFloatAnim, fadeAnim: _emptyFadeAnim)
                      : AnimatedList(
                          key: _listKey,
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          initialItemCount: todos.length,
                          itemBuilder: (ctx, i, animation) {
                            if (i >= todos.length) return const SizedBox.shrink();
                            final item = todos[i];
                            return _SlideInItem(
                              animation: animation,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _TodoCard(
                                  item: item,
                                  onToggle: () => context.read<TodoProvider>().toggleDone(item.id),
                                  onEdit: () => _editTask(context, item),
                                  onDelete: () => _deleteItem(i, item),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final List<TodoItem> todos;
  final int completed;
  final double progress;
  final VoidCallback onSignOut;

  const _Header({required this.todos, required this.completed, required this.progress, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Brand icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _C.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _C.gold.withOpacity(0.4), width: 1.2),
                ),
                child: const Icon(Icons.diamond_outlined, color: _C.gold, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My Tasks',
                    style: TextStyle(fontFamily: 'Georgia', fontSize: 22, fontWeight: FontWeight.w700, color: _C.textPrimary, letterSpacing: -0.3),
                  ),
                  Text(
                    todos.isEmpty ? 'Nothing yet' : '$completed of ${todos.length} complete',
                    style: const TextStyle(fontSize: 12, color: _C.textMuted, letterSpacing: 0.2),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: onSignOut,
                icon: const Icon(Icons.logout_rounded, color: _C.textMuted, size: 20),
                tooltip: 'Sign out',
              ),
            ],
          ),
          if (todos.isNotEmpty) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                builder: (_, value, __) => LinearProgressIndicator(
                  value: value,
                  minHeight: 4,
                  backgroundColor: _C.border,
                  valueColor: const AlwaysStoppedAnimation(_C.gold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final Animation<double> floatAnim;
  final Animation<double> fadeAnim;

  const _EmptyState({required this.floatAnim, required this.fadeAnim});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: fadeAnim,
        child: AnimatedBuilder(
          animation: floatAnim,
          builder: (_, child) => Transform.translate(offset: Offset(0, -floatAnim.value), child: child),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glowing icon container
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: _C.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: _C.gold.withOpacity(0.3), width: 1.5),
                  boxShadow: [BoxShadow(color: _C.gold.withOpacity(0.12), blurRadius: 32, spreadRadius: 4)],
                ),
                child: const Icon(Icons.playlist_add_rounded, size: 44, color: _C.gold),
              ),
              const SizedBox(height: 24),
              const Text(
                'Nothing to do yet',
                style: TextStyle(fontFamily: 'Georgia', fontSize: 20, fontWeight: FontWeight.w700, color: _C.textPrimary, letterSpacing: -0.3),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add a task above to get started.\nYour focus list awaits.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: _C.textMuted, height: 1.6, letterSpacing: 0.2),
              ),
              const SizedBox(height: 24),
              // Decorative dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (i) => Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: _C.gold.withOpacity(0.2 + i * 0.15)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Slide-in wrapper ─────────────────────────────────────────────────────────

class _SlideInItem extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _SlideInItem({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    final slideTween = Tween<Offset>(
      begin: const Offset(-1.0, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

    return SlideTransition(
      position: slideTween,
      child: FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    );
  }
}

// ── Todo Card ────────────────────────────────────────────────────────────────

class _TodoCard extends StatefulWidget {
  final TodoItem item;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isRemoving;

  const _TodoCard({required this.item, required this.onToggle, required this.onEdit, required this.onDelete, this.isRemoving = false});

  @override
  State<_TodoCard> createState() => _TodoCardState();
}

class _TodoCardState extends State<_TodoCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final done = widget.item.done;

    return Dismissible(
      key: ValueKey(widget.item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: _C.danger.withOpacity(0.15),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _C.danger.withOpacity(0.4)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded, color: _C.danger, size: 20),
            SizedBox(width: 6),
            Text(
              'Delete',
              style: TextStyle(color: _C.danger, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.4),
            ),
          ],
        ),
      ),
      onDismissed: (_) => widget.onDelete(),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _hovered ? _C.cardHover : _C.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: done ? _C.success.withOpacity(0.25) : _C.border, width: 1),
            boxShadow: _hovered ? [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 4))] : [],
          ),
          child: Row(
            children: [
              // Checkbox zone
              GestureDetector(
                onTap: widget.onToggle,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? _C.success : Colors.transparent,
                      border: Border.all(color: done ? _C.success : _C.border, width: 1.8),
                      boxShadow: done ? [BoxShadow(color: _C.success.withOpacity(0.3), blurRadius: 8, spreadRadius: 1)] : [],
                    ),
                    child: done ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
                  ),
                ),
              ),

              // Text
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                  child: Text(
                    widget.item.text,
                    style: TextStyle(
                      color: done ? _C.textMuted : _C.textPrimary,
                      fontSize: 14,
                      letterSpacing: 0.2,
                      height: 1.4,
                      decoration: done ? TextDecoration.lineThrough : null,
                      decorationColor: _C.textMuted,
                    ),
                  ),
                ),
              ),

              // Edit button
              IconButton(
                onPressed: widget.onEdit,
                icon: const Icon(Icons.edit_outlined, size: 17, color: _C.textMuted),
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Add Button ───────────────────────────────────────────────────────────────

class _AddButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _AddButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_C.gold, _C.goldLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: _C.gold.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: const Icon(Icons.add_rounded, color: Color(0xFF0D0F14), size: 20),
      ),
    );
  }
}

// ── Edit Dialog ──────────────────────────────────────────────────────────────

class _EditDialog extends StatelessWidget {
  final TextEditingController controller;
  const _EditDialog({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _C.border, width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 40, spreadRadius: 4)],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _C.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _C.gold.withOpacity(0.4)),
                  ),
                  child: const Icon(Icons.edit_note_rounded, color: _C.gold, size: 18),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Edit Task',
                  style: TextStyle(fontFamily: 'Georgia', fontSize: 18, fontWeight: FontWeight.w700, color: _C.textPrimary, letterSpacing: -0.2),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _C.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: _C.textPrimary, fontSize: 14),
                cursorColor: _C.gold,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Task description',
                  hintStyle: TextStyle(color: _C.textMuted, fontSize: 14),
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _C.border),
                      foregroundColor: _C.textMuted,
                      backgroundColor: _C.surface,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_C.gold, _C.goldLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: _C.gold.withOpacity(0.3), blurRadius: 14, offset: const Offset(0, 4))],
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: const Color(0xFF0D0F14),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0D0F14)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Orb helper ───────────────────────────────────────────────────────────────

class _Orb extends StatelessWidget {
  final Color color;
  final double size;
  const _Orb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}
