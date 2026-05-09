import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/damaged_model.dart';
import '../../auth/providers/auth_provider.dart';

class DamagedNotifier
    extends StateNotifier<AsyncValue<List<DamagedItemModel>>> {
  DamagedNotifier(this._houseId) : super(const AsyncValue.loading()) {
    _subscribe();
  }

  final String _houseId;
  final _db = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _sub;

  CollectionReference get _col =>
      _db.collection('houses').doc(_houseId).collection('damaged');

  void _subscribe() {
    if (_houseId.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    _sub = _col.orderBy('createdAt', descending: true).snapshots().listen(
      (snap) {
        state = AsyncValue.data(
          snap.docs
              .map((d) =>
                  DamagedItemModel.fromMap(d.id, d.data() as Map<String, dynamic>))
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

  Future<String?> addItem({
    required String title,
    String? description,
    required String location,
    String? photoUrl,
    required String reportedBy,
  }) async {
    try {
      await _col.add({
        'houseId': _houseId,
        'title': title,
        if (description != null) 'description': description,
        'location': location,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'status': 'pending',
        'reportedBy': reportedBy,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> markFixed(String itemId) async {
    try {
      await _col.doc(itemId).update({'status': 'fixed'});
    } catch (_) {}
  }

  Future<String?> updateItem({
    required String itemId,
    required String title,
    String? description,
    required String location,
  }) async {
    try {
      await _col.doc(itemId).update({
        'title': title,
        'description': description ?? FieldValue.delete(),
        'location': location,
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteItem(String itemId) async {
    try {
      await _col.doc(itemId).delete();
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

final damagedProvider = StateNotifierProvider<DamagedNotifier,
    AsyncValue<List<DamagedItemModel>>>((ref) {
  final houseId = ref.watch(authProvider).currentHouse?.id ?? '';
  return DamagedNotifier(houseId);
});
