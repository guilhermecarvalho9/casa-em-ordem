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

  factory BillModel.fromMap(Map<String, dynamic> map) {
    return BillModel(
      id: map['id'] as String,
      houseId: map['house_id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      dueDate: map['due_date'] as String,
      paid: map['paid'] as bool? ?? false,
      paidBy: map['paid_by'] as String?,
      splitBetween: List<String>.from(map['split_between'] as List? ?? []),
      category: map['category'] as String? ?? 'other',
      createdBy: map['created_by'] as String?,
      createdAt: map['created_at'] as String? ?? '',
    );
  }

  double get perPerson =>
      splitBetween.isEmpty ? amount : amount / splitBetween.length;
}
