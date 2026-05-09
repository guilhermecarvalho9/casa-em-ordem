import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/permissions_model.dart';
import '../../auth/providers/auth_provider.dart';

class PermissionsNotifier extends StateNotifier<PermissionsModel> {
  PermissionsNotifier(this._houseId)
      : super(PermissionsModel.fromMap(null)) {
    _subscribe();
  }

  final String _houseId;
  final _db = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot>? _sub;

  DocumentReference get _doc =>
      _db.collection('houses').doc(_houseId).collection('config').doc('permissions');

  void _subscribe() {
    if (_houseId.isEmpty) return;
    _sub = _doc.snapshots().listen(
      (snap) {
        final data = snap.data() as Map<String, dynamic>?;
        state = PermissionsModel.fromMap(data);
      },
      onError: (_) => state = PermissionsModel.fromMap(null),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<String?> save(PermissionsModel perms) async {
    if (_houseId.isEmpty) return 'Sem casa configurada';
    try {
      await _doc.set(perms.toMap());
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final permissionsProvider =
    StateNotifierProvider<PermissionsNotifier, PermissionsModel>((ref) {
  final houseId = ref.watch(authProvider).currentHouse?.id ?? '';
  return PermissionsNotifier(houseId);
});
