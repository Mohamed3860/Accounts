import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/customer.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/invoice_payment.dart';
import '../models/product.dart';
import '../models/rep_settings.dart';
import '../models/supplier.dart';

class AppState extends ChangeNotifier {
  final List<Customer> customers = [];
  final List<Supplier> suppliers = [];
  final List<Product> products = [];
  final List<String> categories = [];
  final List<Invoice> invoices = [];
  final List<InvoicePayment> payments = [];

  bool isLoading = true;
  RepSettings repSettings = const RepSettings();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    customers
      ..clear()
      ..addAll(_decodeList(prefs.getString('customers')).map(Customer.fromJson));

    suppliers
      ..clear()
      ..addAll(_decodeList(prefs.getString('suppliers')).map(Supplier.fromJson));

    products
      ..clear()
      ..addAll(_decodeList(prefs.getString('products')).map(Product.fromJson));

    categories
      ..clear()
      ..addAll(
        (prefs.getStringList('categories') ?? [])
            .where((e) => e.trim().isNotEmpty),
      );

    invoices
      ..clear()
      ..addAll(_decodeList(prefs.getString('invoices')).map(Invoice.fromJson));

    payments
      ..clear()
      ..addAll(
        _decodeList(prefs.getString('payments')).map(InvoicePayment.fromJson),
      );

    final settingsRaw = prefs.getString('repSettings');
    if (settingsRaw != null && settingsRaw.isNotEmpty) {
      repSettings = RepSettings.fromJson(
        Map<String, dynamic>.from(jsonDecode(settingsRaw) as Map),
      );
    }

    if (products.isEmpty &&
        customers.isEmpty &&
        suppliers.isEmpty &&
        invoices.isEmpty) {
      _seed();
      await save();
    } else {
      _migratePaymentsIfNeeded();
      _normalizeInvoiceStatuses();
      await save();
    }

