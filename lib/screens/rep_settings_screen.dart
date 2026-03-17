import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/rep_settings.dart';
import '../services/app_state.dart';

class RepSettingsScreen extends StatefulWidget {
  const RepSettingsScreen({super.key});

  @override
  State<RepSettingsScreen> createState() => _RepSettingsScreenState();
}

class _RepSettingsScreenState extends State<RepSettingsScreen> {
  late final TextEditingController repName;
  late final TextEditingController ownerName;
  late final TextEditingController taxNumber;
  late final TextEditingController phone;
  late final TextEditingController email;
  late final TextEditingController address;
  late final TextEditingController notes;
  late final TextEditingController taxPercent;
  late final TextEditingController signature;

  @override
  void initState() {
    super.initState();
    final settings = context.read<AppState>().repSettings;
    repName = TextEditingController(text: settings.repName);
    ownerName = TextEditingController(text: settings.ownerName);
    taxNumber = TextEditingController(text: settings.taxNumber);
    phone = TextEditingController(text: settings.phone);
    email = TextEditingController(text: settings.email);
    address = TextEditingController(text: settings.address);
    notes = TextEditingController(text: settings.notes);
    taxPercent = TextEditingController(text: settings.taxPercent.toStringAsFixed(1));
    signature = TextEditingController(text: settings.signature);
  }

  @override
  void dispose() {
    repName.dispose();
    ownerName.dispose();
    taxNumber.dispose();
    phone.dispose();
    email.dispose();
    address.dispose();
    notes.dispose();
    taxPercent.dispose();
    signature.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('إعدادات المندوب', style: TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.check_rounded),
          onPressed: _save,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: repName,
                  decoration: const InputDecoration(
                    labelText: 'اسم المندوب',
                    hintText: 'اسم المندوب',
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Stack(
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF2F5ED7), width: 3),
                    ),
                    child: const Icon(Icons.badge_outlined, size: 62, color: Color(0xFFBDBDBD)),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 8,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2F5ED7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit_rounded, color: Colors.white),
                    ),
                  )
                ],
              ),
            ],
          ),
          const SizedBox(height: 26),
          const Text('معلومات المندوب', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF2F5ED7))),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: ownerName,
                  decoration: const InputDecoration(labelText: 'المالك', suffixIcon: Icon(Icons.person_outline_rounded)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: taxNumber,
                  decoration: const InputDecoration(labelText: 'الرقم الضريبي', suffixIcon: Icon(Icons.badge_outlined)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'الهاتف', suffixIcon: Icon(Icons.phone_outlined)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'البريد الإلكتروني', suffixIcon: Icon(Icons.mail_outline_rounded)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: address,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'العنوان', suffixIcon: Icon(Icons.location_on_outlined)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: notes,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'ملاحظات', suffixIcon: Icon(Icons.note_alt_outlined)),
          ),
          const SizedBox(height: 24),
          const Text('نسبة الضريبة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF2F5ED7))),
          const SizedBox(height: 12),
          Row(
            children: [
              const Spacer(),
              SizedBox(
                width: 310,
                child: TextField(
                  controller: taxPercent,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'نسبة الضريبة',
                    prefixIcon: Icon(Icons.percent_rounded),
                    suffixIcon: Icon(Icons.percent_rounded),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 24),
          const Text('التوقيع الرقمي', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF2F5ED7))),
          const SizedBox(height: 12),
          Container(
            height: 190,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE3E8F0)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.draw_rounded, color: Color(0xFF2F5ED7), size: 46),
                const SizedBox(height: 10),
                const Text('رسم التوقيع', style: TextStyle(fontSize: 24, color: Color(0xFF2F5ED7))),
                const SizedBox(height: 12),
                TextField(
                  controller: signature,
                  decoration: const InputDecoration(labelText: 'اسم التوقيع أو وصفه'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(66),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: const Text('حفظ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final state = context.read<AppState>();
    await state.updateRepSettings(
      RepSettings(
        repName: repName.text.trim().isEmpty ? 'اسم المندوب' : repName.text.trim(),
        ownerName: ownerName.text.trim(),
        taxNumber: taxNumber.text.trim(),
        phone: phone.text.trim(),
        email: email.text.trim(),
        address: address.text.trim(),
        notes: notes.text.trim(),
        taxPercent: double.tryParse(taxPercent.text.trim()) ?? 0,
        signature: signature.text.trim(),
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ إعدادات المندوب')));
    Navigator.pop(context);
  }
}
