import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/sale_report.dart';
import '../../providers/report_provider.dart';
import '../../widgets/stat_tile.dart';

class YearlyReportTab extends StatefulWidget {
  const YearlyReportTab({super.key});

  @override
  State<YearlyReportTab> createState() => _YearlyReportTabState();
}

class _YearlyReportTabState extends State<YearlyReportTab> {
  int _year = DateTime.now().year;

  static const _monthNames = [
    'জানু', 'ফেব্রু', 'মার্চ', 'এপ্রিল',
    'মে', 'জুন', 'জুলাই', 'আগস্ট',
    'সেপ্টে', 'অক্টো', 'নভে', 'ডিসে'
  ];

  @override
  Widget build(BuildContext context) {
    final rp = context.read<ReportProvider>();
    return Column(
      children: [
        // Year navigator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white70),
                onPressed: () => setState(() => _year--),
              ),
              Text(
                '$_year',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white70),
                onPressed: () {
                  if (_year < DateTime.now().year) {
                    setState(() => _year++);
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<SaleReport>>(
            stream: rp.getYearlyReports(_year),
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
                      Text('এই বছরে কোনো রিপোর্ট নেই।',
                          style: GoogleFonts.hindSiliguri(
                              color: Colors.white38)),
                    ],
                  ),
                );
              }

              // Aggregate per month
              final Map<int, _MonthSummary> byMonth = {};
              for (final r in reports) {
                final m = r.date.month;
                byMonth[m] ??= _MonthSummary();
                byMonth[m]!.sale += r.sale;
                byMonth[m]!.parcel += r.parcel;
                byMonth[m]!.returns += r.returns;
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

              final spots = List.generate(12, (i) {
                final m = i + 1;
                return FlSpot(i.toDouble(), byMonth[m]?.sale ?? 0);
              });

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary KPIs
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

                    // Monthly sale line chart
                    Text(
                      'মাসিক সেল ট্রেন্ড (৳)',
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
                      child: LineChart(
                        LineChartData(
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipColor: (_) =>
                                  const Color(0xFF1B2A3B),
                              getTooltipItems: (spots) =>
                                  spots.map((s) {
                                return LineTooltipItem(
                                  '৳${s.y.toStringAsFixed(0)}',
                                  GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                );
                              }).toList(),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (_) => FlLine(
                              color: Colors.white.withAlpha(15),
                              strokeWidth: 1,
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 52,
                                getTitlesWidget: (v, _) => Text(
                                  v >= 1000
                                      ? '${(v / 1000).toStringAsFixed(0)}k'
                                      : v.toStringAsFixed(0),
                                  style: GoogleFonts.outfit(
                                      color: Colors.white38,
                                      fontSize: 9),
                                ),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, _) {
                                  final idx = v.toInt();
                                  if (idx < 0 || idx > 11) {
                                    return const SizedBox();
                                  }
                                  return Text(
                                    _monthNames[idx],
                                    style: GoogleFonts.hindSiliguri(
                                        color: Colors.white38,
                                        fontSize: 9),
                                  );
                                },
                              ),
                            ),
                            rightTitles: const AxisTitles(
                                sideTitles:
                                    SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(
                                sideTitles:
                                    SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF2ECC71),
                                  Color(0xFF3498DB)
                                ],
                              ),
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter:
                                    (spot, percent, bar, index) {
                                  return FlDotCirclePainter(
                                    radius: 4,
                                    color: Colors.white,
                                    strokeWidth: 2,
                                    strokeColor:
                                        const Color(0xFF2ECC71),
                                  );
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF2ECC71)
                                        .withAlpha(60),
                                    const Color(0xFF3498DB)
                                        .withAlpha(10),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Monthly parcel bar chart
                    Text(
                      'মাসিক পার্সেল',
                      style: GoogleFonts.hindSiliguri(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    _buildMonthlyParcelChart(byMonth),
                    const SizedBox(height: 24),

                    // Monthly breakdown table
                    Text(
                      'মাসওয়ারি বিস্তারিত',
                      style: GoogleFonts.hindSiliguri(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    _buildMonthTable(byMonth),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyParcelChart(Map<int, _MonthSummary> byMonth) {
    final maxY = List.generate(12, (i) => byMonth[i + 1]?.parcel.toDouble() ?? 0)
        .fold<double>(0, (a, b) => a > b ? a : b) * 1.3;
    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY == 0 ? 10 : maxY,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}',
                  style: GoogleFonts.outfit(
                      color: Colors.white38, fontSize: 9),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= 12) return const SizedBox();
                  return Text(_monthNames[idx],
                      style: GoogleFonts.hindSiliguri(
                          color: Colors.white38, fontSize: 8));
                },
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
          barGroups: List.generate(12, (i) {
            final m = i + 1;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: byMonth[m]?.parcel.toDouble() ?? 0,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 14,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(5)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildMonthTable(Map<int, _MonthSummary> byMonth) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                    child: Text('মাস',
                        style: GoogleFonts.hindSiliguri(
                            color: const Color(0xFF2ECC71),
                            fontWeight: FontWeight.bold,
                            fontSize: 12))),
                Expanded(
                    child: Text('সেল',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.hindSiliguri(
                            color: Colors.white54, fontSize: 12))),
                Expanded(
                    child: Text('পার্সেল',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.hindSiliguri(
                            color: Colors.white54, fontSize: 12))),
                Expanded(
                    child: Text('রিটার্ন',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.hindSiliguri(
                            color: Colors.white54, fontSize: 12))),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          ...List.generate(12, (i) {
            final m = i + 1;
            final s = byMonth[m];
            if (s == null || s.sale == 0) return const SizedBox.shrink();
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(_monthNames[i],
                              style: GoogleFonts.hindSiliguri(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12))),
                      Expanded(
                          child: Text(
                              '৳${s.sale.toStringAsFixed(0)}',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                  color: const Color(0xFF2ECC71),
                                  fontSize: 12))),
                      Expanded(
                          child: Text('${s.parcel}',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                  color: const Color(0xFF3498DB),
                                  fontSize: 12))),
                      Expanded(
                          child: Text('${s.returns}',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                  color: const Color(0xFFE74C3C),
                                  fontSize: 12))),
                    ],
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _MonthSummary {
  double sale = 0;
  int parcel = 0;
  int returns = 0;
}
