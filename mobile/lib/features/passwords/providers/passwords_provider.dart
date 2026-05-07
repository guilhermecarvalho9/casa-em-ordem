import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/password_model.dart';
import '../../auth/providers/auth_provider.dart';

class PasswordsNotifier
    extends StateNotifier<AsyncValue<List<PasswordModel>>> {
  PasswordsNotifier(this._houseId) : super(const AsyncValue.loading()) {
    _subscribe();
  }

  final String _houseId;
  final _db = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _sub;

  CollectionReference get _col =>
      _db.collection('houses').doc(_houseId).collection('passwords');

  void _subscribe() {
    if (_houseId.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    _sub = _col.orderBy('category').snapshots().listen(
      (snap) {
        state = AsyncValue.data(
          snap.docs
              .map((d) =>
                  PasswordModel.fromMap(d.id, d.data() as Map<String, dynamic>))
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
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deletePassword(String passwordId) async {
    try {
      await _col.doc(passwordId).delete();
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
