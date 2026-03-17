import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/app_state.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  bool busy = false;
  List<FileSystemEntity> backups = const [];

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    final files = await context.read<AppState>().listBackupFiles();
    if (!mounted) return;
    setState(() => backups = files);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('النسخ الاحتياطي والاستعادة', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE3E8F0)),
            ),
            child: Column(
              children: [
                const Text('إنشاء نسخة احتياطية جديدة', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                const Text('أنشئ نسخ احتياطية محلية أو استعد نسخة سابقة.', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: busy ? null : _createBackup,
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('إنشاء نسخة احتياطية جديدة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(72),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : _restoreBackup,
                    icon: const Icon(Icons.restore_page_rounded),
                    label: const Text('استعادة من ملف خارجي', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(72),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text('سجل النسخ الاحتياطي', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          if (backups.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: Text('لا توجد نسخ احتياطية محلية.', style: TextStyle(fontSize: 20))),
            )
          else
            ...backups.map((file) {
              final stat = File(file.path).statSync();
              final name = file.path.split('/').last;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE3E8F0)),
                ),
                child: ListTile(
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(DateFormat('yyyy/MM/dd - hh:mm a', 'ar').format(stat.modified)),
                  trailing: IconButton(
                    icon: const Icon(Icons.share_rounded),
                    onPressed: () => Share.shareXFiles([XFile(file.path)]),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _createBackup() async {
    setState(() => busy = true);
    try {
      final file = await context.read<AppState>().createBackup();
      if (!mounted) return;
      await _loadBackups();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إنشاء النسخة: ${file.path.split('/').last}')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _restoreBackup() async {
    setState(() => busy = true);
    try {
      final ok = await context.read<AppState>().restoreFromExternalFile();
      if (!mounted) return;
      if (ok) {
        await _loadBackups();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت استعادة النسخة الاحتياطية')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}
