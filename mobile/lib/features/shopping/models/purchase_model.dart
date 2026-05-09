import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseModel {
  final String id;
  final String houseId;
  final String store;
  final String date;
  final double total;
  final List<String> splitBetween;
  final String? paidBy;
  final String? note;
  final String createdBy;
  final String createdAt;

  const PurchaseModel({
    required this.id,
    required this.houseId,
    required this.store,
    required this.date,
    required this.total,
    required this.splitBetween,
    this.paidBy,
    this.note,
    required this.createdBy,
    required this.createdAt,
  });

  factory PurchaseModel.fromMap(String id, Map<String, dynamic> map) {
    return PurchaseModel(
      id: id,
      houseId: map['houseId'] as String? ?? '',
      store: map['store'] as String? ?? '',
      date: map['date'] as String? ?? '',
      total: (map['total'] as num?)?.toDouble() ?? 0,
      splitBetween: (map['splitBetween'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      paidBy: map['paidBy'] as String?,
      note: map['note'] as String?,
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate().toIso8601String()
          : (map['createdAt'] as String? ?? ''),
    );
  }

  double get amountPerPerson =>
      splitBetween.isEmpty ? total : total / splitBetween.length;
}
