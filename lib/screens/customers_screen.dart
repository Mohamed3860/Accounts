import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'customer_details_screen.dart';
import '../models/customer.dart';
import '../services/app_state.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

enum _CustomerFilter { all, hasInvoices, noInvoices }
enum _CustomerSort { nameAsc, nameDesc, mostInvoices, leastInvoices }

class _CustomersScreenState extends State<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  _CustomerFilter _filter = _CustomerFilter.all;
  _CustomerSort _sort = _CustomerSort.nameAsc;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final customers = _buildCustomers(state);

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
                    _AddButton(onTap: () => _openAddDialog(context)),
                    const Spacer(),
                    const Text(
                      'العملاء',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _SearchField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 56,
                  child: ListView(
                    reverse: true,
                    scrollDirection: Axis.horizontal,
                    children: [
                      _SortChip(
                        label: _sortLabel(_sort),
                        onTap: () => _openSortSheet(context),
                      ),
                      const SizedBox(width: 14),
                      _FilterChipItem(
                        label: 'الكل',
                        selected: _filter == _CustomerFilter.all,
                        onTap: () => setState(() => _filter = _CustomerFilter.all),
                      ),
                      const SizedBox(width: 14),
                      _FilterChipItem(
                        label: 'لديه فواتير',
                        selected: _filter == _CustomerFilter.hasInvoices,
                        onTap: () => setState(() => _filter = _CustomerFilter.hasInvoices),
                      ),
                      const SizedBox(width: 14),
                      _FilterChipItem(
                        label: 'بدون فواتير',
                        selected: _filter == _CustomerFilter.noInvoices,
                        onTap: () => setState(() => _filter = _CustomerFilter.noInvoices),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: customers.isEmpty
                ? const _CustomersEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 26),
                    itemCount: customers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 18),
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      final invoiceCount = _invoiceCountFor(state, customer);
                      return _CustomerCard(
                        customer: customer,
                        invoiceCount: invoiceCount,
                        onDelete: () => _confirmDelete(context, customer),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CustomerDetailsScreen(customer: customer),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<Customer> _buildCustomers(AppState state) {
    final query = _searchController.text.trim();
    final items = state.customers.where((customer) {
      final invoiceCount = _invoiceCountFor(state, customer);
      final matchesFilter = switch (_filter) {
        _CustomerFilter.all => true,
        _CustomerFilter.hasInvoices => invoiceCount > 0,
        _CustomerFilter.noInvoices => invoiceCount == 0,
      };

      if (!matchesFilter) return false;
      if (query.isEmpty) return true;

      return customer.name.contains(query) ||
          customer.phone.contains(query) ||
          customer.email.contains(query) ||
          customer.address.contains(query);
    }).toList();

    items.sort((a, b) {
      final aCount = _invoiceCountFor(state, a);
      final bCount = _invoiceCountFor(state, b);
      return switch (_sort) {
        _CustomerSort.nameAsc => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        _CustomerSort.nameDesc => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
        _CustomerSort.mostInvoices => bCount.compareTo(aCount),
        _CustomerSort.leastInvoices => aCount.compareTo(bCount),
      };
    });

    return items;
  }

  int _invoiceCountFor(AppState state, Customer customer) {
    return state.invoices.where((invoice) => invoice.customerId == customer.id).length;
  }

  String _sortLabel(_CustomerSort sort) {
    return switch (sort) {
      _CustomerSort.nameAsc => 'الاسم (أ-ي)',
      _CustomerSort.nameDesc => 'الاسم (ي-أ)',
      _CustomerSort.mostInvoices => 'الأكثر فواتير',
      _CustomerSort.leastInvoices => 'الأقل فواتير',
    };
  }

  Future<void> _openSortSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<_CustomerSort>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(26, 28, 26, 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'ترتيب حسب',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 18),
            ..._CustomerSort.values.map(
              (item) => InkWell(
                onTap: () => Navigator.pop(context, item),
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Icon(
                        _sort == item ? Icons.check_rounded : Icons.circle_outlined,
                        color: _sort == item ? const Color(0xFF3567E7) : Colors.transparent,
                        size: 30,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _sortLabel(item),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (selected != null) {
      setState(() => _sort = selected);
    }
  }

  Future<void> _confirmDelete(BuildContext context, Customer customer) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف عميل'),
        content: Text('هل تريد حذف العميل ${customer.name}؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              await context.read<AppState>().deleteCustomer(customer.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddDialog(BuildContext context) async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final email = TextEditingController();
    final address = TextEditingController();

    await showDialog<void>(
      context: context,
      barrierColor: const Color(0x99000000),
      builder: (dialogContext) => Dialog(
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
                child: Text(
                  'إضافة عميل',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _DialogField(controller: name, hint: 'الاسم', icon: Icons.contact_page_outlined),
              const SizedBox(height: 18),
              _DialogField(
                controller: phone,
                hint: 'الهاتف',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 18),
              _DialogField(
                controller: email,
                hint: 'البريد الإلكتروني',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 18),
              _DialogField(controller: address, hint: 'العنوان'),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 72,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF3567E7),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        onPressed: () async {
                          if (name.text.trim().isEmpty) return;
                          final state = context.read<AppState>();
                          await state.addCustomer(
                            Customer(
                              id: state.newId(),
                              name: name.text.trim(),
                              phone: phone.text.trim(),
                              email: email.text.trim(),
                              address: address.text.trim(),
                            ),
                          );
                          if (dialogContext.mounted) Navigator.pop(dialogContext);
                        },
                        child: const Text('حفظ'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text(
                        'إلغاء',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3567E7),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEAF0FF),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: const SizedBox(
          width: 78,
          height: 78,
          child: Icon(Icons.add_rounded, size: 40, color: Color(0xFF3567E7)),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 42, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                hintText: 'البحث عن العملاء...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipItem({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF3567E7) : Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : const Color(0xFF111827),
            ),
          ),
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SortChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sort_rounded, color: Color(0xFF3567E7), size: 28),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  final int invoiceCount;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _CustomerCard({
    required this.customer,
    required this.invoiceCount,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhone = customer.phone.trim().isNotEmpty;
    return Dismissible(
      key: ValueKey(customer.id),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFE7E7),
          borderRadius: BorderRadius.circular(28),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 28),
        child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE5484D), size: 32),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.chevron_left_rounded, size: 42, color: Color(0xFFA1A1AA)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      customer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (hasPhone)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Icon(Icons.phone_rounded, size: 22, color: Color(0xFFA1A1AA)),
                          const SizedBox(width: 8),
                          Text(
                            customer.phone,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF333A49),
                            ),
                          ),
                        ],
                      )
                    else
                      const SizedBox(height: 4),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(Icons.receipt_long_rounded, size: 22, color: Color(0xFFA1A1AA)),
                        const SizedBox(width: 8),
                        Text(
                          invoiceCount == 0
                              ? 'لا يوجد فواتير'
                              : invoiceCount == 1
                                  ? 'فاتورة واحدة'
                                  : '$invoiceCount فواتير',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFEAF0FF),
                child: Icon(Icons.person_rounded, size: 34, color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final TextInputType? keyboardType;

  const _DialogField({
    required this.controller,
    required this.hint,
    this.icon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD9DCE3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 34, color: const Color(0xFF111827)),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
                hintStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomersEmptyState extends StatelessWidget {
  const _CustomersEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'لا يوجد عملاء مطابقون للبحث أو الفلترة',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}
