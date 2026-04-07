import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/member_model.dart';
import '../../auth/providers/auth_provider.dart';

class MembersNotifier extends StateNotifier<AsyncValue<List<MemberModel>>> {
  MembersNotifier(this._houseId) : super(const AsyncValue.loading()) {
    load();
  }

  final String _houseId;
  final _supabase = Supabase.instance.client;

  Future<void> load() async {
    try {
      state = const AsyncValue.loading();
      final data = await _supabase
          .from('house_members')
          .select('*, profiles(name, avatar_url, color)')
          .eq('house_id', _houseId)
          .order('entry_date');
      state = AsyncValue.data(
        (data as List).map((m) => MemberModel.fromMap(m)).toList(),
      );
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<String?> addMember(String userId, String role) async {
    try {
      await _supabase.from('house_members').insert({
        'house_id': _houseId,
        'user_id': userId,
        'role': role,
      });
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateRole(String memberId, String role) async {
    try {
      await _supabase
          .from('house_members')
          .update({'role': role})
          .eq('id', memberId);
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> removeMember(String memberId) async {
    try {
      await _supabase.from('house_members').delete().eq('id', memberId);
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final membersProvider = StateNotifierProvider<MembersNotifier, AsyncValue<List<MemberModel>>>((ref) {
  final authState = ref.watch(authProvider);
  final houseId = authState.currentHouse?.id ?? '';
  return MembersNotifier(houseId);
});
