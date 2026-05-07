import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rule_model.dart';
import '../../auth/providers/auth_provider.dart';

class RulesNotifier extends StateNotifier<AsyncValue<List<RuleModel>>> {
  RulesNotifier(this._houseId) : super(const AsyncValue.loading()) {
    _subscribe();
  }

  final String _houseId;
  final _db = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _sub;

  CollectionReference get _col =>
      _db.collection('houses').doc(_houseId).collection('rules');

  void _subscribe() {
    if (_houseId.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    _sub = _col.orderBy('createdAt').snapshots().listen(
      (snap) {
        state = AsyncValue.data(
          snap.docs
              .map((d) =>
                  RuleModel.fromMap(d.id, d.data() as Map<String, dynamic>))
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

  Future<String?> addRule({
    required String title,
    required String description,
    required String createdBy,
  }) async {
    try {
      await _col.add({
        'houseId': _houseId,
        'title': title,
        'description': description,
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteRule(String ruleId) async {
    try {
      await _col.doc(ruleId).delete();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final rulesProvider =
    StateNotifierProvider<RulesNotifier, AsyncValue<List<RuleModel>>>((ref) {
  final houseId = ref.watch(authProvider).currentHouse?.id ?? '';
  return RulesNotifier(houseId);
});
