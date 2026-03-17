import 'package:flutter/material.dart';

import 'backup_restore_screen.dart';
import 'rep_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        const Text('الإعدادات', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 24),
        _NavCard(
          icon: Icons.badge_outlined,
          title: 'إعدادات المندوب',
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RepSettingsScreen()));
          },
        ),
        const SizedBox(height: 16),
        _BackupCard(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BackupRestoreScreen()));
          },
        ),
      ],
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _NavCard({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4))],
        ),
        child: Row(
          children: [
            const Icon(Icons.chevron_left_rounded, size: 36),
            const Spacer(),
            Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
            const SizedBox(width: 16),
            Icon(icon, size: 34),
          ],
        ),
      ),
    );
  }
}

class _BackupCard extends StatelessWidget {
  final VoidCallback onTap;
  const _BackupCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 14),
              child: Icon(Icons.chevron_left_rounded, size: 36),
            ),
            const Spacer(),
            const Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('النسخ الاحتياطي والاستعادة', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                  SizedBox(height: 10),
                  Text(
                    'أنشئ نسخ احتياطية محلية أو استعد نسخة سابقة.',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 17, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Icon(Icons.cloud_upload_outlined, size: 34),
            ),
          ],
        ),
      ),
    );
  }
}
