import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/sale_report.dart';
import '../../providers/report_provider.dart';
import '../../widgets/stat_tile.dart';

class MonthlyReportTab extends StatefulWidget {
  const MonthlyReportTab({super.key});

  @override
  State<MonthlyReportTab> createState() => _MonthlyReportTabState();
}

class _MonthlyReportTabState extends State<MonthlyReportTab> {
  DateTime _selected = DateTime.now();

  void _prevMonth() => setState(() {
        _selected = DateTime(_selected.year, _selected.month - 1);
      });

  void _nextMonth() {
    final next = DateTime(_selected.year, _selected.month + 1);
    if (next.isBefore(DateTime.now().add(const Duration(days: 1)))) {
      setState(() => _selected = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rp = context.read<ReportProvider>();
    return Column(
      children: [
        // Month navigator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white70),
                onPressed: _prevMonth,
              ),
              Text(
                DateFormat('MMMM yyyy').format(_selected),
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white70),
                onPressed: _nextMonth,
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<SaleReport>>(
            stream:
                rp.getMonthlyReports(_selected.year, _selected.month),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF2ECC71)));
              }
              final reports = snap.data ?? [];
              if (reports.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.inbox_outlined,
                          color: Colors.white24, size: 64),
                      const SizedBox(height: 12),
                      Text('এই মাসে কোনো রিপোর্ট নেই।',
                          style: GoogleFonts.hindSiliguri(
                              color: Colors.white38)),
                    ],
                  ),
                );
              }

              // Aggregate per day
              final Map<int, _DaySummary> byDay = {};
              for (final r in reports) {
                final d = r.date.day;
                byDay[d] ??= _DaySummary();
                byDay[d]!.sale += r.sale;
                byDay[d]!.parcel += r.parcel;
                byDay[d]!.returns += r.returns;
                byDay[d]!.bkash += r.bkash;
                byDay[d]!.nagad += r.nagad;
                byDay[d]!.app += r.appCharge;
              }

              final totalSale =
                  reports.fold<double>(0, (s, r) => s + r.sale);
              final totalParcel =
                  reports.fold<int>(0, (s, r) => s + r.parcel);
              final totalReturn =
                  reports.fold<int>(0, (s, r) => s + r.returns);
              final totalBkash =
                  reports.fold<double>(0, (s, r) => s + r.bkash);
              final totalNagad =
                  reports.fold<double>(0, (s, r) => s + r.nagad);
              final totalApp =
                  reports.fold<double>(0, (s, r) => s + r.appCharge);

              // Build bar groups
              final sortedDays = byDay.keys.toList()..sort();
              final maxSale = byDay.values
                  .map((e) => e.sale)
                  .fold<double>(0, (a, b) => a > b ? a : b);

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.4,
                      children: [
                        StatTile(
                            label: 'মোট পার্সেল',
                            value: '$totalParcel',
                            icon: Icons.inventory_2_outlined,
                            color: const Color(0xFF3498DB)),
                        StatTile(
                            label: 'মোট সেল',
                            value: '৳${totalSale.toStringAsFixed(0)}',
                            icon: Icons.attach_money,
                            color: const Color(0xFF2ECC71)),
                        StatTile(
                            label: 'বিকাশ',
                            value: '৳${totalBkash.toStringAsFixed(0)}',
                            icon: Icons.phone_android,
                            color: const Color(0xFFE91E8C)),
                        StatTile(
                            label: 'নগদ',
                            value: '৳${totalNagad.toStringAsFixed(0)}',
                            icon: Icons.account_balance_wallet,
                            color: const Color(0xFFFF6B35)),
                        StatTile(
                            label: 'App চার্জ',
                            value: '৳${totalApp.toStringAsFixed(0)}',
                            icon: Icons.apps,
                            color: const Color(0xFF9B59B6)),
                        StatTile(
                            label: 'মোট রিটার্ন',
                            value: '$totalReturn',
                            icon: Icons.assignment_return,
                            color: const Color(0xFFE74C3C)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Bar chart - daily sale
                    Text(
                      'দৈনিক সেল (৳)',
                      style: GoogleFonts.hindSiliguri(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 220,
                      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.white.withAlpha(20)),
                      ),
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: maxSale * 1.2,
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (_) =>
                                  const Color(0xFF1B2A3B),
                              getTooltipItem: (group, gi, rod, ri) =>
                                  BarTooltipItem(
                                '৳${rod.toY.toStringAsFixed(0)}',
                                GoogleFonts.outfit(color: Colors.white),
                              ),
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 48,
                                getTitlesWidget: (v, _) => Text(
                                  v >= 1000
                                      ? '${(v / 1000).toStringAsFixed(0)}k'
                                      : v.toStringAsFixed(0),
                                  style: GoogleFonts.outfit(
                                      color: Colors.white38,
                                      fontSize: 10),
                                ),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, _) => Text(
                                  '${v.toInt()}',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white38,
                                      fontSize: 10),
                                ),
                              ),
                            ),
                            rightTitles: const AxisTitles(
                                sideTitles:
                                    SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(
                                sideTitles:
                                    SideTitles(showTitles: false)),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (_) => FlLine(
                              color: Colors.white.withAlpha(15),
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: sortedDays.map((day) {
                            return BarChartGroupData(
                              x: day,
                              barRods: [
                                BarChartRodData(
                                  toY: byDay[day]!.sale,
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF2ECC71),
                                      Color(0xFF27AE60)
                                    ],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                  width: 12,
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(6)),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Parcel vs Return bar chart
                    Text(
                      'পার্সেল vs রিটার্ন',
                      style: GoogleFonts.hindSiliguri(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    _buildParcelReturnChart(byDay, sortedDays),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildParcelReturnChart(
      Map<int, _DaySummary> byDay, List<int> sortedDays) {
    final maxY = sortedDays
            .map((d) => byDay[d]!.parcel.toDouble())
            .fold<double>(0, (a, b) => a > b ? a : b) *
        1.3;
    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}',
                  style:
                      GoogleFonts.outfit(color: Colors.white38, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}',
                  style:
                      GoogleFonts.outfit(color: Colors.white38, fontSize: 10),
                ),
              ),
            ),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: Colors.white.withAlpha(15), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: sortedDays.map((day) {
            return BarChartGroupData(
              x: day,
              barRods: [
                BarChartRodData(
                  toY: byDay[day]!.parcel.toDouble(),
                  color: const Color(0xFF3498DB),
                  width: 8,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4)),
                ),
                BarChartRodData(
                  toY: byDay[day]!.returns.toDouble(),
                  color: const Color(0xFFE74C3C),
                  width: 8,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _DaySummary {
  double sale = 0;
  int parcel = 0;
  int returns = 0;
  double bkash = 0;
  double nagad = 0;
  double app = 0;
}
