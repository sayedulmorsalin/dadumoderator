import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/sale_report.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import '../login_screen.dart';

class ModeratorHome extends StatefulWidget {
  const ModeratorHome({super.key});

  @override
  State<ModeratorHome> createState() => _ModeratorHomeState();
}

class _ModeratorHomeState extends State<ModeratorHome> {
  final _formKey = GlobalKey<FormState>();
  final _parcelCtrl = TextEditingController();
  final _saleCtrl = TextEditingController();
  final _bkashCtrl = TextEditingController();
  final _nagadCtrl = TextEditingController();
  final _appCtrl = TextEditingController();
  final _returnCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _parcelCtrl.dispose();
    _saleCtrl.dispose();
    _bkashCtrl.dispose();
    _nagadCtrl.dispose();
    _appCtrl.dispose();
    _returnCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF2ECC71),
              surface: Color(0xFF1B2A3B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final rp = context.read<ReportProvider>();

    final report = SaleReport(
      date: _selectedDate,
      moderatorId: auth.user!.uid,
      moderatorName: auth.user!.name,
      parcel: int.parse(_parcelCtrl.text),
      sale: double.parse(_saleCtrl.text),
      bkash: double.parse(_bkashCtrl.text.isEmpty ? '0' : _bkashCtrl.text),
      nagad: double.parse(_nagadCtrl.text.isEmpty ? '0' : _nagadCtrl.text),
      appCharge:
          double.parse(_appCtrl.text.isEmpty ? '0' : _appCtrl.text),
      returns: int.parse(_returnCtrl.text.isEmpty ? '0' : _returnCtrl.text),
      createdAt: DateTime.now(),
    );

    final success = await rp.submitReport(report);
    if (!mounted) return;
    if (success) {
      _formKey.currentState!.reset();
      _parcelCtrl.clear();
      _saleCtrl.clear();
      _bkashCtrl.clear();
      _nagadCtrl.clear();
      _appCtrl.clear();
      _returnCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ রিপোর্ট সংরক্ষিত হয়েছে!',
              style: GoogleFonts.hindSiliguri(color: Colors.white)),
          backgroundColor: const Color(0xFF27AE60),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(rp.submitError ?? 'ত্রুটি হয়েছে।',
              style: GoogleFonts.hindSiliguri(color: Colors.white)),
          backgroundColor: const Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final rp = context.watch<ReportProvider>();
    final uid = auth.user?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'দৈনিক সেল রিপোর্ট',
              style: GoogleFonts.hindSiliguri(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              auth.user?.name ?? '',
              style: GoogleFonts.hindSiliguri(
                  color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white54),
            onPressed: () async {
              await auth.signOut();
              if (!mounted) return;
              // ignore: use_build_context_synchronously
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            tooltip: 'লগআউট',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date selector
            _buildDateCard(),
            const SizedBox(height: 16),
            // Form
            _buildFormCard(rp),
            const SizedBox(height: 24),
            // Recent reports
            Text(
              'সাম্প্রতিক রিপোর্ট',
              style: GoogleFonts.hindSiliguri(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<SaleReport>>(
              stream: rp.getModeratorReports(uid),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF2ECC71)));
                }
                if (snap.hasError) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE74C3C).withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'রিপোর্ট লোড করা যায়নি: ${snap.error}',
                        style: GoogleFonts.hindSiliguri(
                            color: const Color(0xFFE74C3C), fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                final reports = snap.data ?? [];
                if (reports.isEmpty) {
                  return Center(
                    child: Text(
                      'কোনো রিপোর্ট নেই।',
                      style: GoogleFonts.hindSiliguri(color: Colors.white38),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reports.length > 7 ? 7 : reports.length,
                  itemBuilder: (_, i) => _ModeratorReportCard(
                    report: reports[i],
                    onDelete: () async {
                      final confirm = await _showDeleteDialog();
                      if (confirm == true && reports[i].id != null) {
                        await rp.deleteReport(reports[i].id!);
                      }
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    try {
      return DateFormat('dd MMMM yyyy', 'bn').format(dt);
    } catch (_) {
      return DateFormat('dd MMMM yyyy').format(dt);
    }
  }

  Widget _buildDateCard() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withAlpha(25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Color(0xFF2ECC71), size: 20),
            const SizedBox(width: 12),
            Text(
              _formatDate(_selectedDate),
              style: GoogleFonts.hindSiliguri(
                  color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text('পরিবর্তন করুন',
                style: GoogleFonts.hindSiliguri(
                    color: const Color(0xFF2ECC71), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard(ReportProvider rp) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(25)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('📦 পার্সেল ও সেল'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildField(_parcelCtrl, 'আজকের পার্সেল',
                      Icons.inventory_2_outlined,
                      isRequired: true, isInt: true),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                      _saleCtrl, 'আজকের সেল (৳)', Icons.attach_money,
                      isRequired: true),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _sectionHeader('🚚 ডেলিভারি চার্জ'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _buildField(
                        _bkashCtrl, 'বিকাশ (৳)', Icons.phone_android)),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildField(
                        _nagadCtrl, 'নগদ (৳)', Icons.account_balance_wallet)),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildField(_appCtrl, 'App (৳)', Icons.apps)),
              ],
            ),
            const SizedBox(height: 20),
            _sectionHeader('↩️ রিটার্ন'),
            const SizedBox(height: 12),
            _buildField(_returnCtrl, 'আজকের রিটার্ন', Icons.assignment_return,
                isInt: true),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: rp.isSubmitting ? null : _submit,
                icon: rp.isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded, color: Colors.white),
                label: Text(
                  rp.isSubmitting ? 'সংরক্ষণ হচ্ছে...' : 'রিপোর্ট সংরক্ষণ করুন',
                  style: GoogleFonts.hindSiliguri(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2ECC71),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 6,
                  shadowColor: const Color(0xFF2ECC71).withAlpha(80),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Text(
      text,
      style: GoogleFonts.hindSiliguri(
          color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool isRequired = false,
    bool isInt = false,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      style: GoogleFonts.hindSiliguri(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            GoogleFonts.hindSiliguri(color: Colors.white54, fontSize: 12),
        prefixIcon: Icon(icon, color: Colors.white38, size: 18),
        filled: true,
        fillColor: Colors.white.withAlpha(8),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withAlpha(25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFF2ECC71), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE74C3C)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFFE74C3C), width: 1.5),
        ),
        errorStyle: const TextStyle(color: Color(0xFFE74C3C), fontSize: 10),
      ),
      validator: (v) {
        if (isRequired && (v == null || v.isEmpty)) return 'প্রয়োজনীয়';
        if (v != null && v.isNotEmpty) {
          final num = double.tryParse(v);
          if (num == null) return 'সংখ্যা লিখুন';
          if (isInt && v.contains('.')) return 'পূর্ণ সংখ্যা';
          if (num < 0) return '০ বা বেশি';
        }
        return null;
      },
    );
  }

  Future<bool?> _showDeleteDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B2A3B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('রিপোর্ট মুছুন?',
            style: GoogleFonts.hindSiliguri(color: Colors.white)),
        content: Text('এই রিপোর্টটি স্থায়ীভাবে মুছে যাবে।',
            style: GoogleFonts.hindSiliguri(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('বাতিল',
                style: GoogleFonts.hindSiliguri(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE74C3C)),
            child: Text('মুছুন',
                style: GoogleFonts.hindSiliguri(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _ModeratorReportCard extends StatelessWidget {
  final SaleReport report;
  final VoidCallback onDelete;

  const _ModeratorReportCard(
      {required this.report, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd MMM yyyy').format(report.date),
                style: GoogleFonts.outfit(
                    color: const Color(0xFF2ECC71),
                    fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Color(0xFFE74C3C), size: 20),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _row('পার্সেল', '${report.parcel}টি', Icons.inventory_2_outlined),
          _row('সেল', '৳${report.sale.toStringAsFixed(0)}', Icons.attach_money),
          _row('বিকাশ', '৳${report.bkash.toStringAsFixed(0)}', Icons.phone_android),
          _row('নগদ', '৳${report.nagad.toStringAsFixed(0)}', Icons.account_balance_wallet),
          _row('App চার্জ', '৳${report.appCharge.toStringAsFixed(0)}', Icons.apps),
          _row('রিটার্ন', '${report.returns}টি', Icons.assignment_return),
        ],
      ),
    );
  }

  Widget _row(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white38),
          const SizedBox(width: 6),
          Text(label,
              style:
                  GoogleFonts.hindSiliguri(color: Colors.white54, fontSize: 12)),
          const Spacer(),
          Text(value,
              style: GoogleFonts.hindSiliguri(
                  color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
