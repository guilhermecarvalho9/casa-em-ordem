import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/member_model.dart';
import '../../auth/providers/auth_provider.dart';

class MembersNotifier extends StateNotifier<AsyncValue<List<MemberModel>>> {
  MembersNotifier(this._houseId) : super(const AsyncValue.loading()) {
    load();
  }

  final String _houseId;
  final _db = FirebaseFirestore.instance;

  CollectionReference get _col =>
      _db.collection('houses').doc(_houseId).collection('members');

  Future<void> load() async {
    if (_houseId.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    try {
      state = const AsyncValue.loading();
      final snap = await _col.get();
      state = AsyncValue.data(
        snap.docs
            .map((d) => MemberModel.fromMap(
                d.id, _houseId, d.data() as Map<String, dynamic>))
            .toList(),
      );
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<String?> updateRole(String memberId, String role) async {
    try {
      await _col.doc(memberId).update({'role': role});
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> removeMember(String memberId) async {
    try {
      await _col.doc(memberId).delete();
      // Also clear houseId in user doc
      await _db.collection('users').doc(memberId).update({'houseId': ''});
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final membersProvider =
    StateNotifierProvider<MembersNotifier, AsyncValue<List<MemberModel>>>((ref) {
  final houseId = ref.watch(authProvider).currentHouse?.id ?? '';
  return MembersNotifier(houseId);
});
