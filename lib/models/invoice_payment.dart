class InvoicePayment {
  final String id;
  final String invoiceId;
  final String invoiceNumber;
  final String customerId;
  final String customerName;
  final double amount;
  final String notes;
  final DateTime createdAt;

  const InvoicePayment({
    required this.id,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.customerId,
    required this.customerName,
    required this.amount,
    required this.notes,
    required this.createdAt,
  });

  factory InvoicePayment.fromJson(Map<String, dynamic> json) => InvoicePayment(
        id: json['id'] as String? ?? '',
        invoiceId: json['invoiceId'] as String? ?? '',
        invoiceNumber: json['invoiceNumber'] as String? ?? '',
        customerId: json['customerId'] as String? ?? '',
        customerName: json['customerName'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        notes: json['notes'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'invoiceId': invoiceId,
        'invoiceNumber': invoiceNumber,
        'customerId': customerId,
        'customerName': customerName,
        'amount': amount,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };
}
