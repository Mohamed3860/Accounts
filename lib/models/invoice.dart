import 'invoice_item.dart';

class Invoice {
  final String id;
  final String number;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final DateTime createdAt;
  final List<InvoiceItem> items;
  final double taxPercent;
  final double taxValue;
  final double discount;
  final bool discountIsPercent;
  final double paidAmount;
  final String status;
  final String notes;
  final String companyName;
  final String repName;
  final String ownerName;
  final String repPhone;
  final String repEmail;
  final String repAddress;
  final String taxNumber;
  final String signature;

  Invoice({
    required this.id,
    required this.number,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.createdAt,
    required this.items,
    required this.taxPercent,
    required this.taxValue,
    required this.discount,
    required this.discountIsPercent,
    required this.paidAmount,
    required this.status,
    required this.notes,
    this.companyName = 'اسم المندوب',
    this.repName = 'اسم المندوب',
    this.ownerName = '',
    this.repPhone = '',
    this.repEmail = '',
    this.repAddress = '',
    this.taxNumber = '',
    this.signature = '',
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);

  double get discountValue {
    if (discountIsPercent) {
      return subtotal * (discount / 100);
    }
    return discount;
  }

  double get total => subtotal - discountValue + taxValue;
  double get remaining => total - paidAmount;


  Invoice copyWith({
    String? id,
    String? number,
    String? customerId,
    String? customerName,
    String? customerPhone,
    DateTime? createdAt,
    List<InvoiceItem>? items,
    double? taxPercent,
    double? taxValue,
    double? discount,
    bool? discountIsPercent,
    double? paidAmount,
    String? status,
    String? notes,
    String? companyName,
    String? repName,
    String? ownerName,
    String? repPhone,
    String? repEmail,
    String? repAddress,
    String? taxNumber,
    String? signature,
  }) => Invoice(
        id: id ?? this.id,
        number: number ?? this.number,
        customerId: customerId ?? this.customerId,
        customerName: customerName ?? this.customerName,
        customerPhone: customerPhone ?? this.customerPhone,
        createdAt: createdAt ?? this.createdAt,
        items: items ?? this.items,
        taxPercent: taxPercent ?? this.taxPercent,
        taxValue: taxValue ?? this.taxValue,
        discount: discount ?? this.discount,
        discountIsPercent: discountIsPercent ?? this.discountIsPercent,
        paidAmount: paidAmount ?? this.paidAmount,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        companyName: companyName ?? this.companyName,
        repName: repName ?? this.repName,
        ownerName: ownerName ?? this.ownerName,
        repPhone: repPhone ?? this.repPhone,
        repEmail: repEmail ?? this.repEmail,
        repAddress: repAddress ?? this.repAddress,
        taxNumber: taxNumber ?? this.taxNumber,
        signature: signature ?? this.signature,
      );

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
        id: json['id'] as String,
        number: json['number'] as String? ?? '',
        customerId: json['customerId'] as String? ?? '',
        customerName: json['customerName'] as String? ?? '',
        customerPhone: json['customerPhone'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        items: ((json['items'] as List?) ?? [])
            .map((e) => InvoiceItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        taxPercent: (json['taxPercent'] as num?)?.toDouble() ?? 0,
        taxValue: (json['taxValue'] as num?)?.toDouble() ?? 0,
        discount: (json['discount'] as num?)?.toDouble() ?? 0,
        discountIsPercent: json['discountIsPercent'] as bool? ?? false,
        paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
        status: json['status'] as String? ?? 'غير مدفوعة',
        notes: json['notes'] as String? ?? '',
        companyName: json['companyName'] as String? ?? json['repName'] as String? ?? 'اسم المندوب',
        repName: json['repName'] as String? ?? json['companyName'] as String? ?? 'اسم المندوب',
        ownerName: json['ownerName'] as String? ?? '',
        repPhone: json['repPhone'] as String? ?? '',
        repEmail: json['repEmail'] as String? ?? '',
        repAddress: json['repAddress'] as String? ?? '',
        taxNumber: json['taxNumber'] as String? ?? '',
        signature: json['signature'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'customerId': customerId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'createdAt': createdAt.toIso8601String(),
        'items': items.map((e) => e.toJson()).toList(),
        'taxPercent': taxPercent,
        'taxValue': taxValue,
        'discount': discount,
        'discountIsPercent': discountIsPercent,
        'paidAmount': paidAmount,
        'status': status,
        'notes': notes,
        'companyName': companyName,
        'repName': repName,
        'ownerName': ownerName,
        'repPhone': repPhone,
        'repEmail': repEmail,
        'repAddress': repAddress,
        'taxNumber': taxNumber,
        'signature': signature,
      };
}
