import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/task_service.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TextEditingController _taskController = TextEditingController();
  final TaskService _taskService = TaskService();
  String _searchQuery = '';   // ← 변수만 여기

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  void _addTask() {
    final title = _taskController.text.trim();
    if (title.isEmpty) return;
    _taskService.addTask(title);
    _taskController.clear();
  }

  Future<void> _confirmDelete(String taskId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete task?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) _taskService.deleteTask(taskId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task Manager')),
      body: Column(
        children: [
          // 검색바 ← 여기
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          // 태스크 입력창
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _taskController,
                  decoration: const InputDecoration(hintText: 'New task name...'),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _addTask, child: const Text('Add')),
            ]),
          ),
          Expanded(
            child: StreamBuilder<List<Task>>(
              stream: _taskService.streamTasks(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                // 검색 필터 적용
                final tasks = (snapshot.data ?? [])
                    .where((t) => t.title.toLowerCase().contains(_searchQuery))
                    .toList();
                if (tasks.isEmpty) {
                  return const Center(child: Text('No tasks yet — add one above!'));
                }
                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return ExpansionTile(
                      leading: Checkbox(
                        value: task.isCompleted,
                        onChanged: (_) => _taskService.toggleTask(task),
                      ),
                      title: Text(
                        task.title,
                        style: TextStyle(
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmDelete(task.id),
                      ),
                      children: [
                        ...task.subtasks.map((sub) => ListTile(
                          contentPadding: const EdgeInsets.only(left: 48),
                          title: Text(sub['title'] ?? ''),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              final updated =
                                  List<Map<String, dynamic>>.from(task.subtasks)
                                    ..remove(sub);
                              _taskService.updateSubtasks(task.id, updated);
                            },
                          ),
                        )),
                        ListTile(
                          contentPadding:
                              const EdgeInsets.only(left: 48, right: 16),
                          title: TextField(
                            decoration: const InputDecoration(
                                hintText: 'Add subtask...'),
                            onSubmitted: (value) {
                              if (value.trim().isEmpty) return;
                              final updated =
                                  List<Map<String, dynamic>>.from(task.subtasks)
                                    ..add({'title': value.trim()});
                              _taskService.updateSubtasks(task.id, updated);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}