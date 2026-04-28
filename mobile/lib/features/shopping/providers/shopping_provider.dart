import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shopping_model.dart';
import '../../auth/providers/auth_provider.dart';

class ShoppingNotifier
    extends StateNotifier<AsyncValue<List<ShoppingItemModel>>> {
  ShoppingNotifier(this._houseId) : super(const AsyncValue.loading()) {
    load();
  }

  final String _houseId;
  final _db = FirebaseFirestore.instance;

  CollectionReference get _col =>
      _db.collection('houses').doc(_houseId).collection('shopping');

  Future<void> load() async {
    if (_houseId.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    try {
      state = const AsyncValue.loading();
      final snap =
          await _col.orderBy('createdAt', descending: true).get();
      state = AsyncValue.data(
        snap.docs
            .map((d) =>
                ShoppingItemModel.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList(),
      );
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<String?> addItem({
    required String name,
    int quantity = 1,
    double? price,
    List<String> splitBetween = const [],
    required String addedBy,
  }) async {
    try {
      await _col.add({
        'houseId': _houseId,
        'name': name,
        'quantity': quantity,
        if (price != null) 'price': price,
        if (splitBetween.isNotEmpty) 'splitBetween': splitBetween,
        'bought': false,
        'addedBy': addedBy,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> toggleBought(String itemId, bool bought,
      {String? boughtBy}) async {
    try {
      await _col.doc(itemId).update({
        'bought': bought,
        'boughtBy': bought ? boughtBy : null,
      });
      await load();
    } catch (_) {}
  }

  Future<String?> deleteItem(String itemId) async {
    try {
      await _col.doc(itemId).delete();
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final shoppingProvider = StateNotifierProvider<ShoppingNotifier,
    AsyncValue<List<ShoppingItemModel>>>((ref) {
  final houseId = ref.watch(authProvider).currentHouse?.id ?? '';
  return ShoppingNotifier(houseId);
});
