import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/customer.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/product.dart';
import '../services/app_state.dart';
import '../widgets/empty_state.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = 'الكل';
  String _sort = 'التاريخ (الأحدث)';

  static const List<String> _filters = ['الكل', 'مدفوعة', 'مدفوعة جزئياً', 'غير مدفوعة'];
  static const List<String> _sorts = ['التاريخ (الأحدث)', 'التاريخ (الأقدم)', 'الأعلى مبلغ', 'الأقل مبلغ'];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final invoices = _buildInvoices(state);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      _SquareActionButton(
                        icon: Icons.add,
                        onTap: () => _openCreateInvoice(context),
                      ),
                      const SizedBox(width: 10),
                      _SquareActionButton(
                        icon: Icons.qr_code_2_outlined,
                        onTap: () => _showQrInfo(context),
                      ),
                      const Spacer(),
                      const Text(
                        'الفواتير',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'بحث في الفواتير (العميل، الرقم، المبلغ)',
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF2F5ED7), size: 34),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 52,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _SortPill(
                          label: _sort,
                          selected: false,
                          icon: Icons.sort_rounded,
                          onTap: () => _pickSort(context),
                        ),
                        const SizedBox(width: 10),
                        for (final item in _filters) ...[
                          _SortPill(
                            label: item,
                            selected: item == _filter,
                            onTap: () => setState(() => _filter = item),
                          ),
                          const SizedBox(width: 10),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: invoices.isEmpty
                  ? const EmptyState(title: 'لا يوجد فواتير', subtitle: '')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
                      itemCount: invoices.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final invoice = invoices[index];
                        return _InvoiceCard(
                          invoice: invoice,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => InvoiceDetailsScreen(invoice: invoice)),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Invoice> _buildInvoices(AppState state) {
    final q = _searchController.text.trim();
    var items = state.invoices.where((invoice) {
      final matchesFilter = _filter == 'الكل' || invoice.status == _filter;
      if (!matchesFilter) return false;
      if (q.isEmpty) return true;
      return invoice.customerName.contains(q) ||
          invoice.number.contains(q) ||
          invoice.total.toStringAsFixed(2).contains(q);
    }).toList();

    switch (_sort) {
      case 'التاريخ (الأقدم)':
        items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'الأعلى مبلغ':
        items.sort((a, b) => b.total.compareTo(a.total));
        break;
      case 'الأقل مبلغ':
        items.sort((a, b) => a.total.compareTo(b.total));
        break;
      default:
        items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return items;
  }

  Future<void> _pickSort(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ترتيب حسب', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                const SizedBox(height: 20),
                for (final item in _sorts)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item, style: const TextStyle(fontSize: 18)),
                    leading: Icon(
                      _sort == item ? Icons.check_rounded : Icons.circle_outlined,
                      color: _sort == item ? const Color(0xFF2F5ED7) : Colors.transparent,
                    ),
                    onTap: () => Navigator.pop(context, item),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (result != null) {
      setState(() => _sort = result);
    }
  }


  void _showQrInfo(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إضافة دعم QR داخل عرض الفاتورة وإنشاء الفاتورة.')),
    );
  }

  Future<void> _openCreateInvoice(BuildContext context) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
    );
    if (created == true && mounted) {
      setState(() {});
    }
  }
}

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  Customer? selectedCustomer;
  Product? selectedProduct;
  final quantityController = TextEditingController(text: '1');
  final priceController = TextEditingController();
  final discountController = TextEditingController();
  final taxController = TextEditingController(text: '0');
  final paidController = TextEditingController(text: '0');
  final notesController = TextEditingController();
  final discountValueController = TextEditingController(text: '0');
  final List<InvoiceItem> items = [];
  bool discountIsPercent = false;
  String paymentStatus = 'غير مدفوعة';

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    if (state.customers.isNotEmpty) selectedCustomer = state.customers.first;
    taxController.text = state.repSettings.taxPercent.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final currency = NumberFormat.currency(locale: 'ar_EG', symbol: 'EGP ');
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.total);
    final discountInput = _double(discountValueController.text);
    final discountBase = discountIsPercent ? subtotal * (discountInput / 100) : discountInput;
    final safeDiscount = discountBase.clamp(0, subtotal).toDouble();
    final taxPercent = _double(taxController.text).clamp(0, 100).toDouble();
    final taxValue = ((subtotal - safeDiscount) * (taxPercent / 100)).clamp(0, double.infinity).toDouble();
    final total = (subtotal - safeDiscount + taxValue).clamp(0, double.infinity).toDouble();
    final paid = _double(paidController.text).clamp(0, total).toDouble();
    final effectivePaid = paymentStatus == 'مدفوعة' ? total : paymentStatus == 'غير مدفوعة' ? 0.0 : paid;
    final remaining = (total - effectivePaid).clamp(0, double.infinity).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء فاتورة', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('العميل', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    TextButton.icon(
                      onPressed: () => _openQuickAddCustomer(context),
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: const Text('إضافة عميل'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<Customer>(
                  value: selectedCustomer,
                  items: state.customers
                      .map((c) => DropdownMenuItem<Customer>(value: c, child: Text(c.name)))
                      .toList(),
                  onChanged: (value) => setState(() => selectedCustomer = value),
                  decoration: const InputDecoration(labelText: 'اختر عميل'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.qr_code_scanner_rounded, size: 30),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.add_box_rounded, size: 30),
                    ),
                    const Spacer(),
                    const Text('أضف منتج للفاتورة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 16),
                Autocomplete<Product>(
                  optionsBuilder: (value) {
                    if (value.text.trim().isEmpty) return state.products;
                    return state.products.where((p) =>
                        p.name.contains(value.text.trim()) || p.barcode.contains(value.text.trim()));
                  },
                  displayStringForOption: (option) => option.name,
                  onSelected: (value) {
                    setState(() {
                      selectedProduct = value;
                      priceController.text = value.price.toStringAsFixed(1);
                    });
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topRight,
                      child: Material(
                        elevation: 4,
                        child: SizedBox(
                          width: 565,
                          child: ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return ListTile(
                                title: Text(option.name, textAlign: TextAlign.right),
                                subtitle: Text('السعر : ${option.price}    الكمية المتوفرة : ${option.stock}', textAlign: TextAlign.right, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w700)),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                  fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                    if (selectedProduct != null && controller.text.isEmpty) controller.text = selectedProduct!.name;
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: 'المنتج',
                        suffixIcon: const Icon(Icons.shopping_bag_outlined),
                        prefixIcon: IconButton(
                          onPressed: () {
                            controller.clear();
                            setState(() => selectedProduct = null);
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'السعر'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'الكمية'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _addItem(context),
                    icon: const Icon(Icons.add_shopping_cart_rounded),
                    label: const Text('إضافة'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(64),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: EmptyState(title: 'لا يوجد منتجات', subtitle: ''),
            )
          else
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: _SectionCard(
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => setState(() => items.removeAt(index)),
                        icon: const Icon(Icons.delete_rounded, color: Colors.red),
                      ),
                      IconButton(
                        onPressed: () {
                          final stock = state.products.firstWhere((p) => p.id == item.productId).stock;
                          if (item.quantity + 1 > stock) {
                            _showMessage(context, 'لا يمكن تجاوز المخزون المتاح');
                            return;
                          }
                          setState(() {
                            items[index] = InvoiceItem(
                              productId: item.productId,
                              name: item.name,
                              price: item.price,
                              quantity: item.quantity + 1,
                            );
                          });
                        },
                        icon: const Icon(Icons.add_circle_outline_rounded),
                      ),
                      Text('${item.quantity}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      IconButton(
                        onPressed: item.quantity > 1
                            ? () => setState(() {
                                  items[index] = InvoiceItem(
                                    productId: item.productId,
                                    name: item.name,
                                    price: item.price,
                                    quantity: item.quantity - 1,
                                  );
                                })
                            : null,
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(item.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text('${currency.format(item.price)} x ${item.quantity}', style: const TextStyle(fontSize: 16)),
                            Text('المتوفر: ${state.products.firstWhere((p) => p.id == item.productId).stock}', style: const TextStyle(fontSize: 15, color: Colors.green)),
                            Text('= ${currency.format(item.total)}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          if (items.isNotEmpty) ...[
            Text('المجموع الفرعي   ${currency.format(subtotal)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            _SectionCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: discountController,
                          enabled: false,
                          decoration: const InputDecoration(labelText: 'الخصم'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: discountValueController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(labelText: 'الخصم'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _ToggleMini(
                        first: 'EGP',
                        second: '%',
                        valueIsFirst: !discountIsPercent,
                        onChanged: (first) => setState(() => discountIsPercent = !first),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _PaymentSegment(
                    value: paymentStatus,
                    onChanged: (v) {
                      setState(() {
                        paymentStatus = v;
                        if (v == 'مدفوعة') {
                          paidController.text = total.toStringAsFixed(2);
                        } else if (v == 'غير مدفوعة') {
                          paidController.text = '0';
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  if (paymentStatus == 'مدفوعة جزئياً')
                    TextField(
                      controller: paidController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(labelText: 'المبلغ المدفوع'),
                    ),
                  if (paymentStatus != 'مدفوعة جزئياً') const SizedBox.shrink(),
                  const SizedBox(height: 14),
                  TextField(
                    controller: taxController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'نسبة الضريبة المطبقة',
                      prefixIcon: Icon(Icons.edit_rounded),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _SectionCard(
              child: Column(
                children: [
                  _SummaryRow(label: 'المجموع الفرعي', value: currency.format(subtotal)),
                  _SummaryRow(label: 'الضريبة (${taxPercent.toStringAsFixed(1)}%)', value: currency.format(taxValue)),
                  const Divider(height: 24),
                  _SummaryRow(label: 'المجموع', value: currency.format(total), bold: true),
                  _SummaryRow(label: 'الخصم', value: currency.format(safeDiscount)),
                  _SummaryRow(label: 'المبلغ المدفوع', value: currency.format(effectivePaid), valueColor: Colors.green),
                  _SummaryRow(label: 'المبلغ المتبقي', value: currency.format(remaining), valueColor: const Color(0xFFF59E0B)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _saveInvoice(context),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(70),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: const Text('حفظ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              ),
            )
          ],
        ],
      ),
    );
  }

  double _double(String text) => double.tryParse(text.trim()) ?? 0;

  void _addItem(BuildContext context) {
    if (selectedProduct == null) return;
    final qty = int.tryParse(quantityController.text.trim()) ?? 1;
    final price = _double(priceController.text);
    if (qty <= 0) {
      _showMessage(context, 'أدخل كمية صحيحة');
      return;
    }
    final alreadyAdded = items.where((e) => e.productId == selectedProduct!.id).fold<int>(0, (sum, e) => sum + e.quantity);
    if (alreadyAdded + qty > selectedProduct!.stock) {
      _showMessage(context, 'الكمية المطلوبة أكبر من المخزون المتاح');
      return;
    }
    setState(() {
      final existingIndex = items.indexWhere((e) => e.productId == selectedProduct!.id);
      if (existingIndex != -1) {
        final existing = items[existingIndex];
        items[existingIndex] = InvoiceItem(
          productId: existing.productId,
          name: existing.name,
          price: price,
          quantity: existing.quantity + qty,
        );
      } else {
        items.add(InvoiceItem(
          productId: selectedProduct!.id,
          name: selectedProduct!.name,
          price: price,
          quantity: qty,
        ));
      }
      selectedProduct = null;
      quantityController.text = '1';
      priceController.clear();
    });
  }

  Future<void> _openQuickAddCustomer(BuildContext context) async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final email = TextEditingController();
    final address = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة عميل'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'الاسم')),
              const SizedBox(height: 12),
              TextField(controller: phone, decoration: const InputDecoration(labelText: 'الهاتف')),
              const SizedBox(height: 12),
              TextField(controller: email, decoration: const InputDecoration(labelText: 'البريد الإلكتروني')),
              const SizedBox(height: 12),
              TextField(controller: address, decoration: const InputDecoration(labelText: 'العنوان')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              final state = context.read<AppState>();
              final customer = Customer(
                id: state.newId(),
                name: name.text.trim().isEmpty ? 'عميل نقدي' : name.text.trim(),
                phone: phone.text.trim(),
                email: email.text.trim(),
                address: address.text.trim(),
              );
              await state.addCustomer(customer);
              if (mounted) {
                setState(() => selectedCustomer = customer);
                Navigator.pop(context);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveInvoice(BuildContext context) async {
    final state = context.read<AppState>();
    if (selectedCustomer == null) {
      _showMessage(context, 'اختر العميل أولاً');
      return;
    }
    if (items.isEmpty) {
      _showMessage(context, 'أضف منتجاً واحداً على الأقل');
      return;
    }

    final subtotal = items.fold<double>(0, (sum, item) => sum + item.total);
    final discount = _double(discountValueController.text);
    final discountValue = (discountIsPercent ? subtotal * (discount / 100) : discount).clamp(0, subtotal).toDouble();
    final taxPercent = _double(taxController.text).clamp(0, 100).toDouble();
    final taxValue = ((subtotal - discountValue) * (taxPercent / 100)).clamp(0, double.infinity).toDouble();
    final total = (subtotal - discountValue + taxValue).clamp(0, double.infinity).toDouble();
    final paid = paymentStatus == 'مدفوعة' ? total : paymentStatus == 'غير مدفوعة' ? 0.0 : _double(paidController.text).clamp(0, total).toDouble();

    final requested = <String, int>{};
    for (final item in items) {
      requested[item.productId] = (requested[item.productId] ?? 0) + item.quantity;
    }
    for (final entry in requested.entries) {
      final product = state.products.firstWhere((p) => p.id == entry.key);
      if (entry.value > product.stock) {
        _showMessage(context, 'الكمية المتاحة غير كافية للمنتج: ${product.name}');
        return;
      }
    }

    try {
      await state.addInvoice(
        customer: selectedCustomer!,
        items: items,
        taxPercent: taxPercent,
        taxValue: taxValue,
        discount: discountIsPercent ? discount : discountValue,
        discountIsPercent: discountIsPercent,
        paidAmount: paid,
        notes: notesController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _showMessage(context, e.toString().replaceFirst('Bad state: ', ''));
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class InvoiceDetailsScreen extends StatelessWidget {
  final Invoice invoice;
  const InvoiceDetailsScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'ar_EG', symbol: 'EGP ');
    final invoiceText = _invoiceMessage(invoice, currency);

    return Scaffold(
      appBar: AppBar(
        title: Text('فاتورة #${invoice.number}', style: const TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _deleteInvoice(context),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFF2F5ED7),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                onPressed: () => Share.share(invoiceText),
                icon: const Icon(Icons.share_rounded, color: Colors.white, size: 34),
              ),
              IconButton(
                onPressed: () => Share.share(invoiceText),
                icon: const Icon(Icons.print_rounded, color: Colors.white, size: 34),
              ),
              IconButton(
                onPressed: () => _openWhatsApp(invoice.customerPhone, invoiceText),
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 34),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [BoxShadow(color: Color(0x30000000), blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 34),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0E5EA8),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(invoice.companyName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('فاتورة', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                              Text('# ${invoice.number}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F4FA),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF87B8D2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('المطلوب من السيد / السيدة', style: TextStyle(color: Color(0xFF5081A0), fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 8),
                                  Text(invoice.customerName, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2B5E7F))),
                                  Text(invoice.customerPhone, style: const TextStyle(color: Color(0xFF69A5BD), fontWeight: FontWeight.w600)),
                                  if (invoice.repAddress.isNotEmpty) Text(invoice.repAddress, style: const TextStyle(color: Color(0xFF69A5BD), fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 18),
                          QrImageView(
                            data: invoiceText,
                            size: 100,
                            backgroundColor: Colors.white,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (invoice.repPhone.isNotEmpty) Text('هاتف المندوب: ${invoice.repPhone}', style: const TextStyle(fontWeight: FontWeight.w600)),
                            if (invoice.repEmail.isNotEmpty) Text('بريد المندوب: ${invoice.repEmail}', style: const TextStyle(fontWeight: FontWeight.w600)),
                            if (invoice.taxNumber.isNotEmpty) Text('الرقم الضريبي: ${invoice.taxNumber}', style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text('التاريخ: ${DateFormat('yyyy-MM-dd  hh:mm a', 'ar_EG').format(invoice.createdAt)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Table(
                        border: TableBorder.symmetric(inside: const BorderSide(color: Color(0xFFE5E7EB))),
                        columnWidths: const {
                          0: FlexColumnWidth(2),
                          1: FlexColumnWidth(2),
                          2: FlexColumnWidth(1.5),
                          3: FlexColumnWidth(2),
                          4: FlexColumnWidth(0.8),
                        },
                        children: [
                          const TableRow(
                            decoration: BoxDecoration(color: Color(0xFF0E5EA8)),
                            children: [
                              _CellText('الوصف', header: true),
                              _CellText('السعر', header: true),
                              _CellText('الكمية', header: true),
                              _CellText('المجموع', header: true),
                              _CellText('#', header: true),
                            ],
                          ),
                          ...invoice.items.asMap().entries.map(
                                (entry) => TableRow(
                                  children: [
                                    _CellText(entry.value.name),
                                    _CellText(currency.format(entry.value.price)),
                                    _CellText(entry.value.quantity.toStringAsFixed(1)),
                                    _CellText(currency.format(entry.value.total)),
                                    _CellText('${entry.key + 1}'),
                                  ],
                                ),
                              ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                const Divider(color: Color(0xFF87B8D2), thickness: 2),
                                Text(invoice.signature.isEmpty ? 'التوقيع' : invoice.signature, style: const TextStyle(color: Color(0xFF69A5BD), fontWeight: FontWeight.w700)),
                                if (invoice.repName.isNotEmpty) Text(invoice.repName, style: const TextStyle(color: Color(0xFF2B5E7F), fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFF87B8D2)),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Column(
                                children: [
                                  _SummaryLine(label: 'المجموع الفرعي', value: currency.format(invoice.subtotal)),
                                  _SummaryLine(label: 'الخصم', value: '-${currency.format(invoice.discountValue)}'),
                                  _SummaryLine(label: 'الضريبة', value: currency.format(invoice.taxValue)),
                                  Container(height: 10, color: const Color(0xFF0E5EA8)),
                                  _SummaryLine(label: 'المجموع', value: currency.format(invoice.total), bold: true),
                                  _SummaryLine(label: 'المبلغ المدفوع', value: currency.format(invoice.paidAmount), valueColor: Colors.green),
                                  _SummaryLine(label: 'المبلغ المتبقي', value: currency.format(invoice.remaining), valueColor: Colors.red),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 140),
                    ],
                  ),
                ),
                Container(height: 20, decoration: const BoxDecoration(color: Color(0xFF0E5EA8), borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _invoiceMessage(Invoice invoice, NumberFormat currency) {
    final items = invoice.items
        .map((e) => '- ${e.name} | ${e.quantity} x ${currency.format(e.price)} = ${currency.format(e.total)}')
        .join('\n');
    return 'فاتورة رقم ${invoice.number}\nالعميل: ${invoice.customerName}\nالهاتف: ${invoice.customerPhone}\n\n$items\n\nالمجموع: ${currency.format(invoice.total)}\nالمدفوع: ${currency.format(invoice.paidAmount)}\nالمتبقي: ${currency.format(invoice.remaining)}';
  }

  Future<void> _openWhatsApp(String phone, String text) async {
    final normalized = _normalizeEgyptPhone(phone);
    if (normalized.isEmpty) return;
    final webUri = Uri.parse('https://wa.me/$normalized?text=${Uri.encodeComponent(text)}');
    final appUri = Uri.parse('whatsapp://send?phone=$normalized&text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri, mode: LaunchMode.externalApplication);
      return;
    }
    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  String _normalizeEgyptPhone(String phone) {
    var value = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (value.startsWith('+')) value = value.substring(1);
    if (value.startsWith('00')) value = value.substring(2);
    if (value.startsWith('20') && value.length >= 12) return value;
    if (value.startsWith('0') && value.length == 11) return '20${value.substring(1)}';
    if (value.length == 10 && !value.startsWith('20')) return '20$value';
    return value;
  }

  Future<void> _deleteInvoice(BuildContext context) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('حذف الفاتورة'),
            content: const Text('سيتم حذف الفاتورة وإرجاع الكميات للمخزون. هل تريد المتابعة؟'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) return;
    await context.read<AppState>().deleteInvoice(invoice.id);
    if (!context.mounted) return;
    Navigator.pop(context, true);
  }
}


class _InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onTap;
  const _InvoiceCard({required this.invoice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'ar_EG', symbol: 'EGP ');
    final badgeColor = invoice.status == 'مدفوعة'
        ? const Color(0xFF10B981)
        : invoice.status == 'مدفوعة جزئياً'
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 18, offset: Offset(0, 6))],
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Color(0xFFEFF3FF), shape: BoxShape.circle),
              child: Text(invoice.number, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF3363E5))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    invoice.customerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(DateFormat('d-M-y', 'ar_EG').format(invoice.createdAt), style: const TextStyle(fontSize: 16, color: Color(0xFF555555))),
                  Text(DateFormat('h:mm a', 'ar_EG').format(invoice.createdAt), style: const TextStyle(fontSize: 16, color: Color(0xFF555555))),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(currency.format(invoice.total), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF111827))),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: badgeColor, width: 2),
                      color: badgeColor.withOpacity(.08),
                    ),
                    child: Text(
                      '${invoice.status} : ${currency.format(invoice.remaining)}',
                      style: TextStyle(color: badgeColor, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SquareActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SquareActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 78,
        height: 72,
        decoration: BoxDecoration(
          color: const Color(0xFFEEF4FF),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(icon, size: 38, color: const Color(0xFF2F5ED7)),
      ),
    );
  }
}

class _SortPill extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback onTap;
  const _SortPill({required this.label, required this.selected, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF3363E5) : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: selected ? Colors.white : const Color(0xFF3363E5)),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF111827),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x16000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: child,
    );
  }
}

class _ToggleMini extends StatelessWidget {
  final String first;
  final String second;
  final bool valueIsFirst;
  final ValueChanged<bool> onChanged;
  const _ToggleMini({required this.first, required this.second, required this.valueIsFirst, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD4D9E2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _smallItem(second, !valueIsFirst, () => onChanged(false)),
          _smallItem(first, valueIsFirst, () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _smallItem(String text, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 70,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8EEFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(text, style: const TextStyle(fontSize: 20)),
      ),
    );
  }
}

class _PaymentSegment extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _PaymentSegment({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD5DDEA)),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          _item('مدفوعة', Icons.check_rounded),
          _item('غير مدفوعة', Icons.more_horiz_rounded),
          _item('جزئي', Icons.pie_chart_outline_rounded, actual: 'مدفوعة جزئياً'),
        ],
      ),
    );
  }

  Widget _item(String text, IconData icon, {String? actual}) {
    final key = actual ?? text;
    final selected = value == key;
    return Expanded(
      child: InkWell(
        onTap: () => onChanged(key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEAF0FF) : Colors.white,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF111827)),
              const SizedBox(width: 8),
              Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;
  const _SummaryRow({required this.label, required this.value, this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(value, style: TextStyle(fontSize: bold ? 22 : 18, fontWeight: bold ? FontWeight.w900 : FontWeight.w600, color: valueColor)),
          Text(label, style: TextStyle(fontSize: bold ? 22 : 18, fontWeight: bold ? FontWeight.w900 : FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;
  const _SummaryLine({required this.label, required this.value, this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w700, color: valueColor ?? Colors.black)),
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w700)),
        ],
      ),
    );
  }
}

class _CellText extends StatelessWidget {
  final String text;
  final bool header;
  const _CellText(this.text, {this.header = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: header ? Colors.white : const Color(0xFF222222),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
