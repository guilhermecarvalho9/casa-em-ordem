import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bill_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/services/notification_service.dart';

class BillsNotifier extends StateNotifier<AsyncValue<List<BillModel>>> {
  BillsNotifier(this._houseId) : super(const AsyncValue.loading()) {
    _subscribe();
  }

  final String _houseId;
  final _db = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _sub;

  CollectionReference get _col =>
      _db.collection('houses').doc(_houseId).collection('bills');

  void _subscribe() {
    if (_houseId.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    _sub = _col.orderBy('dueDate').snapshots().listen(
      (snap) {
        state = AsyncValue.data(
          snap.docs
              .map((d) => BillModel.fromMap(d.id, d.data() as Map<String, dynamic>))
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

  Future<String?> addBill({
    required String title,
    required double amount,
    required String dueDate,
    required String category,
    required List<String> splitBetween,
    required String createdBy,
  }) async {
    try {
      final doc = await _col.add({
        'houseId': _houseId,
        'title': title,
        'amount': amount,
        'dueDate': dueDate,
        'category': category,
        'splitBetween': splitBetween,
        'paid': false,
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
      });
      NotificationService.instance.scheduleBillReminders(
        billId: doc.id,
        billTitle: title,
        dueDate: dueDate,
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> togglePaid(String billId, bool paid, {String? paidBy, BillModel? bill}) async {
    try {
      await _col.doc(billId).update({
        'paid': paid,
        'paidBy': paid ? paidBy : null,
      });
      if (paid) {
        NotificationService.instance.cancelBillReminders(billId);
      } else if (bill != null) {
        NotificationService.instance.scheduleBillReminders(
          billId: bill.id,
          billTitle: bill.title,
          dueDate: bill.dueDate,
        );
      }
    } catch (_) {}
  }

  Future<String?> updateBill({
    required String billId,
    required String title,
    required double amount,
    required String dueDate,
    required String category,
    required List<String> splitBetween,
  }) async {
    try {
      await _col.doc(billId).update({
        'title': title,
        'amount': amount,
        'dueDate': dueDate,
        'category': category,
        'splitBetween': splitBetween,
      });
      NotificationService.instance.scheduleBillReminders(
        billId: billId,
        billTitle: title,
        dueDate: dueDate,
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteBill(String billId) async {
    try {
      await _col.doc(billId).delete();
      NotificationService.instance.cancelBillReminders(billId);
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

final billsProvider =
    StateNotifierProvider<BillsNotifier, AsyncValue<List<BillModel>>>((ref) {
  final houseId = ref.watch(authProvider).currentHouse?.id ?? '';
  return BillsNotifier(houseId);
});
