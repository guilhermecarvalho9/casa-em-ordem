import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shopping_model.dart';
import '../../auth/providers/auth_provider.dart';

class ShoppingNotifier extends StateNotifier<AsyncValue<List<ShoppingItemModel>>> {
  ShoppingNotifier(this._houseId) : super(const AsyncValue.loading()) {
    load();
  }

  final String _houseId;
  final _supabase = Supabase.instance.client;

  Future<void> load() async {
    try {
      state = const AsyncValue.loading();
      final data = await _supabase
          .from('shopping_items')
          .select()
          .eq('house_id', _houseId)
          .order('created_at', ascending: false);
      state = AsyncValue.data(
        (data as List).map((i) => ShoppingItemModel.fromMap(i)).toList(),
      );
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<String?> addItem({
    required String name,
    int quantity = 1,
    double? price,
    required String addedBy,
  }) async {
    try {
      await _supabase.from('shopping_items').insert({
        'house_id': _houseId,
        'name': name,
        'quantity': quantity,
        'price': price,
        'bought': false,
        'added_by': addedBy,
      });
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> toggleBought(String itemId, bool bought, {String? boughtBy}) async {
    try {
      await _supabase.from('shopping_items').update({
        'bought': bought,
        'bought_by': bought ? boughtBy : null,
      }).eq('id', itemId);
      await load();
    } catch (_) {}
  }

  Future<String?> deleteItem(String itemId) async {
    try {
      await _supabase.from('shopping_items').delete().eq('id', itemId);
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final shoppingProvider = StateNotifierProvider<ShoppingNotifier, AsyncValue<List<ShoppingItemModel>>>((ref) {
  final authState = ref.watch(authProvider);
  final houseId = authState.currentHouse?.id ?? '';
  return ShoppingNotifier(houseId);
});
