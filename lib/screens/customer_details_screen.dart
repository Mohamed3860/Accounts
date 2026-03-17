import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/customer.dart';
import '../models/invoice.dart';
import '../models/invoice_payment.dart';
import '../services/app_state.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final Customer customer;
  const CustomerDetailsScreen({super.key, required this.customer});

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  int tabIndex = 0;
  final currency = NumberFormat.currency(locale: 'en', symbol: 'EGP ', decimalDigits: 2);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final invoices = state.invoicesForCustomer(widget.customer.id);
    final payments = state.paymentsForCustomer(widget.customer.id);
    final totalInvoices = state.totalSalesForCustomer(widget.customer.id);
    final totalPaid = state.totalPaidForCustomer(widget.customer.id);
    final totalDebt = state.outstandingForCustomer(widget.customer.id);

    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
            color: const Color(0xFFF0F4FB),
            child: Column(
              children: [
                Row(
                  children: [
                    _SquareActionButton(
                      icon: Icons.add_rounded,
                      onTap: () => _openPaymentDialog(context),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 36, color: Color(0xFF111827)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.customer.name,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryStat(
                        title: 'إجمالي الفواتير',
                        value: currency.format(totalInvoices),
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _SummaryStat(
                        title: 'إجمالي المدفوع',
                        value: currency.format(totalPaid),
                        color: const Color(0xFF0F9D8A),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _SummaryStat(
                        title: 'إجمالي الديون',
                        value: currency.format(totalDebt),
                        color: const Color(0xFFE5484D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(child: _TopTab(label: 'المدفوعات', selected: tabIndex == 1, onTap: () => setState(() => tabIndex = 1))),
                    const SizedBox(width: 16),
                    Expanded(child: _TopTab(label: 'الفواتير', selected: tabIndex == 0, onTap: () => setState(() => tabIndex = 0))),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: tabIndex == 0
                ? _InvoicesList(invoices: invoices, currency: currency)
                : _PaymentsList(
                    payments: payments,
                    currency: currency,
                    onEdit: (payment) => _openPaymentDialog(context, payment: payment),
                    onDelete: (payment) => _deletePayment(context, payment),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePayment(BuildContext context, InvoicePayment payment) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('حذف دفعة'),
            content: const Text('سيتم خصم قيمة هذه الدفعة من المدفوع وإعادتها إلى مديونية الفاتورة. هل تريد المتابعة؟'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
            ],
          ),
        ) ??
        false;
    if (!ok || !context.mounted) return;
    await context.read<AppState>().deletePayment(payment.id);
  }

  Future<void> _openPaymentDialog(BuildContext context, {InvoicePayment? payment}) async {
    final state = context.read<AppState>();
    final amountController = TextEditingController(text: payment == null ? '' : payment.amount.toStringAsFixed(0));
    final notesController = TextEditingController(text: payment?.notes ?? '');
    final invoices = state.invoicesForCustomer(widget.customer.id);
    String? selectedInvoiceId = payment?.invoiceId;
    if (selectedInvoiceId == null) {
      selectedInvoiceId = invoices.where((e) => e.remaining > 0).isNotEmpty ? invoices.firstWhere((e) => e.remaining > 0).id : null;
    }

    await showDialog<void>(
      context: context,
      barrierColor: const Color(0x99000000),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final availableInvoices = invoices.where((invoice) {
              if (payment != null && invoice.id == payment.invoiceId) return true;
              return invoice.remaining > 0;
            }).toList();
            if (selectedInvoiceId != null && !availableInvoices.any((e) => e.id == selectedInvoiceId)) {
              selectedInvoiceId = availableInvoices.isNotEmpty ? availableInvoices.first.id : null;
            }
            final selectedInvoice = selectedInvoiceId == null
                ? null
                : availableInvoices.cast<Invoice?>().firstWhere((e) => e?.id == selectedInvoiceId, orElse: () => null);

            return Dialog(
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(horizontal: 22),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Center(
                      child: Text('إضافة دفعة', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 24),
                    if (availableInvoices.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 20),
                        child: Text('لا توجد فواتير مفتوحة لهذا العميل.', style: TextStyle(fontSize: 16, color: Color(0xFF6B7280))),
                      )
                    else
                      DropdownButtonFormField<String>(
                        value: selectedInvoiceId,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'الفواتير'),
                        items: availableInvoices
                            .map(
                              (invoice) => DropdownMenuItem(
                                value: invoice.id,
                                child: Text(
                                  '#${invoice.number} - ${currency.format(invoice.total)} (متبقي: ${currency.format(invoice.remaining)})',
                                  textAlign: TextAlign.right,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setModalState(() => selectedInvoiceId = value),
                      ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(labelText: 'المبلغ'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(labelText: 'ملاحظات'),
                    ),
                    if (selectedInvoice != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'اختر الفاتورة للسداد - المتبقي الحالي: ${currency.format(selectedInvoice.remaining)}',
                        style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                      ),
                    ],
                    const SizedBox(height: 26),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('إلغاء', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: availableInvoices.isEmpty
                                ? null
                                : () async {
                                    final invoiceId = selectedInvoiceId;
                                    final invoice = invoiceId == null
                                        ? null
                                        : availableInvoices.cast<Invoice?>().firstWhere((e) => e?.id == invoiceId, orElse: () => null);
                                    final amount = double.tryParse(amountController.text.trim()) ?? 0;
                                    if (invoice == null || amount <= 0) return;
                                    try {
                                      if (payment == null) {
                                        await state.addPayment(
                                          invoiceId: invoice.id,
                                          amount: amount,
                                          notes: notesController.text.trim(),
                                        );
                                      } else {
                                        await state.updatePayment(
                                          paymentId: payment.id,
                                          invoiceId: invoice.id,
                                          amount: amount,
                                          notes: notesController.text.trim(),
                                        );
                                      }
                                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                                    } catch (e) {
                                      if (!dialogContext.mounted) return;
                                      ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(e.toString())));
                                    }
                                  },
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF3567E7),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              minimumSize: const Size.fromHeight(58),
                            ),
                            child: Text(payment == null ? 'إضافة' : 'حفظ'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const _SummaryStat({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}

class _TopTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TopTab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: selected ? const Color(0xFF3567E7) : const Color(0xFF111827))),
            const SizedBox(height: 10),
            Container(height: 4, decoration: BoxDecoration(color: selected ? const Color(0xFF3567E7) : Colors.transparent, borderRadius: BorderRadius.circular(10))),
          ],
        ),
      ),
    );
  }
}

class _InvoicesList extends StatelessWidget {
  final List<Invoice> invoices;
  final NumberFormat currency;
  const _InvoicesList({required this.invoices, required this.currency});

  @override
  Widget build(BuildContext context) {
    if (invoices.isEmpty) {
      return const Center(child: Text('لا توجد فواتير لهذا العميل', style: TextStyle(fontSize: 18, color: Color(0xFF6B7280))));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 26),
      itemCount: invoices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 18),
      itemBuilder: (context, index) {
        final invoice = invoices[index];
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 20, offset: Offset(0, 8))],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFEAF0FF),
                child: Text(invoice.number, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF3567E7))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(currency.format(invoice.total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE8B34A), width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(invoice.status, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFD58B00))),
                          const SizedBox(height: 2),
                          Text('المتبقي: ${currency.format(invoice.remaining)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFD58B00))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(DateFormat('dd-MM-yyyy  h:mm a', 'ar').format(invoice.createdAt), style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PaymentsList extends StatelessWidget {
  final List<InvoicePayment> payments;
  final NumberFormat currency;
  final ValueChanged<InvoicePayment> onEdit;
  final ValueChanged<InvoicePayment> onDelete;
  const _PaymentsList({required this.payments, required this.currency, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return const Center(child: Text('لا توجد مدفوعات مسجلة لهذا العميل', style: TextStyle(fontSize: 18, color: Color(0xFF6B7280))));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 26),
      itemCount: payments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 18),
      itemBuilder: (context, index) {
        final payment = payments[index];
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 20, offset: Offset(0, 8))],
          ),
          child: Row(
            children: [
              IconButton(onPressed: () => onDelete(payment), icon: const Icon(Icons.delete_rounded, color: Color(0xFFE5484D), size: 34)),
              IconButton(onPressed: () => onEdit(payment), icon: const Icon(Icons.edit_rounded, color: Color(0xFF4B5563), size: 32)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(currency.format(payment.amount), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text(DateFormat('dd-MM-yyyy  HH:mm:ss', 'ar').format(payment.createdAt), style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280))),
                    const SizedBox(height: 8),
                    Text(payment.notes, style: const TextStyle(fontSize: 18, color: Color(0xFF111827), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const CircleAvatar(
                radius: 26,
                backgroundColor: Color(0xFFEAF8F7),
                child: Icon(Icons.credit_card_rounded, color: Color(0xFF256D6A), size: 28),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SquareActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SquareActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEAF0FF),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(width: 78, height: 78, child: Icon(icon, size: 40, color: const Color(0xFF3567E7))),
      ),
    );
  }
}
