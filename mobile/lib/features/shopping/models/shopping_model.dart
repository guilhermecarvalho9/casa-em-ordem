class ShoppingItemModel {
  final String id;
  final String houseId;
  final String name;
  final int quantity;
  final bool bought;
  final String? addedBy;
  final String? boughtBy;
  final double? price;
  final String createdAt;

  const ShoppingItemModel({
    required this.id,
    required this.houseId,
    required this.name,
    required this.quantity,
    required this.bought,
    this.addedBy,
    this.boughtBy,
    this.price,
    required this.createdAt,
  });

  factory ShoppingItemModel.fromMap(Map<String, dynamic> map) {
    return ShoppingItemModel(
      id: map['id'] as String,
      houseId: map['house_id'] as String,
      name: map['name'] as String,
      quantity: map['quantity'] as int? ?? 1,
      bought: map['bought'] as bool? ?? false,
      addedBy: map['added_by'] as String?,
      boughtBy: map['bought_by'] as String?,
      price: map['price'] != null ? (map['price'] as num).toDouble() : null,
      createdAt: map['created_at'] as String? ?? '',
    );
  }
}
