import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bill_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/services/notification_service.dart';
import '../../../shared/services/house_notification_service.dart';

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

  String _nextDueDate(String currentDueDate, String frequency) {
    final date = DateTime.parse(currentDueDate);
    final DateTime next;
    if (frequency == 'weekly') {
      next = date.add(const Duration(days: 7));
    } else if (frequency == 'biweekly') {
      next = date.add(const Duration(days: 14));
    } else if (frequency == 'yearly') {
      next = DateTime(date.year + 1, date.month, date.day);
    } else {
      // monthly (default)
      next = DateTime(date.year, date.month + 1, date.day);
    }
    return next.toIso8601String().split('T').first;
  }

  Future<String?> addBill({
    required String title,
    required double amount,
    required String dueDate,
    required String category,
    required List<String> splitBetween,
    required String createdBy,
    String creatorName = '',
    bool isRecurring = false,
    String? recurringFrequency,
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
        if (isRecurring) 'isRecurring': true,
        if (isRecurring && recurringFrequency != null) 'recurringFrequency': recurringFrequency,
      });
      NotificationService.instance.scheduleBillReminders(
        billId: doc.id,
        billTitle: title,
        dueDate: dueDate,
      );
      final name = creatorName.isNotEmpty ? creatorName : 'Alguém';
      if (splitBetween.isNotEmpty) {
        HouseNotificationService.billSplitAdded(
          houseId: _houseId,
          createdBy: createdBy,
          creatorName: name,
          billTitle: title,
        );
      } else {
        HouseNotificationService.billAdded(
          houseId: _houseId,
          createdBy: createdBy,
          creatorName: name,
          billTitle: title,
          amount: amount,
        );
      }
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
        // Auto-create next occurrence for recurring bills
        if (bill != null && bill.isRecurring && bill.recurringFrequency != null) {
          final nextDue = _nextDueDate(bill.dueDate, bill.recurringFrequency!);
          await _col.add({
            'houseId': _houseId,
            'title': bill.title,
            'amount': bill.amount,
            'dueDate': nextDue,
            'category': bill.category,
            'splitBetween': bill.splitBetween,
            'paid': false,
            'createdBy': bill.createdBy ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'isRecurring': true,
            'recurringFrequency': bill.recurringFrequency,
          });
        }
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
    bool isRecurring = false,
    String? recurringFrequency,
  }) async {
    try {
      await _col.doc(billId).update({
        'title': title,
        'amount': amount,
        'dueDate': dueDate,
        'category': category,
        'splitBetween': splitBetween,
        'isRecurring': isRecurring,
        if (isRecurring && recurringFrequency != null)
          'recurringFrequency': recurringFrequency
        else
          'recurringFrequency': FieldValue.delete(),
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
