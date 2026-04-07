import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/damaged_model.dart';
import '../../auth/providers/auth_provider.dart';

class DamagedNotifier extends StateNotifier<AsyncValue<List<DamagedItemModel>>> {
  DamagedNotifier(this._houseId) : super(const AsyncValue.loading()) {
    load();
  }

  final String _houseId;
  final _supabase = Supabase.instance.client;

  Future<void> load() async {
    try {
      state = const AsyncValue.loading();
      final data = await _supabase
          .from('damaged_items')
          .select()
          .eq('house_id', _houseId)
          .order('created_at', ascending: false);
      state = AsyncValue.data(
        (data as List).map((d) => DamagedItemModel.fromMap(d)).toList(),
      );
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<String?> addItem({
    required String title,
    String? description,
    required String location,
    String? photoUrl,
    required String reportedBy,
  }) async {
    try {
      await _supabase.from('damaged_items').insert({
        'house_id': _houseId,
        'title': title,
        'description': description,
        'location': location,
        'photo_url': photoUrl,
        'status': 'pending',
        'reported_by': reportedBy,
      });
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> markFixed(String itemId) async {
    try {
      await _supabase
          .from('damaged_items')
          .update({'status': 'fixed'})
          .eq('id', itemId);
      await load();
    } catch (_) {}
  }

  Future<String?> deleteItem(String itemId) async {
    try {
      await _supabase.from('damaged_items').delete().eq('id', itemId);
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final damagedProvider = StateNotifierProvider<DamagedNotifier, AsyncValue<List<DamagedItemModel>>>((ref) {
  final authState = ref.watch(authProvider);
  final houseId = authState.currentHouse?.id ?? '';
  return DamagedNotifier(houseId);
});
