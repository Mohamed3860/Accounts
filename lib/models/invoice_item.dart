class InvoiceItem {
  final String productId;
  final String name;
  final double price;
  final int quantity;

  InvoiceItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  double get total => price * quantity;

  factory InvoiceItem.fromJson(Map<String, dynamic> json) => InvoiceItem(
        productId: json['productId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        quantity: json['quantity'] as int? ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'price': price,
        'quantity': quantity,
      };
}
