import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/rule_model.dart';
import '../../auth/providers/auth_provider.dart';

class RulesNotifier extends StateNotifier<AsyncValue<List<RuleModel>>> {
  RulesNotifier(this._houseId) : super(const AsyncValue.loading()) {
    load();
  }

  final String _houseId;
  final _supabase = Supabase.instance.client;

  Future<void> load() async {
    try {
      state = const AsyncValue.loading();
      final data = await _supabase
          .from('rules')
          .select()
          .eq('house_id', _houseId)
          .order('created_at');
      state = AsyncValue.data(
        (data as List).map((r) => RuleModel.fromMap(r)).toList(),
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
      await _supabase.from('rules').insert({
        'house_id': _houseId,
        'title': title,
        'description': description,
        'created_by': createdBy,
      });
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteRule(String ruleId) async {
    try {
      await _supabase.from('rules').delete().eq('id', ruleId);
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final rulesProvider = StateNotifierProvider<RulesNotifier, AsyncValue<List<RuleModel>>>((ref) {
  final authState = ref.watch(authProvider);
  final houseId = authState.currentHouse?.id ?? '';
  return RulesNotifier(houseId);
});
