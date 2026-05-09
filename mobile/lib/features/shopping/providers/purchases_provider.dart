import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/purchase_model.dart';
import '../../auth/providers/auth_provider.dart';

class PurchasesNotifier extends StateNotifier<AsyncValue<List<PurchaseModel>>> {
  PurchasesNotifier(this._houseId) : super(const AsyncValue.loading()) {
    _subscribe();
  }

  final String _houseId;
  final _db = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _sub;

  CollectionReference get _col =>
      _db.collection('houses').doc(_houseId).collection('purchases');

  void _subscribe() {
    if (_houseId.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    _sub = _col.orderBy('date', descending: true).snapshots().listen(
      (snap) {
        state = AsyncValue.data(
          snap.docs
              .map((d) =>
                  PurchaseModel.fromMap(d.id, d.data() as Map<String, dynamic>))
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

  Future<String?> addPurchase({
    required String store,
    required String date,
    required double total,
    required List<String> splitBetween,
    String? paidBy,
    String? note,
    required String createdBy,
  }) async {
    try {
      await _col.add({
        'houseId': _houseId,
        'store': store,
        'date': date,
        'total': total,
        'splitBetween': splitBetween,
        if (paidBy != null) 'paidBy': paidBy,
        if (note != null && note.isNotEmpty) 'note': note,
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updatePurchase({
    required String purchaseId,
    required String store,
    required String date,
    required double total,
    required List<String> splitBetween,
    String? paidBy,
    String? note,
  }) async {
    try {
      await _col.doc(purchaseId).update({
        'store': store,
        'date': date,
        'total': total,
        'splitBetween': splitBetween,
        if (paidBy != null) 'paidBy': paidBy else 'paidBy': FieldValue.delete(),
        if (note != null && note.isNotEmpty) 'note': note else 'note': FieldValue.delete(),
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deletePurchase(String purchaseId) async {
    try {
      await _col.doc(purchaseId).delete();
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

final purchasesProvider = StateNotifierProvider<PurchasesNotifier,
    AsyncValue<List<PurchaseModel>>>((ref) {
  final houseId = ref.watch(authProvider).currentHouse?.id ?? '';
  return PurchasesNotifier(houseId);
});
