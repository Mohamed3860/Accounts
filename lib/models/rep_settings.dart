class RepSettings {
  final String repName;
  final String ownerName;
  final String taxNumber;
  final String phone;
  final String email;
  final String address;
  final String notes;
  final double taxPercent;
  final String signature;

  const RepSettings({
    this.repName = 'اسم المندوب',
    this.ownerName = '',
    this.taxNumber = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.notes = '',
    this.taxPercent = 0,
    this.signature = '',
  });

  RepSettings copyWith({
    String? repName,
    String? ownerName,
    String? taxNumber,
    String? phone,
    String? email,
    String? address,
    String? notes,
    double? taxPercent,
    String? signature,
  }) {
    return RepSettings(
      repName: repName ?? this.repName,
      ownerName: ownerName ?? this.ownerName,
      taxNumber: taxNumber ?? this.taxNumber,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      taxPercent: taxPercent ?? this.taxPercent,
      signature: signature ?? this.signature,
    );
  }

  factory RepSettings.fromJson(Map<String, dynamic> json) => RepSettings(
        repName: json['repName'] as String? ?? 'اسم المندوب',
        ownerName: json['ownerName'] as String? ?? '',
        taxNumber: json['taxNumber'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String? ?? '',
        address: json['address'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        taxPercent: (json['taxPercent'] as num?)?.toDouble() ?? 0,
        signature: json['signature'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'repName': repName,
        'ownerName': ownerName,
        'taxNumber': taxNumber,
        'phone': phone,
        'email': email,
        'address': address,
        'notes': notes,
        'taxPercent': taxPercent,
        'signature': signature,
      };
}
