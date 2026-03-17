class Product {
  final String id;
  final String name;
  final String unit;
  final double price;
  final int stock;
  final String barcode;
  final String category;

  Product({
    required this.id,
    required this.name,
    required this.unit,
    required this.price,
    required this.stock,
    this.barcode = '',
    this.category = '',
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        unit: json['unit'] as String? ?? 'قطعة',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        stock: (json['stock'] as num?)?.toInt() ?? 0,
        barcode: json['barcode'] as String? ?? '',
        category: json['category'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'unit': unit,
        'price': price,
        'stock': stock,
        'barcode': barcode,
        'category': category,
      };
}
