import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/member_model.dart';
import '../../auth/providers/auth_provider.dart';

class MembersNotifier extends StateNotifier<AsyncValue<List<MemberModel>>> {
  MembersNotifier(this._houseId) : super(const AsyncValue.loading()) {
    _subscribe();
  }

  final String _houseId;
  final _db = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _sub;

  CollectionReference get _col =>
      _db.collection('houses').doc(_houseId).collection('members');

  void _subscribe() {
    if (_houseId.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    _sub = _col.snapshots().listen(
      (snap) {
        state = AsyncValue.data(
          snap.docs
              .map((d) => MemberModel.fromMap(
                  d.id, _houseId, d.data() as Map<String, dynamic>))
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

  Future<String?> updateRole(String memberId, String role) async {
    try {
      await _col.doc(memberId).update({'role': role});
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> setExpiry(String memberId, String? dateIso) async {
    try {
      if (dateIso == null) {
        await _col.doc(memberId).update({'expiresAt': FieldValue.delete()});
      } else {
        await _col.doc(memberId).update({'expiresAt': dateIso});
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateMemberContact(
    String memberId, {
    String? phone,
    String? emergencyContact,
    String? emergencyPhone,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (phone != null) data['phone'] = phone.isEmpty ? FieldValue.delete() : phone;
      if (emergencyContact != null) data['emergencyContact'] = emergencyContact.isEmpty ? FieldValue.delete() : emergencyContact;
      if (emergencyPhone != null) data['emergencyPhone'] = emergencyPhone.isEmpty ? FieldValue.delete() : emergencyPhone;
      if (data.isNotEmpty) await _col.doc(memberId).update(data);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> removeMember(String memberId) async {
    try {
      await _col.doc(memberId).delete();
      await _db.collection('users').doc(memberId).update({'houseId': ''});
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

final membersProvider =
    StateNotifierProvider<MembersNotifier, AsyncValue<List<MemberModel>>>((ref) {
  final houseId = ref.watch(authProvider).currentHouse?.id ?? '';
  return MembersNotifier(houseId);
});
