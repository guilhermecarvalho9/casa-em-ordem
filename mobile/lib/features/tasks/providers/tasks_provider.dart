import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../../auth/providers/auth_provider.dart';

class TasksNotifier extends StateNotifier<AsyncValue<List<TaskModel>>> {
  TasksNotifier(this._houseId) : super(const AsyncValue.loading()) {
    load();
  }

  final String _houseId;
  final _db = FirebaseFirestore.instance;

  CollectionReference get _col =>
      _db.collection('houses').doc(_houseId).collection('tasks');

  Future<void> load() async {
    if (_houseId.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    try {
      state = const AsyncValue.loading();
      final snap =
          await _col.orderBy('createdAt', descending: true).get();
      state = AsyncValue.data(
        snap.docs
            .map((d) => TaskModel.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList(),
      );
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<String?> addTask({
    required String title,
    String? description,
    String? assignedTo,
    String? dueDate,
    String? recurring,
    required String createdBy,
  }) async {
    try {
      await _col.add({
        'houseId': _houseId,
        'title': title,
        if (description != null) 'description': description,
        if (assignedTo != null) 'assignedTo': assignedTo,
        if (dueDate != null) 'dueDate': dueDate,
        if (recurring != null) 'recurring': recurring,
        'completed': false,
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> toggleComplete(String taskId, bool completed) async {
    try {
      await _col.doc(taskId).update({'completed': completed});
      await load();
    } catch (_) {}
  }

  Future<String?> deleteTask(String taskId) async {
    try {
      await _col.doc(taskId).delete();
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final tasksProvider =
    StateNotifierProvider<TasksNotifier, AsyncValue<List<TaskModel>>>((ref) {
  final houseId = ref.watch(authProvider).currentHouse?.id ?? '';
  return TasksNotifier(houseId);
});
