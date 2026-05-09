import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/task_model.dart';
import '../../auth/providers/auth_provider.dart';

class TasksNotifier extends StateNotifier<AsyncValue<List<TaskModel>>> {
  TasksNotifier(this._houseId) : super(const AsyncValue.loading()) {
    _subscribe();
  }

  final String _houseId;
  final _db = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _sub;

  CollectionReference get _col =>
      _db.collection('houses').doc(_houseId).collection('tasks');

  void _subscribe() {
    if (_houseId.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    _sub = _col.orderBy('createdAt', descending: true).snapshots().listen(
      (snap) {
        state = AsyncValue.data(
          snap.docs
              .map((d) => TaskModel.fromMap(d.id, d.data() as Map<String, dynamic>))
              .toList(),
        );
      },
      onError: (e, s) => state = AsyncValue.error(e, s),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<String?> addTask({
    required String title,
    String? description,
    String? assignedTo,
    String? dueDate,
    String? recurring,
    required String createdBy,
    bool photoRequired = false,
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
        'photoRequired': photoRequired,
        'photosBefore': [],
        'photosAfter': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> addPhoto(String taskId, File file, {required bool isBefore}) async {
    try {
      final ext = file.path.split('.').last;
      final ref = FirebaseStorage.instance
          .ref('houses/$_houseId/tasks/$taskId/${isBefore ? 'before' : 'after'}_${DateTime.now().millisecondsSinceEpoch}.$ext');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      final field = isBefore ? 'photosBefore' : 'photosAfter';
      await _col.doc(taskId).update({field: FieldValue.arrayUnion([url])});
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> removePhoto(String taskId, String url, {required bool isBefore}) async {
    try {
      final field = isBefore ? 'photosBefore' : 'photosAfter';
      await _col.doc(taskId).update({field: FieldValue.arrayRemove([url])});
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> toggleComplete(String taskId, bool completed) async {
    await _col.doc(taskId).update({'completed': completed});
  }

  Future<String?> deleteTask(String taskId) async {
    try {
      await _col.doc(taskId).delete();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> refresh() async {
    _sub?.cancel();
    _sub = null;
    _subscribe();
    await Future.delayed(const Duration(milliseconds: 600));
  }
}

final tasksProvider =
    StateNotifierProvider<TasksNotifier, AsyncValue<List<TaskModel>>>((ref) {
  final houseId = ref.watch(authProvider).currentHouse?.id ?? '';
  return TasksNotifier(houseId);
});
