import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../services/app_state.dart';

enum _ProductTab { products, categories }
enum _ProductFilter { all, lowStock, outOfStock, available }
enum _ProductSort { nameAsc, nameDesc, priceHigh, priceLow }

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  _ProductTab _tab = _ProductTab.products;
  _ProductFilter _filter = _ProductFilter.all;
  _ProductSort _sort = _ProductSort.nameAsc;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final products = _buildProducts(state);

    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFFF4F6FA),
            child: Column(
              children: [
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.fromLTRB(22, 10, 22, 22),
                  child: Row(
                    children: [
                      Spacer(),
                      Text(
                        'المنتجات',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: _TopTabButton(
                          label: 'الفئات',
                          selected: _tab == _ProductTab.categories,
                          onTap: () => setState(() => _tab = _ProductTab.categories),
                        ),
                      ),
                      Expanded(
                        child: _TopTabButton(
                          label: 'المنتجات',
                          selected: _tab == _ProductTab.products,
                          onTap: () => setState(() => _tab = _ProductTab.products),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
                  color: const Color(0xFFF4F6FA),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _AddButton(
                            onTap: () => _tab == _ProductTab.products
                                ? _openAddProductDialog(context)
                                : _openAddCategoryDialog(context),
                          ),
                          const Spacer(),
                          Text(
                            _tab == _ProductTab.products ? 'المنتجات' : 'الفئات',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      _SearchField(
                        controller: _searchController,
                        hint: _tab == _ProductTab.products
                            ? 'بحث عن منتج (الاسم، الباركود)'
                            : 'بحث عن فئة',
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 18),
                      if (_tab == _ProductTab.products)
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
                                selected: _filter == _ProductFilter.all,
                                onTap: () => setState(() => _filter = _ProductFilter.all),
                              ),
                              const SizedBox(width: 14),
                              _FilterChipItem(
                                label: 'مخزون منخفض',
                                selected: _filter == _ProductFilter.lowStock,
                                onTap: () => setState(() => _filter = _ProductFilter.lowStock),
                              ),
                              const SizedBox(width: 14),
                              _FilterChipItem(
                                label: 'نفذت الكمية',
                                selected: _filter == _ProductFilter.outOfStock,
                                onTap: () => setState(() => _filter = _ProductFilter.outOfStock),
                              ),
                              const SizedBox(width: 14),
                              _FilterChipItem(
                                label: 'متوفر',
                                selected: _filter == _ProductFilter.available,
                                onTap: () => setState(() => _filter = _ProductFilter.available),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _tab == _ProductTab.products
                ? _ProductsBody(
                    products: products,
                    onDelete: (product) => _confirmDeleteProduct(context, product),
                  )
                : _CategoriesBody(
                    categories: _buildCategories(state),
                    onDelete: (category) => _confirmDeleteCategory(context, category),
                  ),
          ),
        ],
      ),
    );
  }

  List<Product> _buildProducts(AppState state) {
    final query = _searchController.text.trim();
    final items = state.products.where((product) {
      final matchesFilter = switch (_filter) {
        _ProductFilter.all => true,
        _ProductFilter.lowStock => product.stock > 0 && product.stock <= 5,
        _ProductFilter.outOfStock => product.stock <= 0,
        _ProductFilter.available => product.stock > 0,
      };
      if (!matchesFilter) return false;
      if (query.isEmpty) return true;
      return product.name.contains(query) || product.barcode.contains(query);
    }).toList();

    items.sort((a, b) => switch (_sort) {
          _ProductSort.nameAsc => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          _ProductSort.nameDesc => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
          _ProductSort.priceHigh => b.price.compareTo(a.price),
          _ProductSort.priceLow => a.price.compareTo(b.price),
        });
    return items;
  }

  List<String> _buildCategories(AppState state) {
    final query = _searchController.text.trim();
    final items = List<String>.from(state.categories);
    if (query.isEmpty) return items;
    return items.where((item) => item.contains(query)).toList();
  }

  String _sortLabel(_ProductSort sort) {
    return switch (sort) {
      _ProductSort.nameAsc => 'الاسم (أ-ي)',
      _ProductSort.nameDesc => 'الاسم (ي-أ)',
      _ProductSort.priceHigh => 'الأعلى سعرًا',
      _ProductSort.priceLow => 'الأقل سعرًا',
    };
  }

  Future<void> _openSortSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<_ProductSort>(
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
            ..._ProductSort.values.map(
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

  Future<void> _confirmDeleteProduct(BuildContext context, Product product) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف منتج'),
        content: Text('هل تريد حذف المنتج ${product.name}؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              await context.read<AppState>().deleteProduct(product.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteCategory(BuildContext context, String category) async {
    final state = context.read<AppState>();
    final used = state.products.any((product) => product.category == category);

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف فئة'),
        content: Text(
          used
              ? 'هذه الفئة مستخدمة داخل بعض المنتجات. يمكن حذفها من القائمة فقط وسيبقى اسمها محفوظًا داخل المنتجات الحالية.'
              : 'هل تريد حذف الفئة $category؟',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              await state.deleteCategory(category);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddCategoryDialog(BuildContext context) async {
    final controller = TextEditingController();
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
                  'إضافة فئة',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 24),
              _DialogField(controller: controller, hint: 'اسم الفئة'),
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
                        ),
                        onPressed: () async {
                          await context.read<AppState>().addCategory(controller.text.trim());
                          if (dialogContext.mounted) Navigator.pop(dialogContext);
                        },
                        child: const Text('إضافة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('إلغاء', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF3567E7))),
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

  Future<void> _openAddProductDialog(BuildContext context) async {
    final state = context.read<AppState>();
    final name = TextEditingController();
    final price = TextEditingController();
    final stock = TextEditingController(text: '0');
    final barcode = TextEditingController();
    String? selectedCategory = state.categories.isNotEmpty ? state.categories.first : null;

    await showDialog<void>(
      context: context,
      barrierColor: const Color(0x99000000),
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
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
                    'إضافة منتج',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                  ),
                ),
                const SizedBox(height: 24),
                _DialogField(controller: name, hint: 'اسم المنتج'),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _DialogField(
                        controller: price,
                        hint: 'السعر',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: _StockField(controller: stock),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _DialogField(controller: barcode, hint: 'باركود', icon: Icons.qr_code_scanner_rounded),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Material(
                      color: const Color(0xFF2DA4F1),
                      borderRadius: BorderRadius.circular(24),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () async {
                          final value = await _showQuickCategoryInput(dialogContext);
                          if (value != null && value.trim().isNotEmpty) {
                            await state.addCategory(value.trim());
                            setModalState(() => selectedCategory = value.trim());
                          }
                        },
                        child: const SizedBox(
                          width: 56,
                          height: 56,
                          child: Icon(Icons.add_rounded, color: Colors.white, size: 34),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _CategoryDropdown(
                        value: selectedCategory,
                        items: state.categories,
                        onChanged: (value) => setModalState(() => selectedCategory = value),
                      ),
                    ),
                  ],
                ),
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
                            await state.addProduct(
                              Product(
                                id: state.newId(),
                                name: name.text.trim(),
                                unit: 'قطعة',
                                price: double.tryParse(price.text.trim()) ?? 0,
                                stock: int.tryParse(stock.text.trim()) ?? 0,
                                barcode: barcode.text.trim(),
                                category: selectedCategory ?? '',
                              ),
                            );
                            if (dialogContext.mounted) Navigator.pop(dialogContext);
                          },
                          child: const Text('إضافة'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text(
                          'إلغاء',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF3567E7)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _showQuickCategoryInput(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('فئة جديدة'),
        content: TextField(
          controller: controller,
          textAlign: TextAlign.right,
          decoration: const InputDecoration(hintText: 'اسم الفئة'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('حفظ')),
        ],
      ),
    );
  }
}

class _ProductsBody extends StatelessWidget {
  final List<Product> products;
  final ValueChanged<Product> onDelete;

  const _ProductsBody({required this.products, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const _ProductsEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 26),
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 18),
      itemBuilder: (context, index) => _ProductCard(product: products[index], onDelete: () => onDelete(products[index])),
    );
  }
}

class _CategoriesBody extends StatelessWidget {
  final List<String> categories;
  final ValueChanged<String> onDelete;

  const _CategoriesBody({required this.categories, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Center(
        child: Text(
          'لا يوجد فئات',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF)),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 26),
      itemCount: categories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 18),
      itemBuilder: (context, index) {
        final category = categories[index];
        return Dismissible(
          key: ValueKey(category),
          direction: DismissDirection.startToEnd,
          confirmDismiss: (_) async {
            onDelete(category);
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
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(color: Color(0x12000000), blurRadius: 20, offset: Offset(0, 8)),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.chevron_left_rounded, size: 42, color: Color(0xFFA1A1AA)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    category,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                  ),
                ),
                const SizedBox(width: 18),
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFFFFF5E7),
                  child: Icon(Icons.category_outlined, size: 30, color: Color(0xFFF2A51A)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TopTabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TopTabButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(top: 20, bottom: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? const Color(0xFF3567E7) : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: selected ? const Color(0xFF3567E7) : const Color(0xFF111827),
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
  final String hint;

  const _SearchField({required this.controller, required this.onChanged, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
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
              decoration: InputDecoration(
                hintText: hint,
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
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onDelete;

  const _ProductCard({required this.product, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en', symbol: 'EGP ', decimalDigits: 2);
    return Dismissible(
      key: ValueKey(product.id),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        decoration: BoxDecoration(color: const Color(0xFFFFE7E7), borderRadius: BorderRadius.circular(28)),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 28),
        child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE5484D), size: 32),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 20, offset: Offset(0, 8))],
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
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    currency.format(product.price),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            const CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xFFFFF5E7),
              child: Icon(Icons.shopping_bag_outlined, size: 30, color: Color(0xFFF2A51A)),
            ),
          ],
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

  const _DialogField({required this.controller, required this.hint, this.icon, this.keyboardType});

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
                hintStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFF111827)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StockField extends StatelessWidget {
  final TextEditingController controller;

  const _StockField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD9DCE3)),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: 8,
            right: 16,
            child: Text(
              'الكمية المتوفرة',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF6F8BD9)),
            ),
          ),
          Center(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.only(top: 20),
              ),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Color(0xFF111827)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _CategoryDropdown({required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD9DCE3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: const Align(
            alignment: Alignment.centerRight,
            child: Text('اختر', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          ),
          icon: const Icon(Icons.arrow_drop_down_rounded, size: 34, color: Color(0xFF6B7280)),
          items: items
              .map((item) => DropdownMenuItem<String>(
                    value: item,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(item, textAlign: TextAlign.right),
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ProductsEmptyState extends StatelessWidget {
  const _ProductsEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.production_quantity_limits_outlined, size: 86, color: Color(0xFFB7B7B7)),
          SizedBox(height: 16),
          Text(
            'لا يوجد منتجات',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }
}
