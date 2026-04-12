import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';

class TaskService {
  final CollectionReference _col =
      FirebaseFirestore.instance.collection('tasks');

  Future<void> addTask(String title) async {
    if (title.trim().isEmpty) return;
    await _col.add({
      'title': title.trim(),
      'isCompleted': false,
      'subtasks': [],
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Stream<List<Task>> streamTasks() {
    return _col
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                Task.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  Future<void> toggleTask(Task task) async {
    await _col.doc(task.id).update({'isCompleted': !task.isCompleted});
  }

  Future<void> updateSubtasks(
      String taskId, List<Map<String, dynamic>> subtasks) async {
    await _col.doc(taskId).update({'subtasks': subtasks});
  }

  Future<void> deleteTask(String taskId) async {
    await _col.doc(taskId).delete();
  }
}