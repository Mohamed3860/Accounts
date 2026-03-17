class Supplier {
  final String id;
  final String name;
  final String phone;
  final String address;

  Supplier({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) => Supplier(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        address: json['address'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'address': address,
      };
}
