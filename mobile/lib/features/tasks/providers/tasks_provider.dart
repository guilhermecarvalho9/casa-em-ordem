import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_model.dart';
import '../../auth/providers/auth_provider.dart';

class TasksNotifier extends StateNotifier<AsyncValue<List<TaskModel>>> {
  TasksNotifier(this._houseId) : super(const AsyncValue.loading()) {
    load();
  }

  final String _houseId;
  final _supabase = Supabase.instance.client;

  Future<void> load() async {
    try {
      state = const AsyncValue.loading();
      final data = await _supabase
          .from('tasks')
          .select()
          .eq('house_id', _houseId)
          .order('created_at', ascending: false);
      state = AsyncValue.data(
        (data as List).map((t) => TaskModel.fromMap(t)).toList(),
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
      await _supabase.from('tasks').insert({
        'house_id': _houseId,
        'title': title,
        'description': description,
        'assigned_to': assignedTo,
        'due_date': dueDate,
        'recurring': recurring,
        'completed': false,
        'created_by': createdBy,
      });
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> toggleComplete(String taskId, bool completed) async {
    try {
      await _supabase
          .from('tasks')
          .update({'completed': completed})
          .eq('id', taskId);
      await load();
    } catch (_) {}
  }

  Future<String?> deleteTask(String taskId) async {
    try {
      await _supabase.from('tasks').delete().eq('id', taskId);
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final tasksProvider = StateNotifierProvider<TasksNotifier, AsyncValue<List<TaskModel>>>((ref) {
  final authState = ref.watch(authProvider);
  final houseId = authState.currentHouse?.id ?? '';
  return TasksNotifier(houseId);
});
