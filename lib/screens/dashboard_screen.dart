import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/invoice.dart';
import '../services/app_state.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final currency = NumberFormat.currency(locale: 'en_US', symbol: 'EGP ', decimalDigits: 2);
    final recentInvoices = state.invoices.take(5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            color: const Color(0xFFF0F4FB),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(height: 6),
                Text(
                  'الرئيسية',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 22, 28, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'قم بإدارة فواتيرك بسهولة مع تطبيق أمانيا',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.12,
                  children: [
                    _StatBox(
                      icon: Icons.receipt_long_rounded,
                      iconColor: const Color(0xFF5D6EF5),
                      iconBackground: const Color(0xFFEEF0FF),
                      value: state.invoiceCount.toString(),
                      label: 'الفواتير',
                    ),
                    _StatBox(
                      icon: Icons.attach_money_rounded,
                      iconColor: const Color(0xFF56A95A),
                      iconBackground: const Color(0xFFEAF6EB),
                      value: currency.format(state.totalSales),
                      label: 'إجمالي المبيعات',
                    ),
                    _StatBox(
                      icon: Icons.shopping_bag_rounded,
                      iconColor: const Color(0xFFF5A000),
                      iconBackground: const Color(0xFFFFF5DF),
                      value: state.productCount.toString(),
                      label: 'المنتجات',
                    ),
                    _StatBox(
                      icon: Icons.groups_rounded,
                      iconColor: const Color(0xFF3B9DFF),
                      iconBackground: const Color(0xFFEAF4FF),
                      value: state.customerCount.toString(),
                      label: 'العملاء',
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _SalesChartCard(invoices: state.invoices),
                const SizedBox(height: 28),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'عرض الكل',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3567E7),
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'النشاط الأخير',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (recentInvoices.isEmpty)
                  const _EmptyRecentActivity()
                else
                  ...recentInvoices.map(
                    (invoice) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _RecentInvoiceCard(invoice: invoice, currency: currency),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String value;
  final String label;

  const _StatBox({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: CircleAvatar(
              radius: 25,
              backgroundColor: iconBackground,
              child: Icon(icon, color: iconColor, size: 28),
            ),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesChartCard extends StatelessWidget {
  final List<Invoice> invoices;

  const _SalesChartCard({required this.invoices});

  @override
  Widget build(BuildContext context) {
    final spots = _buildSpots(invoices);
    final labels = _buildLabels(invoices);
    double maxY = 1000;
    for (final spot in spots) {
      if (spot.y > maxY) maxY = spot.y;
    }
    maxY = (maxY * 1.12).clamp(1000, double.infinity);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            'اتجاه المبيعات',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (spots.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                lineTouchData: const LineTouchData(enabled: false),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
                ),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: maxY / 3,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: Color(0xFFEDEFF5),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      reservedSize: 34,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            labels[index],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF6F95F6),
                    barWidth: 5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF6F95F6).withOpacity(0.28),
                          const Color(0xFF6F95F6).withOpacity(0.02),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _buildSpots(List<Invoice> invoices) {
    final values = List<double>.filled(7, 0);
    final now = DateTime.now();
    for (final invoice in invoices) {
      final diff = now.difference(DateTime(
        invoice.createdAt.year,
        invoice.createdAt.month,
        invoice.createdAt.day,
      )).inDays;
      if (diff >= 0 && diff < 7) {
        final index = 6 - diff;
        values[index] += invoice.total;
      }
    }

    final hasData = values.any((e) => e > 0);
    if (!hasData) {
      return const [
        FlSpot(0, 100),
        FlSpot(1, 100),
        FlSpot(2, 100),
        FlSpot(3, 100),
        FlSpot(4, 100),
        FlSpot(5, 450),
        FlSpot(6, 1200),
      ];
    }

    return List.generate(values.length, (i) {
      final value = values[i] == 0 ? 40.0 : values[i];
      return FlSpot(i.toDouble(), value);
    });
  }

  List<String> _buildLabels(List<Invoice> invoices) {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      return DateFormat('M/d', 'en_US').format(date);
    });
  }
}

class _RecentInvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final NumberFormat currency;

  const _RecentInvoiceCard({required this.invoice, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFEAF0FF),
            child: Text(
              '${invoice.items.length}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF3567E7),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  invoice.customerName.isEmpty ? 'فاتورة مبيعات' : invoice.customerName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  DateFormat('HH:mm:ss dd-MM-yyyy', 'en_US').format(invoice.createdAt),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            currency.format(invoice.total),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRecentActivity extends StatelessWidget {
  const _EmptyRecentActivity();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Text(
        'لا يوجد نشاط حديث الآن',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }
}
