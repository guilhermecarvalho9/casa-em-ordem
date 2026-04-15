import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rule_model.dart';
import '../../auth/providers/auth_provider.dart';

class RulesNotifier extends StateNotifier<AsyncValue<List<RuleModel>>> {
  RulesNotifier(this._houseId) : super(const AsyncValue.loading()) {
    load();
  }

  final String _houseId;
  final _db = FirebaseFirestore.instance;

  CollectionReference get _col =>
      _db.collection('houses').doc(_houseId).collection('rules');

  Future<void> load() async {
    if (_houseId.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    try {
      state = const AsyncValue.loading();
      final snap = await _col.orderBy('createdAt').get();
      state = AsyncValue.data(
        snap.docs
            .map((d) =>
                RuleModel.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList(),
      );
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
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
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteRule(String ruleId) async {
    try {
      await _col.doc(ruleId).delete();
      await load();
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
