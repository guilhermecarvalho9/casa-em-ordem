import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/damaged_model.dart';
import '../../auth/providers/auth_provider.dart';

class DamagedNotifier
    extends StateNotifier<AsyncValue<List<DamagedItemModel>>> {
  DamagedNotifier(this._houseId) : super(const AsyncValue.loading()) {
    load();
  }

  final String _houseId;
  final _db = FirebaseFirestore.instance;

  CollectionReference get _col =>
      _db.collection('houses').doc(_houseId).collection('damaged');

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
            .map((d) =>
                DamagedItemModel.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList(),
      );
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
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
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> markFixed(String itemId) async {
    try {
      await _col.doc(itemId).update({'status': 'fixed'});
      await load();
    } catch (_) {}
  }

  Future<String?> deleteItem(String itemId) async {
    try {
      await _col.doc(itemId).delete();
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final damagedProvider = StateNotifierProvider<DamagedNotifier,
    AsyncValue<List<DamagedItemModel>>>((ref) {
  final houseId = ref.watch(authProvider).currentHouse?.id ?? '';
  return DamagedNotifier(houseId);
});
