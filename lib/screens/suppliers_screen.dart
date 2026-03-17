import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/supplier.dart';
import '../services/app_state.dart';
import '../widgets/empty_state.dart';

class SuppliersScreen extends StatelessWidget {
  const SuppliersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      body: state.suppliers.isEmpty
          ? const EmptyState(
              title: 'لا يوجد موردون',
              subtitle: 'أضف موردًا لإدارة المشتريات',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.suppliers.length,
              itemBuilder: (context, index) {
                final item = state.suppliers[index];
                return Card(
                  child: ListTile(
                    title: Text(item.name),
                    subtitle: Text('${item.phone}\n${item.address}'),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () =>
                          context.read<AppState>().deleteSupplier(item.id),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('مورد'),
      ),
    );
  }

  Future<void> _openAddDialog(BuildContext context) async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final address = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إضافة مورد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'الاسم'),
              ),
              TextField(
                controller: phone,
                decoration: const InputDecoration(labelText: 'الهاتف'),
              ),
              TextField(
                controller: address,
                decoration: const InputDecoration(labelText: 'العنوان'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              if (name.text.trim().isEmpty) return;

              final state = context.read<AppState>();
              await state.addSupplier(
                Supplier(
                  id: state.newId(),
                  name: name.text.trim(),
                  phone: phone.text.trim(),
                  address: address.text.trim(),
                ),
              );

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
