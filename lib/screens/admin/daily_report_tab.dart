import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/sale_report.dart';
import '../../providers/report_provider.dart';
import '../../widgets/report_card.dart';
import '../../widgets/stat_tile.dart';

class DailyReportTab extends StatefulWidget {
  const DailyReportTab({super.key});

  @override
  State<DailyReportTab> createState() => _DailyReportTabState();
}

class _DailyReportTabState extends State<DailyReportTab> {
  DateTime _selectedDay = DateTime.now();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF2ECC71),
            surface: Color(0xFF1B2A3B),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDay = picked);
  }

  @override
  Widget build(BuildContext context) {
    final rp = context.read<ReportProvider>();
    return Column(
      children: [
        // Date picker header
        Padding(
          padding: const EdgeInsets.all(16),
          child: GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withAlpha(25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      color: Color(0xFF2ECC71), size: 20),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('dd MMMM yyyy').format(_selectedDay),
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text('পরিবর্তন',
                      style: GoogleFonts.hindSiliguri(
                          color: const Color(0xFF2ECC71), fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<SaleReport>>(
            stream: rp.getDailyReports(_selectedDay),
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
                      Text(
                        'এই দিনে কোনো রিপোর্ট নেই।',
                        style: GoogleFonts.hindSiliguri(
                            color: Colors.white38, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }
              // Summary aggregation
              final totalParcel =
                  reports.fold<int>(0, (s, r) => s + r.parcel);
              final totalSale =
                  reports.fold<double>(0, (s, r) => s + r.sale);
              final totalBkash =
                  reports.fold<double>(0, (s, r) => s + r.bkash);
              final totalNagad =
                  reports.fold<double>(0, (s, r) => s + r.nagad);
              final totalApp =
                  reports.fold<double>(0, (s, r) => s + r.appCharge);
              final totalReturn =
                  reports.fold<int>(0, (s, r) => s + r.returns);

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary
                    Text(
                      'সারসংক্ষেপ (${reports.length} জন মডারেটর)',
                      style: GoogleFonts.hindSiliguri(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
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
                    Text(
                      'সকল রিপোর্ট',
                      style: GoogleFonts.hindSiliguri(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    ...reports.map((r) => ReportCard(report: r)),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
