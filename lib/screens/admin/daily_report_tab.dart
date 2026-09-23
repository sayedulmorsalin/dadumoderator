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

  Future<void> _showEditSheet(SaleReport report) async {
    final rp = context.read<ReportProvider>();
    final parcelCtrl =
        TextEditingController(text: report.parcel.toString());
    final saleCtrl =
        TextEditingController(text: report.sale.toStringAsFixed(0));
    final bkashCtrl =
        TextEditingController(text: report.bkash.toStringAsFixed(0));
    final nagadCtrl =
        TextEditingController(text: report.nagad.toStringAsFixed(0));
    final appCtrl =
        TextEditingController(text: report.appCharge.toStringAsFixed(0));
    final returnCtrl =
        TextEditingController(text: report.returns.toString());
    final commCtrl =
        TextEditingController(text: report.commission.toStringAsFixed(0));
    final extraCtrl = TextEditingController(
        text: report.extra.abs().toStringAsFixed(0));
    final extraNoteCtrl = TextEditingController(text: report.extraNote);
    String extraType = report.extraType == 'none' ? 'none' : report.extraType;
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1B2A3B),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 24),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.edit_outlined,
                          color: Color(0xFF3498DB), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${report.moderatorName} — রিপোর্ট সম্পাদনা',
                        style: GoogleFonts.hindSiliguri(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _sectionLabel('📦 পার্সেল ও সেল'),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                        child: _editField(parcelCtrl, 'পার্সেল',
                            Icons.inventory_2_outlined,
                            isInt: true)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _editField(
                            saleCtrl, 'সেল (৳)', Icons.attach_money)),
                  ]),
                  const SizedBox(height: 12),
                  _sectionLabel('🚚 ডেলিভারি চার্জ'),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                        child: _editField(
                            bkashCtrl, 'বিকাশ', Icons.phone_android)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _editField(nagadCtrl, 'নগদ',
                            Icons.account_balance_wallet)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _editField(appCtrl, 'App', Icons.apps)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: _editField(returnCtrl, 'রিটার্ন',
                            Icons.assignment_return,
                            isInt: true)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _editField(commCtrl, 'কমিশন (৳)',
                            Icons.monetization_on_outlined)),
                  ]),
                  const SizedBox(height: 16),
                  // Admin-only: Extra (bonus/fine)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF39C12).withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFFF39C12).withAlpha(40)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.admin_panel_settings,
                                color: Color(0xFFF39C12), size: 16),
                            const SizedBox(width: 6),
                            Text('এক্সট্রা (শুধু অ্যাডমিন)',
                                style: GoogleFonts.hindSiliguri(
                                    color: const Color(0xFFF39C12),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Bonus / Fine / None toggle
                        Row(children: [
                          _extraTypeBtn('none', 'নেই', setSheetState,
                              extraType, (v) => extraType = v),
                          const SizedBox(width: 8),
                          _extraTypeBtn('bonus', '🎁 বোনাস', setSheetState,
                              extraType, (v) => extraType = v),
                          const SizedBox(width: 8),
                          _extraTypeBtn('fine', '⚠️ জরিমানা', setSheetState,
                              extraType, (v) => extraType = v),
                        ]),
                        if (extraType != 'none') ...[
                          const SizedBox(height: 10),
                          _editField(extraCtrl, 'পরিমাণ (৳)',
                              Icons.currency_exchange),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: extraNoteCtrl,
                            style: GoogleFonts.hindSiliguri(
                                color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: extraType == 'bonus'
                                  ? 'বোনাসের কারণ / নোট'
                                  : 'জরিমানার কারণ / নোট',
                              hintText: 'মডারেটর এই নোটটি দেখতে পাবেন',
                              hintStyle: const TextStyle(
                                  color: Colors.white24, fontSize: 11),
                              labelStyle: GoogleFonts.hindSiliguri(
                                  color: Colors.white60, fontSize: 11),
                              prefixIcon: const Icon(Icons.comment_outlined,
                                  color: Colors.white38, size: 16),
                              filled: true,
                              fillColor: Colors.white.withAlpha(8),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 10),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                      color: Colors.white.withAlpha(25))),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                      color: Color(0xFFF39C12))),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        double extraVal = 0;
                        if (extraType != 'none') {
                          final ev = double.tryParse(extraCtrl.text) ?? 0;
                          extraVal =
                              extraType == 'fine' ? -ev.abs() : ev.abs();
                        }
                        final updated = report.copyWith(
                          parcel: int.tryParse(parcelCtrl.text) ??
                              report.parcel,
                          sale: double.tryParse(saleCtrl.text) ??
                              report.sale,
                          bkash: double.tryParse(bkashCtrl.text) ??
                              report.bkash,
                          nagad: double.tryParse(nagadCtrl.text) ??
                              report.nagad,
                          appCharge: double.tryParse(appCtrl.text) ??
                              report.appCharge,
                          returns: int.tryParse(returnCtrl.text) ??
                              report.returns,
                          commission: double.tryParse(commCtrl.text) ??
                              report.commission,
                          extra: extraVal,
                          extraType: extraType,
                          extraNote: extraType == 'none'
                              ? ''
                              : extraNoteCtrl.text.trim(),
                        );
                        Navigator.pop(ctx);
                        final messenger = ScaffoldMessenger.of(context);
                        final ok = await rp.updateReport(updated);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? '✅ রিপোর্ট আপডেট হয়েছে!'
                                  : rp.submitError ?? 'আপডেট ব্যর্থ হয়েছে।',
                              style: GoogleFonts.hindSiliguri(
                                  color: Colors.white),
                            ),
                            backgroundColor: ok
                                ? const Color(0xFF27AE60)
                                : const Color(0xFFE74C3C),
                            behavior: SnackBarBehavior.floating,
                          ),

                        );
                      },
                      icon: const Icon(Icons.save_rounded, color: Colors.white),
                      label: Text('আপডেট সংরক্ষণ করুন',
                          style: GoogleFonts.hindSiliguri(
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3498DB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: GoogleFonts.hindSiliguri(
          color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600));

  Widget _editField(TextEditingController ctrl, String label, IconData icon,
      {bool isInt = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      style: GoogleFonts.hindSiliguri(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.hindSiliguri(color: Colors.white54, fontSize: 11),
        prefixIcon: Icon(icon, color: Colors.white38, size: 16),
        filled: true,
        fillColor: Colors.white.withAlpha(8),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.white.withAlpha(25))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF3498DB))),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE74C3C))),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE74C3C))),
        errorStyle: const TextStyle(color: Color(0xFFE74C3C), fontSize: 9),
      ),
      validator: (v) {
        if (v != null && v.isNotEmpty) {
          final n = double.tryParse(v);
          if (n == null) return 'সংখ্যা';
          if (isInt && v.contains('.')) return 'পূর্ণ';
          if (n < 0) return '≥0';
        }
        return null;
      },
    );
  }

  Widget _extraTypeBtn(
    String type,
    String label,
    StateSetter setSheetState,
    String currentType,
    void Function(String) onChanged,
  ) {
    final isSelected = currentType == type;
    Color color;
    if (type == 'bonus') {
      color = const Color(0xFFF1C40F);
    } else if (type == 'fine') {
      color = const Color(0xFFE74C3C);
    } else {
      color = Colors.white38;
    }
    return Expanded(
      child: GestureDetector(
        onTap: () => setSheetState(() => onChanged(type)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withAlpha(40) : Colors.white.withAlpha(8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: isSelected ? color : Colors.white.withAlpha(20)),
          ),
          child: Center(
            child: Text(label,
                style: GoogleFonts.hindSiliguri(
                    color: isSelected ? color : Colors.white54,
                    fontSize: 11,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal)),
          ),
        ),
      ),
    );
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
              final totalCommission =
                  reports.fold<double>(0, (s, r) => s + r.commission);
              final totalExtra =
                  reports.fold<double>(0, (s, r) => s + r.extra);

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
                        StatTile(
                            label: 'মোট কমিশন',
                            value: '৳${totalCommission.toStringAsFixed(0)}',
                            icon: Icons.monetization_on_outlined,
                            color: const Color(0xFF2ECC71)),
                        StatTile(
                            label: 'নেট এক্সট্রা',
                            value: '৳${totalExtra.toStringAsFixed(0)}',
                            icon: Icons.add_circle_outline,
                            color: totalExtra >= 0
                                ? const Color(0xFFF1C40F)
                                : const Color(0xFFE74C3C)),
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
                    ...reports.map((r) => ReportCard(
                          report: r,
                          onEdit: () => _showEditSheet(r),
                        )),
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
