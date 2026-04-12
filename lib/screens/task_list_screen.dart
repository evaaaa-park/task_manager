final TaskService _taskService = TaskService();

Expanded(
  child: StreamBuilder<List<Task>>(
    stream: _taskService.streamTasks(),
    builder: (context, snapshot) {
      // 상태 1: Firestore 연결 중
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      }

      final tasks = snapshot.data ?? [];
      if (tasks.isEmpty) {
        return const Center(child: Text('No tasks yet — add one above!'));
      }

      return ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return ListTile(
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
              onPressed: () => _taskService.deleteTask(task.id),
            ),
          );
        },
      );
    },
  ),
),