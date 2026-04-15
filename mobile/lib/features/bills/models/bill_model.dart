import 'package:cloud_firestore/cloud_firestore.dart';

class BillModel {
  final String id;
  final String houseId;
  final String title;
  final double amount;
  final String dueDate;
  final bool paid;
  final String? paidBy;
  final List<String> splitBetween;
  final String category;
  final String? createdBy;
  final String createdAt;

  const BillModel({
    required this.id,
    required this.houseId,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.paid,
    this.paidBy,
    required this.splitBetween,
    required this.category,
    this.createdBy,
    required this.createdAt,
  });

  factory BillModel.fromMap(String id, Map<String, dynamic> map) {
    return BillModel(
      id: id,
      houseId: map['houseId'] as String? ?? '',
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      dueDate: map['dueDate'] as String,
      paid: map['paid'] as bool? ?? false,
      paidBy: map['paidBy'] as String?,
      splitBetween: List<String>.from(map['splitBetween'] as List? ?? []),
      category: map['category'] as String? ?? 'other',
      createdBy: map['createdBy'] as String?,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate().toIso8601String()
          : (map['createdAt'] as String? ?? ''),
    );
  }

  double get perPerson =>
      splitBetween.isEmpty ? amount : amount / splitBetween.length;
}
