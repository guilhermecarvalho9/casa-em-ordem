import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/password_model.dart';
import '../../auth/providers/auth_provider.dart';

class PasswordsNotifier
    extends StateNotifier<AsyncValue<List<PasswordModel>>> {
  PasswordsNotifier(this._houseId) : super(const AsyncValue.loading()) {
    load();
  }

  final String _houseId;
  final _db = FirebaseFirestore.instance;

  CollectionReference get _col =>
      _db.collection('houses').doc(_houseId).collection('passwords');

  Future<void> load() async {
    if (_houseId.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    try {
      state = const AsyncValue.loading();
      final snap = await _col.orderBy('category').get();
      state = AsyncValue.data(
        snap.docs
            .map((d) =>
                PasswordModel.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList(),
      );
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<String?> addPassword({
    required String name,
    required String value,
    required String category,
    required String createdBy,
  }) async {
    try {
      await _col.add({
        'houseId': _houseId,
        'name': name,
        'value': value,
        'category': category,
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deletePassword(String passwordId) async {
    try {
      await _col.doc(passwordId).delete();
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final passwordsProvider = StateNotifierProvider<PasswordsNotifier,
    AsyncValue<List<PasswordModel>>>((ref) {
  final houseId = ref.watch(authProvider).currentHouse?.id ?? '';
  return PasswordsNotifier(houseId);
});
