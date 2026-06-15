import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shopping_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/services/house_notification_service.dart';

class ShoppingNotifier
    extends StateNotifier<AsyncValue<List<ShoppingItemModel>>> {
  ShoppingNotifier(this._houseId) : super(const AsyncValue.loading()) {
    _subscribe();
  }

  final String _houseId;
  final _db = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _sub;

  CollectionReference get _col =>
      _db.collection('houses').doc(_houseId).collection('shopping');

  void _subscribe() {
    if (_houseId.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    _sub = _col.orderBy('createdAt', descending: true).snapshots().listen(
      (snap) {
        state = AsyncValue.data(
          snap.docs
              .map((d) =>
                  ShoppingItemModel.fromMap(d.id, d.data() as Map<String, dynamic>))
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

  Future<String?> addItem({
    required String name,
    int quantity = 1,
    double? price,
    List<String> splitBetween = const [],
    required String addedBy,
    String addedByName = '',
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
      HouseNotificationService.shoppingItemAdded(
        houseId: _houseId,
        createdBy: addedBy,
        creatorName: addedByName.isNotEmpty ? addedByName : 'Alguém',
        itemName: name,
      );
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
    } catch (_) {}
  }

  Future<String?> updateItem({
    required String itemId,
    required String name,
    required int quantity,
    double? price,
    List<String> splitBetween = const [],
  }) async {
    try {
      await _col.doc(itemId).update({
        'name': name,
        'quantity': quantity,
        if (price != null) 'price': price else 'price': FieldValue.delete(),
        'splitBetween': splitBetween,
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteItem(String itemId) async {
    try {
      await _col.doc(itemId).delete();
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

final shoppingProvider = StateNotifierProvider<ShoppingNotifier,
    AsyncValue<List<ShoppingItemModel>>>((ref) {
  final houseId = ref.watch(authProvider).currentHouse?.id ?? '';
  return ShoppingNotifier(houseId);
});
