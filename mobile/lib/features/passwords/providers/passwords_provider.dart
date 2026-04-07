import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/password_model.dart';
import '../../auth/providers/auth_provider.dart';

class PasswordsNotifier extends StateNotifier<AsyncValue<List<PasswordModel>>> {
  PasswordsNotifier(this._houseId) : super(const AsyncValue.loading()) {
    load();
  }

  final String _houseId;
  final _supabase = Supabase.instance.client;

  Future<void> load() async {
    try {
      state = const AsyncValue.loading();
      final data = await _supabase
          .from('passwords')
          .select()
          .eq('house_id', _houseId)
          .order('category');
      state = AsyncValue.data(
        (data as List).map((p) => PasswordModel.fromMap(p)).toList(),
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
      await _supabase.from('passwords').insert({
        'house_id': _houseId,
        'name': name,
        'value': value,
        'category': category,
        'created_by': createdBy,
      });
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deletePassword(String passwordId) async {
    try {
      await _supabase.from('passwords').delete().eq('id', passwordId);
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final passwordsProvider = StateNotifierProvider<PasswordsNotifier, AsyncValue<List<PasswordModel>>>((ref) {
  final authState = ref.watch(authProvider);
  final houseId = authState.currentHouse?.id ?? '';
  return PasswordsNotifier(houseId);
});