    isLoading = false;
    notifyListeners();
  }

  List<Map<String, dynamic>> _decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    final parsed = jsonDecode(raw) as List<dynamic>;
    return parsed
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Map<String, dynamic> exportData() => {
        'customers': customers.map((e) => e.toJson()).toList(),
        'suppliers': suppliers.map((e) => e.toJson()).toList(),
        'products': products.map((e) => e.toJson()).toList(),
        'categories': categories,
        'invoices': invoices.map((e) => e.toJson()).toList(),
        'payments': payments.map((e) => e.toJson()).toList(),
        'repSettings': repSettings.toJson(),
        'exportedAt': DateTime.now().toIso8601String(),
      };

  Future<void> importData(Map<String, dynamic> data) async {
    customers
      ..clear()
      ..addAll(
        ((data['customers'] as List?) ?? [])
            .map((e) => Customer.fromJson(Map<String, dynamic>.from(e as Map))),
      );

    suppliers
      ..clear()
      ..addAll(
        ((data['suppliers'] as List?) ?? [])
            .map((e) => Supplier.fromJson(Map<String, dynamic>.from(e as Map))),
      );

    products
      ..clear()
      ..addAll(
        ((data['products'] as List?) ?? [])
            .map((e) => Product.fromJson(Map<String, dynamic>.from(e as Map))),
      );

    categories
      ..clear()
      ..addAll(
        ((data['categories'] as List?) ?? []).map((e) => e.toString()),
      );

    invoices
      ..clear()
      ..addAll(
        ((data['invoices'] as List?) ?? [])
            .map((e) => Invoice.fromJson(Map<String, dynamic>.from(e as Map))),
      );

    payments
      ..clear()
      ..addAll(
        ((data['payments'] as List?) ?? []).map(
          (e) => InvoicePayment.fromJson(Map<String, dynamic>.from(e as Map)),
        ),
      );

    repSettings = RepSettings.fromJson(
      Map<String, dynamic>.from(
        (data['repSettings'] as Map?) ?? <String, dynamic>{},
      ),
    );

    _migratePaymentsIfNeeded();
    _normalizeInvoiceStatuses();
    await save();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'customers',
      jsonEncode(customers.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      'suppliers',
      jsonEncode(suppliers.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      'products',
      jsonEncode(products.map((e) => e.toJson()).toList()),
    );
    await prefs.setStringList('categories', categories);
    await prefs.setString(
      'invoices',
      jsonEncode(invoices.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      'payments',
      jsonEncode(payments.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      'repSettings',
      jsonEncode(repSettings.toJson()),
    );

    notifyListeners();
  }

  Future<void> updateRepSettings(RepSettings value) async {
    repSettings = value;
    await save();
  }

  String newId() =>
      '${DateTime.now().microsecondsSinceEpoch}${Random().nextInt(999)}';

  String nextInvoiceNumber() => '${invoices.length + 1}';

  Future<void> addCustomer(Customer item) async {
    customers.insert(0, item);
    await save();
  }

  Future<void> addSupplier(Supplier item) async {
    suppliers.insert(0, item);
    await save();
  }

  Future<void> addProduct(Product item) async {
    products.insert(0, item);
    if (item.category.trim().isNotEmpty &&
        !categories.contains(item.category.trim())) {
      categories.insert(0, item.category.trim());
    }
    await save();
  }

  Future<void> addCategory(String name) async {
    final value = name.trim();
    if (value.isEmpty || categories.contains(value)) return;
    categories.insert(0, value);
    await save();
  }

  Future<void> deleteCategory(String name) async {
    categories.remove(name);
    await save();
  }

  Future<void> deleteCustomer(String id) async {
    customers.removeWhere((e) => e.id == id);
    final customerInvoiceIds =
        invoices.where((e) => e.customerId == id).map((e) => e.id).toList();
    payments.removeWhere(
      (e) => e.customerId == id || customerInvoiceIds.contains(e.invoiceId),
    );
    invoices.removeWhere((e) => e.customerId == id);
    await save();
  }

  Future<void> deleteSupplier(String id) async {
    suppliers.removeWhere((e) => e.id == id);
    await save();
  }

  Future<void> deleteProduct(String id) async {
    products.removeWhere((e) => e.id == id);
    await save();
  }

  Future<void> addInvoice({
    required Customer customer,
    required List<InvoiceItem> items,
    required double taxPercent,
    required double taxValue,
    required double discount,
    required bool discountIsPercent,
    required double paidAmount,
    required String notes,
    String? companyName,
  }) async {
    final normalizedItems = List<InvoiceItem>.from(items);

    final subtotal = normalizedItems.fold<double>(
      0.0,
      (sum, item) => sum + item.total,
    );

    final discountValue =
        discountIsPercent ? (subtotal * (discount / 100.0)) : discount;

    final safeDiscount = discountValue.clamp(0.0, subtotal).toDouble();
    final safeTaxValue = taxValue < 0 ? 0.0 : taxValue;
    final total = (subtotal - safeDiscount + safeTaxValue)
        .clamp(0.0, double.infinity)
        .toDouble();
    final safePaid = paidAmount.clamp(0.0, total).toDouble();

    final requested = <String, int>{};
    for (final item in normalizedItems) {
      requested[item.productId] =
          (requested[item.productId] ?? 0) + item.quantity;
    }

    final insufficient = <String>[];
    requested.forEach((productId, qty) {
      Product? product;
      try {
        product = products.firstWhere((e) => e.id == productId);
      } catch (_) {
        product = null;
      }

      if (product == null || product.stock < qty) {
        insufficient.add(product?.name ?? 'منتج غير معروف');
      }
    });

    if (insufficient.isNotEmpty) {
      throw StateError(
        'الكمية المتاحة غير كافية للمنتجات: ${insufficient.join('، ')}',
      );
    }

    final preview = Invoice(
      id: newId(),
      number: nextInvoiceNumber(),
      customerId: customer.id,
      customerName: customer.name,
      customerPhone: customer.phone,
      createdAt: DateTime.now(),
      items: normalizedItems,
      taxPercent: taxPercent < 0 ? 0.0 : taxPercent,
      taxValue: safeTaxValue,
      discount: discountIsPercent
          ? (safeDiscount == 0.0 || subtotal == 0.0
              ? discount
              : (safeDiscount / subtotal) * 100.0)
          : safeDiscount,
      discountIsPercent: discountIsPercent,
      paidAmount: safePaid,
      status: _resolveStatus(total, safePaid),
      notes: notes,
      companyName: companyName ?? repSettings.repName,
      repName: repSettings.repName,
      ownerName: repSettings.ownerName,
      repPhone: repSettings.phone,
      repEmail: repSettings.email,
      repAddress: repSettings.address,
      taxNumber: repSettings.taxNumber,
      signature: repSettings.signature,
    );

    for (final item in normalizedItems) {
      final idx = products.indexWhere((e) => e.id == item.productId);
      if (idx != -1) {
        final existing = products[idx];
        products[idx] = Product(
          id: existing.id,
          name: existing.name,
          unit: existing.unit,
          price: existing.price,
          stock: existing.stock - item.quantity,
          barcode: existing.barcode,
          category: existing.category,
        );
      }
    }

    invoices.insert(0, preview);

    if (safePaid > 0.0) {
      payments.insert(
        0,
        InvoicePayment(
          id: newId(),
          invoiceId: preview.id,
          invoiceNumber: preview.number,
          customerId: preview.customerId,
          customerName: preview.customerName,
          amount: safePaid,
          notes: 'دفعة أولية للفاتورة رقم ${preview.number}',
          createdAt: preview.createdAt,
        ),
      );
    }

    await save();
  }

  double totalFrom(
    List<InvoiceItem> items,
    double taxValue,
    double discount,
    bool discountIsPercent,
  ) {
    final subtotal = items.fold<double>(
      0.0,
      (sum, item) => sum + item.total,
    );

    final discountValue =
        discountIsPercent ? (subtotal * (discount / 100.0)) : discount;

    final safeDiscount = discountValue.clamp(0.0, subtotal).toDouble();
    final safeTax = taxValue < 0 ? 0.0 : taxValue;

    return (subtotal - safeDiscount + safeTax)
        .clamp(0.0, double.infinity)
        .toDouble();
  }

  String _resolveStatus(double total, double paid) {
    if (paid <= 0.0) return 'غير مدفوعة';
    if (paid >= total) return 'مدفوعة';
    return 'مدفوعة جزئياً';
  }

  Future<void> addPayment({
    required String invoiceId,
    required double amount,
    String notes = '',
    DateTime? createdAt,
  }) async {
    final invoiceIndex = invoices.indexWhere((e) => e.id == invoiceId);
    if (invoiceIndex == -1) {
      throw StateError('الفاتورة غير موجودة');
    }

    final invoice = invoices[invoiceIndex];
    final safeAmount = amount.clamp(0.0, invoice.remaining).toDouble();

    if (safeAmount <= 0.0) {
      throw StateError('المبلغ المدخل غير صالح');
    }

    final newPaid = (invoice.paidAmount + safeAmount)
        .clamp(0.0, invoice.total)
        .toDouble();

    invoices[invoiceIndex] = invoice.copyWith(
      paidAmount: newPaid,
      status: _resolveStatus(invoice.total, newPaid),
    );

    payments.insert(
      0,
      InvoicePayment(
        id: newId(),
        invoiceId: invoice.id,
        invoiceNumber: invoice.number,
        customerId: invoice.customerId,
        customerName: invoice.customerName,
        amount: safeAmount,
        notes: notes.trim().isEmpty
            ? 'دفعة للفاتورة رقم ${invoice.number}'
            : notes.trim(),
        createdAt: createdAt ?? DateTime.now(),
      ),
    );

    await save();
  }

  Future<void> updatePayment({
    required String paymentId,
    required String invoiceId,
    required double amount,
    required String notes,
  }) async {
    final paymentIndex = payments.indexWhere((e) => e.id == paymentId);
    if (paymentIndex == -1) {
      throw StateError('الدفعة غير موجودة');
    }

    final old = payments[paymentIndex];
    _rollbackPaymentOnInvoice(old);

    final invoiceIndex = invoices.indexWhere((e) => e.id == invoiceId);
    if (invoiceIndex == -1) {
      _applyPaymentOnInvoice(old);
      throw StateError('الفاتورة غير موجودة');
    }

    final invoice = invoices[invoiceIndex];
    final safeAmount = amount.clamp(0.0, invoice.remaining).toDouble();

    if (safeAmount <= 0.0) {
      _applyPaymentOnInvoice(old);
      throw StateError('المبلغ المدخل غير صالح');
    }

    final updatedPayment = InvoicePayment(
      id: old.id,
      invoiceId: invoice.id,
      invoiceNumber: invoice.number,
      customerId: invoice.customerId,
      customerName: invoice.customerName,
      amount: safeAmount,
      notes: notes.trim().isEmpty
          ? 'دفعة للفاتورة رقم ${invoice.number}'
          : notes.trim(),
      createdAt: old.createdAt,
    );

    payments[paymentIndex] = updatedPayment;
    _applyPaymentOnInvoice(updatedPayment);
    await save();
  }

  Future<void> deletePayment(String paymentId) async {
    final paymentIndex = payments.indexWhere((e) => e.id == paymentId);
    if (paymentIndex == -1) return;

    final payment = payments.removeAt(paymentIndex);
    _rollbackPaymentOnInvoice(payment);
    await save();
  }

  void _applyPaymentOnInvoice(InvoicePayment payment) {
    final invoiceIndex = invoices.indexWhere((e) => e.id == payment.invoiceId);
    if (invoiceIndex == -1) return;

    final invoice = invoices[invoiceIndex];
    final newPaid = (invoice.paidAmount + payment.amount)
        .clamp(0.0, invoice.total)
        .toDouble();

    invoices[invoiceIndex] = invoice.copyWith(
      paidAmount: newPaid,
      status: _resolveStatus(invoice.total, newPaid),
    );
  }

  void _rollbackPaymentOnInvoice(InvoicePayment payment) {
    final invoiceIndex = invoices.indexWhere((e) => e.id == payment.invoiceId);
    if (invoiceIndex == -1) return;

    final invoice = invoices[invoiceIndex];
    final newPaid = max<double>(0.0, invoice.paidAmount - payment.amount);

    invoices[invoiceIndex] = invoice.copyWith(
      paidAmount: newPaid,
      status: _resolveStatus(invoice.total, newPaid),
    );
  }

  Future<void> deleteInvoice(String id) async {
    final index = invoices.indexWhere((e) => e.id == id);
    if (index == -1) return;

    final invoice = invoices.removeAt(index);
    payments.removeWhere((e) => e.invoiceId == invoice.id);

    for (final item in invoice.items) {
      final productIndex = products.indexWhere((e) => e.id == item.productId);
      if (productIndex != -1) {
        final existing = products[productIndex];
        products[productIndex] = Product(
          id: existing.id,
          name: existing.name,
          unit: existing.unit,
          price: existing.price,
          stock: existing.stock + item.quantity,
          barcode: existing.barcode,
          category: existing.category,
        );
      }
    }

    await save();
  }

  double get totalSales => invoices.fold<double>(
        0.0,
        (sum, inv) => sum + inv.total,
      );

  double get totalPaid => invoices.fold<double>(
        0.0,
        (sum, inv) => sum + inv.paidAmount,
      );

  double get totalOutstanding => invoices.fold<double>(
        0.0,
        (sum, inv) => sum + max<double>(0.0, inv.remaining),
      );

  int get invoiceCount => invoices.length;
  int get customerCount => customers.length;
  int get productCount => products.length;

  int invoiceCountForCustomer(String customerId) =>
      invoices.where((e) => e.customerId == customerId).length;

  double outstandingForCustomer(String customerId) => invoices
      .where((e) => e.customerId == customerId)
      .fold<double>(
        0.0,
        (sum, inv) => sum + max<double>(0.0, inv.remaining),
      );

  double totalSalesForCustomer(String customerId) => invoices
      .where((e) => e.customerId == customerId)
      .fold<double>(0.0, (sum, inv) => sum + inv.total);

  double totalPaidForCustomer(String customerId) => invoices
      .where((e) => e.customerId == customerId)
      .fold<double>(0.0, (sum, inv) => sum + inv.paidAmount);

  List<Invoice> invoicesForCustomer(String customerId) {
    final list = invoices.where((e) => e.customerId == customerId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<InvoicePayment> paymentsForCustomer(String customerId) {
    final list = payments.where((e) => e.customerId == customerId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<Directory> _backupDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final backup = Directory('${dir.path}/backups');
    if (!await backup.exists()) {
      await backup.create(recursive: true);
    }
    return backup;
  }

  Future<List<FileSystemEntity>> listBackupFiles() async {
    final dir = await _backupDir();
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList();

    files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    return files;
  }

  Future<File> createBackup() async {
    final dir = await _backupDir();
    final file = File(
      '${dir.path}/backup_${DateTime.now().millisecondsSinceEpoch}.json',
    );
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(exportData()),
    );
    return file;
  }

  Future<bool> restoreFromExternalFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) return false;

    final file = File(result.files.single.path!);
    final raw = await file.readAsString();
    final data = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    await importData(data);
    return true;
  }

  Future<void> clearAll() async {
    customers.clear();
    suppliers.clear();
    products.clear();
    categories.clear();
    invoices.clear();
    payments.clear();
    repSettings = const RepSettings();
    _seed();
    await save();
  }

  void _migratePaymentsIfNeeded() {
    final hasPersistedPayments = payments.isNotEmpty;
    if (!hasPersistedPayments) {
      for (final invoice in invoices) {
        if (invoice.paidAmount > 0.0) {
          payments.add(
            InvoicePayment(
              id: newId(),
              invoiceId: invoice.id,
              invoiceNumber: invoice.number,
              customerId: invoice.customerId,
              customerName: invoice.customerName,
              amount: invoice.paidAmount,
              notes: 'دفعة مسجلة سابقاً للفاتورة رقم ${invoice.number}',
              createdAt: invoice.createdAt,
            ),
          );
        }
      }
    }
  }

  void _normalizeInvoiceStatuses() {
    for (var i = 0; i < invoices.length; i++) {
      final invoice = invoices[i];
      final paid = invoice.paidAmount.clamp(0.0, invoice.total).toDouble();
      invoices[i] = invoice.copyWith(
        paidAmount: paid,
        status: _resolveStatus(invoice.total, paid),
      );
    }
  }

  void _seed() {
    repSettings = const RepSettings(
      repName: 'اسم المندوب',
      phone: '01000000000',
      address: 'القاهرة',
      notes: 'شكراً لتعاملكم معنا',
    );

    final c1 = Customer(
      id: newId(),
      name: 'عميل نقدي',
      phone: '01094932665',
      email: '',
      address: 'بني عبيد دقهلية',
    );

    final s1 = Supplier(
      id: newId(),
      name: 'مورد افتراضي',
      phone: '01111111111',
      address: 'الجيزة',
    );

    categories.addAll(['عام', 'إكسسوارات']);

    final p1 = Product(
      id: newId(),
      name: 'كليفر بيوني',
      unit: 'قطعة',
      price: 125.0,
      stock: 1000,
      category: 'عام',
      barcode: '123456789',
    );

    customers.add(c1);
    suppliers.add(s1);
    products.add(p1);

    final seededInvoice = Invoice(
      id: newId(),
      number: '1',
      customerId: c1.id,
      customerName: c1.name,
      customerPhone: c1.phone,
      createdAt: DateTime.now(),
      items: [
        InvoiceItem(
          productId: p1.id,
          name: p1.name,
          price: p1.price,
          quantity: 50,
        ),
      ],
      taxPercent: 0.0,
      taxValue: 0.0,
      discount: 0.0,
      discountIsPercent: false,
      paidAmount: 5000.0,
      status: 'مدفوعة جزئياً',
      notes: 'فاتورة تجريبية',
      companyName: repSettings.repName,
      repName: repSettings.repName,
      repPhone: repSettings.phone,
      repAddress: repSettings.address,
    );

    invoices.add(seededInvoice);

    products[0] = Product(
      id: p1.id,
      name: p1.name,
      unit: p1.unit,
      price: p1.price,
      stock: p1.stock - 50,
      barcode: p1.barcode,
      category: p1.category,
    );

    payments.add(
      InvoicePayment(
        id: newId(),
        invoiceId: seededInvoice.id,
        invoiceNumber: seededInvoice.number,
        customerId: seededInvoice.customerId,
        customerName: seededInvoice.customerName,
        amount: 5000.0,
        notes: 'دفعة أولية للفاتورة رقم 1',
        createdAt: seededInvoice.createdAt,
      ),
    );
  }
}
