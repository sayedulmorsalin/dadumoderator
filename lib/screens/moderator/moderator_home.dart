import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/sale_report.dart';
import '../../models/payout_request.dart';
import '../../models/wallet.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../services/image_upload_service.dart';
import '../login_screen.dart';
import '../profile/moderator_profile_view.dart';
import '../ranking/moderator_ranking_tab.dart';

class ModeratorHome extends StatefulWidget {
  const ModeratorHome({super.key});

  @override
  State<ModeratorHome> createState() => _ModeratorHomeState();
}

class _ModeratorHomeState extends State<ModeratorHome>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _formKey = GlobalKey<FormState>();
  final _parcelCtrl = TextEditingController();
  final _saleCtrl = TextEditingController();
  final _bkashCtrl = TextEditingController();
  final _nagadCtrl = TextEditingController();
  final _appCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  // Delivery charge proof images
  File? _bkashImage;
  File? _nagadImage;
  File? _rocketImage;

  final _imagePicker = ImagePicker();
  final _imageUploadService = ImageUploadService();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _parcelCtrl.dispose();
    _saleCtrl.dispose();
    _bkashCtrl.dispose();
    _nagadCtrl.dispose();
    _appCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String channel) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF1B2A3B),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF2ECC71)),
              title: Text('ক্যামেরা', style: GoogleFonts.hindSiliguri(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF2ECC71)),
              title: Text('গ্যালারি', style: GoogleFonts.hindSiliguri(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await _imagePicker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    setState(() {
      final file = File(picked.path);
      if (channel == 'bkash') _bkashImage = file;
      if (channel == 'nagad') _nagadImage = file;
      if (channel == 'rocket') _rocketImage = file;
    });
  }

  void _removeImage(String channel) {
    setState(() {
      if (channel == 'bkash') _bkashImage = null;
      if (channel == 'nagad') _nagadImage = null;
      if (channel == 'rocket') _rocketImage = null;
    });
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

    // Upload proof images if selected
    String? bkashUrl;
    String? nagadUrl;
    String? rocketUrl;
    final uid = auth.user!.uid;
    final ts = DateTime.now().millisecondsSinceEpoch;
    try {
      if (_bkashImage != null) {
        bkashUrl = await _imageUploadService.compressAndUpload(
          file: _bkashImage!,
          storagePath: 'report_proofs/$uid/${ts}_bkash.jpg',
        );
      }
      if (_nagadImage != null) {
        nagadUrl = await _imageUploadService.compressAndUpload(
          file: _nagadImage!,
          storagePath: 'report_proofs/$uid/${ts}_nagad.jpg',
        );
      }
      if (_rocketImage != null) {
        rocketUrl = await _imageUploadService.compressAndUpload(
          file: _rocketImage!,
          storagePath: 'report_proofs/$uid/${ts}_rocket.jpg',
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ছবি আপলোড ব্যর্থ হয়েছে। আবার চেষ্টা করুন।',
              style: GoogleFonts.hindSiliguri(color: Colors.white)),
          backgroundColor: const Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

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
      returns: 0,
      commission: 0.0,
      createdAt: DateTime.now(),
      status: 'pending',
      bkashImageUrl: bkashUrl,
      nagadImageUrl: nagadUrl,
      rocketImageUrl: rocketUrl,
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
      setState(() {
        _bkashImage = null;
        _nagadImage = null;
        _rocketImage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ রিপোর্ট সংরক্ষিত হয়েছে! অ্যাডমিন অনুমোদনের জন্য অপেক্ষা করুন।',
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

  Future<void> _showEditNameDialog(BuildContext context, AuthProvider auth) async {
    final nameCtrl = TextEditingController(text: auth.user?.name ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B2A3B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('নাম পরিবর্তন করুন',
            style: GoogleFonts.hindSiliguri(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameCtrl,
          style: GoogleFonts.hindSiliguri(color: Colors.white),
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'আপনার নাম',
            labelStyle: GoogleFonts.hindSiliguri(color: Colors.white54),
            prefixIcon: const Icon(Icons.person_outline, color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withAlpha(10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.white.withAlpha(30)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF2ECC71), width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('বাতিল', style: GoogleFonts.hindSiliguri(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2ECC71)),
            child: Text('সংরক্ষণ', style: GoogleFonts.hindSiliguri(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true && nameCtrl.text.trim().isNotEmpty && mounted) {
      // ignore: use_build_context_synchronously
      final success = await auth.updateName(nameCtrl.text.trim());
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? '✅ নাম আপডেট হয়েছে!' : 'নাম আপডেট ব্যর্থ হয়েছে।',
            style: GoogleFonts.hindSiliguri(color: Colors.white)),
        backgroundColor: success ? const Color(0xFF27AE60) : const Color(0xFFE74C3C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
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
            Row(
              children: [
                Text(
                  auth.user?.name ?? '',
                  style: GoogleFonts.hindSiliguri(
                      color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _showEditNameDialog(context, auth),
                  child: const Icon(Icons.edit_outlined,
                      size: 13, color: Color(0xFF2ECC71)),
                ),
              ],
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
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: const Color(0xFF2ECC71),
          indicatorWeight: 3,
          labelColor: const Color(0xFF2ECC71),
          unselectedLabelColor: Colors.white38,
          labelStyle: GoogleFonts.hindSiliguri(
              fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'রিপোর্ট', icon: Icon(Icons.edit_document, size: 18)),
            Tab(text: 'র‍্যাংকিং', icon: Icon(Icons.emoji_events_outlined, size: 18)),
            Tab(text: 'ওয়ালেট', icon: Icon(Icons.account_balance_wallet, size: 18)),
            Tab(text: 'প্রোফাইল', icon: Icon(Icons.person, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _ReportTab(
            formKey: _formKey,
            parcelCtrl: _parcelCtrl,
            saleCtrl: _saleCtrl,
            bkashCtrl: _bkashCtrl,
            nagadCtrl: _nagadCtrl,
            appCtrl: _appCtrl,
            selectedDate: _selectedDate,
            onPickDate: _pickDate,
            onSubmit: _submit,
            uid: uid,
            bkashImage: _bkashImage,
            nagadImage: _nagadImage,
            rocketImage: _rocketImage,
            onPickImage: _pickImage,
            onRemoveImage: _removeImage,
          ),
          const ModeratorRankingTab(isAdmin: false),
          _WalletTab(uid: uid, moderatorName: auth.user?.name ?? ''),
          ModeratorProfileView(
            moderatorId: uid,
            moderatorName: auth.user?.name ?? '',
            moderatorEmail: auth.user?.email ?? '',
            isSelfView: true,
          ),
        ],
      ),
    );
  }
}

// ─── Report Tab ───────────────────────────────────────────────────────────────

class _ReportTab extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController parcelCtrl, saleCtrl, bkashCtrl, nagadCtrl, appCtrl;
  final DateTime selectedDate;
  final VoidCallback onPickDate;
  final Future<void> Function() onSubmit;
  final String uid;
  final File? bkashImage;
  final File? nagadImage;
  final File? rocketImage;
  final Future<void> Function(String channel) onPickImage;
  final void Function(String channel) onRemoveImage;

  const _ReportTab({
    required this.formKey,
    required this.parcelCtrl,
    required this.saleCtrl,
    required this.bkashCtrl,
    required this.nagadCtrl,
    required this.appCtrl,
    required this.selectedDate,
    required this.onPickDate,
    required this.onSubmit,
    required this.uid,
    this.bkashImage,
    this.nagadImage,
    this.rocketImage,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<ReportProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateCard(context),
          const SizedBox(height: 16),
          _buildFormCard(context, rp),
          const SizedBox(height: 24),
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
                itemCount: reports.length,
                itemBuilder: (_, i) => _ModeratorReportCard(
                  report: reports[i],
                  onEdit: () => _showEditSheet(context, reports[i], rp),
                  onDelivered: () => _showDeliveredSheet(context, reports[i], rp),
                  onDelete: () async {
                    final confirm = await _showDeleteDialog(context);
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
    );
  }

  String _formatDate(DateTime dt) {
    try {
      return DateFormat('dd MMMM yyyy', 'bn').format(dt);
    } catch (_) {
      return DateFormat('dd MMMM yyyy').format(dt);
    }
  }

  Widget _buildDateCard(BuildContext context) {
    return GestureDetector(
      onTap: onPickDate,
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
              _formatDate(selectedDate),
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

  Future<void> _showDeliveredSheet(
      BuildContext context, SaleReport report, ReportProvider rp) async {
    final parcelCtrl = TextEditingController(
        text: report.totalParcel > 0 ? report.totalParcel.toString() : '');
    final saleCtrl = TextEditingController(
        text: report.totalSale > 0 ? report.totalSale.toStringAsFixed(0) : '');
    final returnCtrl = TextEditingController(
        text: report.returns > 0 ? report.returns.toString() : '');
    final commCtrl = TextEditingController(
        text: report.commission > 0 ? report.commission.toStringAsFixed(0) : '');
    final sheetFormKey = GlobalKey<FormState>();
    bool isSaving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1B2A3B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: sheetFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3498DB).withAlpha(30),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.local_shipping_rounded,
                                color: Color(0xFF3498DB), size: 20),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Delivered তথ্য আপডেট',
                                style: GoogleFonts.hindSiliguri(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${DateFormat('dd MMMM yyyy', 'bn').format(report.date)} এর রিপোর্ট',
                                style: GoogleFonts.hindSiliguri(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3498DB).withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF3498DB).withAlpha(60)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Color(0xFF3498DB)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ডেলিভার্ড তথ্য সংরক্ষণের পর তা অ্যাডমিন অনুমোদনের জন্য অপেক্ষারত থাকবে।',
                            style: GoogleFonts.hindSiliguri(
                              color: const Color(0xFF3498DB),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 16),
                  _sectionHeader('📦 মোট পার্সেল ও মোট সেল'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildField(
                          parcelCtrl,
                          'মোট পার্সেল',
                          Icons.inventory_2_outlined,
                          isRequired: true,
                          isInt: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildField(
                          saleCtrl,
                          'মোট সেল (৳)',
                          Icons.attach_money,
                          isRequired: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _sectionHeader('↩️ মোট রিটার্ন ও 💰 কমিশন'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildField(
                          returnCtrl,
                          'মোট রিটার্ন',
                          Icons.assignment_return_outlined,
                          isRequired: true,
                          isInt: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildField(
                          commCtrl,
                          'কমিশন (৳)',
                          Icons.monetization_on_outlined,
                          isRequired: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (!sheetFormKey.currentState!.validate()) return;
                              setSheetState(() => isSaving = true);

                              final updated = report.copyWith(
                                totalParcel: int.tryParse(parcelCtrl.text) ?? report.totalParcel,
                                totalSale: double.tryParse(saleCtrl.text) ?? report.totalSale,
                                returns: int.tryParse(returnCtrl.text) ?? report.returns,
                                commission: double.tryParse(commCtrl.text) ?? report.commission,
                                status: 'pending',
                              );

                              final ok = await rp.updateReport(updated);
                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ok
                                        ? '✅ ডেলিভার্ড তথ্য জমা হয়েছে! অ্যাডমিন অনুমোদনের জন্য অপেক্ষা করুন।'
                                        : rp.submitError ?? 'আপডেট ব্যর্থ হয়েছে।',
                                    style: GoogleFonts.hindSiliguri(
                                        color: Colors.white),
                                  ),
                                  backgroundColor: ok
                                      ? const Color(0xFF27AE60)
                                      : const Color(0xFFE74C3C),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            },
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle, color: Colors.white),
                      label: Text(
                        isSaving ? 'সংরক্ষণ হচ্ছে...' : 'Delivered তথ্য সংরক্ষণ করুন',
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3498DB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
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

  Widget _buildFormCard(BuildContext context, ReportProvider rp) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(25)),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('📦 পার্সেল ও সেল'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildField(parcelCtrl, 'আজকের পার্সেল',
                      Icons.inventory_2_outlined,
                      isRequired: true, isInt: true),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                      saleCtrl, 'আজকের সেল (৳)', Icons.attach_money,
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
                        bkashCtrl, 'বিকাশ (৳)', Icons.phone_android)),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildField(
                        nagadCtrl, 'নগদ (৳)', Icons.account_balance_wallet)),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildField(appCtrl, 'রকেট (৳)', Icons.rocket_launch_outlined)),
              ],
            ),
            const SizedBox(height: 8),
            _DeliveryChargeSummary(
                bkashCtrl: bkashCtrl,
                nagadCtrl: nagadCtrl,
                appCtrl: appCtrl),
            const SizedBox(height: 10),
            // Image proof pickers
            _DeliveryImagePickers(
              bkashImage: bkashImage,
              nagadImage: nagadImage,
              rocketImage: rocketImage,
              onPickImage: onPickImage,
              onRemoveImage: onRemoveImage,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: rp.isSubmitting ? null : onSubmit,
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

  Future<bool?> _showDeleteDialog(BuildContext context) {
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

  Future<void> _showEditSheet(
      BuildContext context, SaleReport report, ReportProvider rp) async {
    final parcelCtrl = TextEditingController(text: report.parcel.toString());
    final saleCtrl =
        TextEditingController(text: report.sale.toStringAsFixed(0));
    final bkashCtrl =
        TextEditingController(text: report.bkash.toStringAsFixed(0));
    final nagadCtrl =
        TextEditingController(text: report.nagad.toStringAsFixed(0));
    final appCtrl =
        TextEditingController(text: report.appCharge.toStringAsFixed(0));
    final totalParcelCtrl = TextEditingController(
        text: report.totalParcel > 0 ? report.totalParcel.toString() : '');
    final totalSaleCtrl = TextEditingController(
        text: report.totalSale > 0 ? report.totalSale.toStringAsFixed(0) : '');
    final returnCtrl = TextEditingController(
        text: report.returns > 0 ? report.returns.toString() : '');
    final commCtrl = TextEditingController(
        text: report.commission > 0 ? report.commission.toStringAsFixed(0) : '');
    DateTime editDate = report.date;
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.edit_outlined,
                              color: Color(0xFF2ECC71), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'রিপোর্ট সম্পাদনা করুন',
                            style: GoogleFonts.hindSiliguri(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: editDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            builder: (c, child) => Theme(
                              data: Theme.of(c).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Color(0xFF2ECC71),
                                  surface: Color(0xFF1B2A3B),
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) {
                            setSheetState(() => editDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2ECC71).withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFF2ECC71).withAlpha(60)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today,
                                  size: 12, color: Color(0xFF2ECC71)),
                              const SizedBox(width: 6),
                              Text(
                                DateFormat('dd MMM yyyy').format(editDate),
                                style: GoogleFonts.outfit(
                                    color: const Color(0xFF2ECC71),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE67E22).withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE67E22).withAlpha(60)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Color(0xFFE67E22)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'প্রতিটি পার্সেলের জন্য মাত্র ১ বার সম্পাদনার অনুরোধ করা যাবে এবং তা অ্যাডমিন অনুমোদন করবেন।',
                            style: GoogleFonts.hindSiliguri(
                              color: const Color(0xFFE67E22),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _sheetSectionLabel('📦 পার্সেল ও সেল'),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                        child: _sheetEditField(parcelCtrl, 'পার্সেল',
                            Icons.inventory_2_outlined,
                            isInt: true)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _sheetEditField(
                            saleCtrl, 'সেল (৳)', Icons.attach_money)),
                  ]),
                  const SizedBox(height: 12),
                  _sheetSectionLabel('🚚 ডেলিভারি চার্জ'),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                        child: _sheetEditField(
                            bkashCtrl, 'বিকাশ', Icons.phone_android)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _sheetEditField(nagadCtrl, 'নগদ',
                            Icons.account_balance_wallet)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _sheetEditField(appCtrl, 'রকেট', Icons.rocket_launch_outlined)),
                  ]),
                  const SizedBox(height: 8),
                  _DeliveryChargeSummary(
                      bkashCtrl: bkashCtrl,
                      nagadCtrl: nagadCtrl,
                      appCtrl: appCtrl),
                  const SizedBox(height: 12),
                  _sheetSectionLabel('🏁 ডেলিভার্ড তথ্য (মোট পার্সেল ও মোট সেল)'),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                        child: _sheetEditField(totalParcelCtrl, 'মোট পার্সেল',
                            Icons.local_shipping_outlined,
                            isInt: true)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _sheetEditField(
                            totalSaleCtrl, 'মোট সেল (৳)', Icons.payments_outlined)),
                  ]),
                  const SizedBox(height: 12),
                  _sheetSectionLabel('↩️ রিটার্ন ও 💰 কমিশন'),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                        child: _sheetEditField(returnCtrl, 'মোট রিটার্ন',
                            Icons.assignment_return_outlined,
                            isInt: true)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _sheetEditField(commCtrl, 'কমিশন (৳)',
                            Icons.monetization_on_outlined)),
                  ]),
                  if (report.extraType != 'none') ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: (report.extraType == 'bonus'
                                ? const Color(0xFFF1C40F)
                                : const Color(0xFFE74C3C))
                            .withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: (report.extraType == 'bonus'
                                  ? const Color(0xFFF1C40F)
                                  : const Color(0xFFE74C3C))
                              .withAlpha(50),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            report.extraType == 'bonus'
                                ? Icons.star_outline
                                : Icons.warning_amber_outlined,
                            color: report.extraType == 'bonus'
                                ? const Color(0xFFF1C40F)
                                : const Color(0xFFE74C3C),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  report.extraType == 'bonus'
                                      ? 'বোনাস: ৳${report.extra.abs().toStringAsFixed(0)} (শুধু অ্যাডমিন পরিবর্তন করতে পারবেন)'
                                      : 'জরিমানা: ৳${report.extra.abs().toStringAsFixed(0)} (শুধু অ্যাডমিন পরিবর্তন করতে পারবেন)',
                                  style: GoogleFonts.hindSiliguri(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                if (report.extraNote.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'নোট: ${report.extraNote}',
                                    style: GoogleFonts.hindSiliguri(
                                      color: (report.extraType == 'bonus'
                                          ? const Color(0xFFF1C40F)
                                          : const Color(0xFFE74C3C)),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final updated = report.copyWith(
                          date: editDate,
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
                          totalParcel: int.tryParse(totalParcelCtrl.text) ??
                              report.totalParcel,
                          totalSale: double.tryParse(totalSaleCtrl.text) ??
                              report.totalSale,
                          returns: int.tryParse(returnCtrl.text) ??
                              report.returns,
                          commission: double.tryParse(commCtrl.text) ??
                              report.commission,
                          extra: report.extra,
                          extraType: report.extraType,
                          extraNote: report.extraNote,
                          status: 'pending',
                          editCount: report.editCount + 1,
                        );
                        Navigator.pop(ctx);
                        final messenger = ScaffoldMessenger.of(context);
                        final ok = await rp.updateReport(updated);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? '✅ সম্পাদনার অনুরোধ জমা হয়েছে! অ্যাডমিন অনুমোদনের জন্য অপেক্ষা করুন।'
                                  : rp.submitError ?? 'অনুরোধ ব্যর্থ হয়েছে।',
                              style: GoogleFonts.hindSiliguri(
                                  color: Colors.white),
                            ),
                            backgroundColor: ok
                                ? const Color(0xFF27AE60)
                                : const Color(0xFFE74C3C),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      label: Text('সম্পাদনার অনুরোধ পাঠান',
                          style: GoogleFonts.hindSiliguri(
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2ECC71),
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

  Widget _sheetSectionLabel(String text) => Text(text,
      style: GoogleFonts.hindSiliguri(
          color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600));

  Widget _sheetEditField(TextEditingController ctrl, String label, IconData icon,
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
            borderSide: const BorderSide(color: Color(0xFF2ECC71))),
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
}

// ─── Wallet Tab ───────────────────────────────────────────────────────────────

class _WalletTab extends StatelessWidget {
  final String uid;
  final String moderatorName;

  const _WalletTab({required this.uid, required this.moderatorName});

  @override
  Widget build(BuildContext context) {
    final wp = context.watch<WalletProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wallet balance card and inline payout request section
          StreamBuilder<Wallet?>(
            stream: wp.getWallet(uid),
            builder: (ctx, snap) {
              final wallet = snap.data;
              return Column(
                children: [
                  _WalletBalanceCard(
                    wallet: wallet,
                    isLoading: snap.connectionState == ConnectionState.waiting,
                  ),
                  const SizedBox(height: 16),
                  _PayoutRequestSection(
                    wallet: wallet,
                    uid: uid,
                    moderatorName: moderatorName,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'পেআউট ইতিহাস',
            style: GoogleFonts.hindSiliguri(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<PayoutRequest>>(
            stream: wp.getPayoutRequests(uid),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2ECC71)));
              }
              final requests = snap.data ?? [];
              if (requests.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'কোনো পেআউট রিকোয়েস্ট নেই।',
                      style: GoogleFonts.hindSiliguri(color: Colors.white38),
                    ),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: requests.length,
                itemBuilder: (_, i) => _PayoutRequestCard(req: requests[i]),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Inline Payout Request Section ────────────────────────────────────────────

class _PayoutRequestSection extends StatefulWidget {
  final Wallet? wallet;
  final String uid;
  final String moderatorName;

  const _PayoutRequestSection({
    required this.wallet,
    required this.uid,
    required this.moderatorName,
  });

  @override
  State<_PayoutRequestSection> createState() => _PayoutRequestSectionState();
}

class _PayoutRequestSectionState extends State<_PayoutRequestSection> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(WalletProvider wp) async {
    final balance = widget.wallet?.balance ?? 0.0;
    if (balance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'উইথড্র করার মতো পর্যাপ্ত ব্যালেন্স নেই।',
            style: GoogleFonts.hindSiliguri(color: Colors.white),
          ),
          backgroundColor: const Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
    if (amount > balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'পরিমাণ আপনার ব্যালেন্স (৳${balance.toStringAsFixed(2)}) এর বেশি হতে পারবে না।',
            style: GoogleFonts.hindSiliguri(color: Colors.white),
          ),
          backgroundColor: const Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    final success = await wp.requestPayout(
      moderatorId: widget.uid,
      moderatorName: widget.moderatorName,
      amount: amount,
      note: _noteCtrl.text.trim(),
    );

    if (!mounted) return;
    if (success) {
      _amountCtrl.clear();
      _noteCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ ৳${amount.toStringAsFixed(2)} এর পেআউট রিকোয়েস্ট সফলভাবে পাঠানো হয়েছে!',
            style: GoogleFonts.hindSiliguri(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF27AE60),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wp.error ?? 'পেআউট রিকোয়েস্ট পাঠানো যায়নি।',
            style: GoogleFonts.hindSiliguri(color: Colors.white),
          ),
          backgroundColor: const Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final wp = context.watch<WalletProvider>();
    final balance = widget.wallet?.balance ?? 0.0;
    final hasBalance = balance > 0;

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2ECC71).withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.send_rounded,
                          color: Color(0xFF2ECC71), size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'পেআউট রিকোয়েস্ট',
                      style: GoogleFonts.hindSiliguri(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasBalance
                        ? const Color(0xFF2ECC71).withAlpha(25)
                        : Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasBalance
                          ? const Color(0xFF2ECC71).withAlpha(60)
                          : Colors.white24,
                    ),
                  ),
                  child: Text(
                    'ব্যালেন্স: ৳${balance.toStringAsFixed(2)}',
                    style: GoogleFonts.outfit(
                      color: hasBalance
                          ? const Color(0xFF2ECC71)
                          : Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'আপনার ব্যালেন্সের মধ্যে যেকোনো পরিমাণ লিখে পেআউট রিকোয়েস্ট পাঠান:',
              style: GoogleFonts.hindSiliguri(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            // Amount Input Field (constrained under balance)
            TextFormField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                labelText: 'উত্তোলনের পরিমাণ (৳)',
                hintText: 'যেমন: 500',
                hintStyle:
                    const TextStyle(color: Colors.white24, fontSize: 13),
                labelStyle:
                    GoogleFonts.hindSiliguri(color: Colors.white60),
                prefixIcon: const Icon(Icons.monetization_on_outlined,
                    color: Color(0xFF2ECC71), size: 20),
                suffixIcon: hasBalance
                    ? Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: TextButton(
                          onPressed: () {
                            _amountCtrl.text = balance % 1 == 0
                                ? balance.toInt().toString()
                                : balance.toStringAsFixed(2);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'সব ব্যালেন্স',
                            style: GoogleFonts.hindSiliguri(
                              color: const Color(0xFF2ECC71),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                    : null,
                helperText:
                    'পরিমাণ অবশ্যই বর্তমান ব্যালেন্স (৳${balance.toStringAsFixed(2)}) এর নিচে বা সমান হতে হবে',
                helperStyle: GoogleFonts.hindSiliguri(
                  color: Colors.white38,
                  fontSize: 11,
                ),
                filled: true,
                fillColor: Colors.white.withAlpha(8),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withAlpha(25)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF2ECC71), width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE74C3C)),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFFE74C3C), width: 1.5),
                ),
                errorStyle: const TextStyle(
                    color: Color(0xFFE74C3C), fontSize: 11),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'পরিমাণ লিখুন';
                final amt = double.tryParse(v.trim());
                if (amt == null || amt <= 0) return 'সঠিক পরিমাণ লিখুন';
                if (amt > balance) {
                  return 'ব্যালেন্সের বেশি নয় (সর্বোচ্চ ৳${balance.toStringAsFixed(2)})';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            // Note Field
            TextFormField(
              controller: _noteCtrl,
              style:
                  GoogleFonts.hindSiliguri(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'নোট বা পেমেন্ট মাধ্যম (ঐচ্ছিক)',
                hintText: 'যেমন: বিকাশ/নগদ 017xxxxxxxx',
                hintStyle:
                    const TextStyle(color: Colors.white24, fontSize: 12),
                labelStyle:
                    GoogleFonts.hindSiliguri(color: Colors.white60),
                prefixIcon: const Icon(Icons.note_alt_outlined,
                    color: Colors.white38, size: 18),
                filled: true,
                fillColor: Colors.white.withAlpha(8),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withAlpha(25)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF2ECC71), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed:
                    (!hasBalance || wp.isLoading) ? null : () => _submit(wp),
                icon: wp.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded,
                        color: Colors.white, size: 18),
                label: Text(
                  wp.isLoading
                      ? 'পাঠানো হচ্ছে...'
                      : (hasBalance
                          ? 'পেআউট রিকোয়েস্ট পাঠান'
                          : 'উইথড্র করার মতো ব্যালেন্স নেই'),
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2ECC71),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white12,
                  disabledForegroundColor: Colors.white38,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: hasBalance ? 4 : 0,
                  shadowColor: const Color(0xFF2ECC71).withAlpha(80),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletBalanceCard extends StatelessWidget {
  final Wallet? wallet;
  final bool isLoading;

  const _WalletBalanceCard({
    required this.wallet,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3A2A), Color(0xFF0D2A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2ECC71).withAlpha(60)),
      ),
      child: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2ECC71)))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2ECC71).withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.account_balance_wallet,
                          color: Color(0xFF2ECC71), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text('আমার ওয়ালেট',
                        style: GoogleFonts.hindSiliguri(
                            color: Colors.white70, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '৳ ${(wallet?.balance ?? 0).toStringAsFixed(2)}',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('বর্তমান ব্যালেন্স',
                    style: GoogleFonts.hindSiliguri(
                        color: Colors.white38, fontSize: 12)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _miniStat('মোট আয়',
                        '৳${(wallet?.totalEarned ?? 0).toStringAsFixed(0)}',
                        const Color(0xFF2ECC71)),
                    const SizedBox(width: 16),
                    _miniStat('মোট উত্তোলন',
                        '৳${(wallet?.totalWithdrawn ?? 0).toStringAsFixed(0)}',
                        const Color(0xFFFF6B35)),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.hindSiliguri(
                    color: Colors.white54, fontSize: 10)),
            const SizedBox(height: 2),
            Text(value,
                style: GoogleFonts.outfit(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _PayoutRequestCard extends StatelessWidget {
  final PayoutRequest req;

  const _PayoutRequestCard({required this.req});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    if (req.isApproved) {
      statusColor = const Color(0xFF2ECC71);
      statusLabel = 'অনুমোদিত';
      statusIcon = Icons.check_circle_outline;
    } else if (req.isRejected) {
      statusColor = const Color(0xFFE74C3C);
      statusLabel = 'প্রত্যাখ্যাত';
      statusIcon = Icons.cancel_outlined;
    } else {
      statusColor = const Color(0xFFF39C12);
      statusLabel = 'অপেক্ষারত';
      statusIcon = Icons.hourglass_top_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withAlpha(40)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('৳${req.amount.toStringAsFixed(2)}',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                Text(
                  DateFormat('dd MMM yyyy').format(req.requestedAt),
                  style: GoogleFonts.outfit(
                      color: Colors.white38, fontSize: 11),
                ),
                if (req.note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(req.note,
                      style: GoogleFonts.hindSiliguri(
                          color: Colors.white54, fontSize: 11)),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(statusLabel,
                style: GoogleFonts.hindSiliguri(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ─── Moderator Report Card ────────────────────────────────────────────────────

class _ModeratorReportCard extends StatelessWidget {
  final SaleReport report;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDelivered;

  const _ModeratorReportCard({
    required this.report,
    required this.onEdit,
    required this.onDelete,
    required this.onDelivered,
  });

  Color _statusColor() {
    if (report.isDeliveredPending) return const Color(0xFF3498DB);
    if (report.isEditRequested) return const Color(0xFFE67E22);
    if (report.isApproved) return const Color(0xFF2ECC71);
    if (report.isRejected) return const Color(0xFFE74C3C);
    return const Color(0xFFF39C12);
  }

  String _statusLabel() {
    if (report.isDeliveredPending) return '⏳ ডেলিভারি অনুমোদনের অপেক্ষায়';
    if (report.isEditRequested) return '⏳ সম্পাদনা অপেক্ষারত';
    if (report.isApproved) return '✅ অনুমোদিত';
    if (report.isRejected) return '❌ প্রত্যাখ্যাত';
    return '⏳ অপেক্ষারত';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _statusColor().withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('dd MMM yyyy').format(report.date),
                    style: GoogleFonts.outfit(
                        color: const Color(0xFF2ECC71),
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statusColor().withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _statusColor().withAlpha(70)),
                    ),
                    child: Text(
                      _statusLabel(),
                      style: GoogleFonts.hindSiliguri(
                          color: _statusColor(),
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (report.canRequestEdit) ...[
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          color: Color(0xFF3498DB), size: 20),
                      onPressed: onEdit,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'সম্পাদনা অনুরোধ (১ বার প্রযোজ্য)',
                    ),
                    const SizedBox(width: 12),
                  ] else ...[
                    const Tooltip(
                      message: 'সম্পাদনার অনুরোধ সীমা শেষ (১ বার ব্যবহৃত)',
                      child: Icon(Icons.edit_off_outlined,
                          color: Colors.white24, size: 18),
                    ),
                    const SizedBox(width: 12),
                  ],
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Color(0xFFE74C3C), size: 20),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'মুছুন',
                  ),
                ],
              ),
            ],
          ),
          _row('বুকিং পার্সেল', '${report.parcel}টি', Icons.inventory_2_outlined),
          _row('বুকিং সেল', '৳${report.sale.toStringAsFixed(0)}', Icons.attach_money),
          _row('বিকাশ', '৳${report.bkash.toStringAsFixed(0)}', Icons.phone_android),
          _row('নগদ', '৳${report.nagad.toStringAsFixed(0)}', Icons.account_balance_wallet),
          _row('রকেট', '৳${report.appCharge.toStringAsFixed(0)}', Icons.rocket_launch_outlined),
          _totalDeliveryRow(report),
          if (report.totalParcel > 0 || report.totalSale > 0) ...[
            _row('ডেলিভার্ড পার্সেল', '${report.totalParcel}টি', Icons.local_shipping_outlined,
                valueColor: const Color(0xFF3498DB)),
            _row('ডেলিভার্ড সেল', '৳${report.totalSale.toStringAsFixed(0)}', Icons.payments_outlined,
                valueColor: const Color(0xFF3498DB)),
          ],
          _row('রিটার্ন', '${report.returns}টি', Icons.assignment_return),
          _row('কমিশন', '৳${report.commission.toStringAsFixed(0)}', Icons.monetization_on_outlined,
              valueColor: const Color(0xFF2ECC71)),
          if (report.extraType != 'none') ...[
            _row(
              report.extraType == 'bonus' ? '🎁 বোনাস' : '⚠️ জরিমানা',
              '৳${report.extra.abs().toStringAsFixed(0)}',
              report.extraType == 'bonus'
                  ? Icons.star_outline
                  : Icons.warning_amber_outlined,
              valueColor: report.extraType == 'bonus'
                  ? const Color(0xFFF1C40F)
                  : const Color(0xFFE74C3C),
            ),
            if (report.extraNote.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (report.extraType == 'bonus'
                          ? const Color(0xFFF1C40F)
                          : const Color(0xFFE74C3C))
                      .withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (report.extraType == 'bonus'
                            ? const Color(0xFFF1C40F)
                            : const Color(0xFFE74C3C))
                        .withAlpha(40),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 13,
                      color: report.extraType == 'bonus'
                          ? const Color(0xFFF1C40F)
                          : const Color(0xFFE74C3C),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'অ্যাডমিন নোট: ${report.extraNote}',
                        style: GoogleFonts.hindSiliguri(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
          // Proof images
          if (report.bkashImageUrl != null ||
              report.nagadImageUrl != null ||
              report.rocketImageUrl != null) ...[
            const SizedBox(height: 8),
            _ProofImagesMini(
              bkashUrl: report.bkashImageUrl,
              nagadUrl: report.nagadImageUrl,
              rocketUrl: report.rocketImageUrl,
            ),
          ],
          // Admin rejection note
          if (report.isRejected && report.adminNote.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE74C3C).withAlpha(15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE74C3C).withAlpha(40)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cancel_outlined,
                      size: 13, color: Color(0xFFE74C3C)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'প্রত্যাখ্যানের কারণ: ${report.adminNote}',
                      style: GoogleFonts.hindSiliguri(
                        color: const Color(0xFFE74C3C),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: OutlinedButton.icon(
              onPressed: onDelivered,
              icon: const Icon(Icons.local_shipping_outlined, size: 16),
              label: Text(
                'Delivered',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF3498DB),
                side: const BorderSide(color: Color(0xFF3498DB), width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: const Color(0xFF3498DB).withAlpha(15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalDeliveryRow(SaleReport report) {
    final total = report.totalDeliveryCharge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF2ECC71).withAlpha(18),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF2ECC71).withAlpha(50)),
        ),
        child: Row(
          children: [
            const Icon(Icons.local_shipping_outlined,
                size: 14, color: Color(0xFF2ECC71)),
            const SizedBox(width: 6),
            Text('মোট ডেলিভারি চার্জ',
                style: GoogleFonts.hindSiliguri(
                    color: const Color(0xFF2ECC71),
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('৳${total.toStringAsFixed(0)}',
                style: GoogleFonts.hindSiliguri(
                    color: const Color(0xFF2ECC71),
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
  Widget _row(String label, String value, IconData icon,
      {Color? valueColor}) {
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
                  color: valueColor ?? Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ],
      ),
    );
  }
}

// --- Delivery Charge Live Summary ---

class _DeliveryChargeSummary extends StatefulWidget {
  final TextEditingController bkashCtrl;
  final TextEditingController nagadCtrl;
  final TextEditingController appCtrl;

  const _DeliveryChargeSummary({
    required this.bkashCtrl,
    required this.nagadCtrl,
    required this.appCtrl,
  });

  @override
  State<_DeliveryChargeSummary> createState() => _DeliveryChargeSummaryState();
}

class _DeliveryChargeSummaryState extends State<_DeliveryChargeSummary> {
  @override
  void initState() {
    super.initState();
    widget.bkashCtrl.addListener(_rebuild);
    widget.nagadCtrl.addListener(_rebuild);
    widget.appCtrl.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    widget.bkashCtrl.removeListener(_rebuild);
    widget.nagadCtrl.removeListener(_rebuild);
    widget.appCtrl.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bkash = double.tryParse(widget.bkashCtrl.text) ?? 0;
    final nagad = double.tryParse(widget.nagadCtrl.text) ?? 0;
    final rocket = double.tryParse(widget.appCtrl.text) ?? 0;
    final total = bkash + nagad + rocket;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2ECC71).withAlpha(18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2ECC71).withAlpha(50)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_shipping_outlined,
              size: 15, color: Color(0xFF2ECC71)),
          const SizedBox(width: 8),
          Text('মোট ডেলিভারি চার্জ',
              style: GoogleFonts.hindSiliguri(
                  color: const Color(0xFF2ECC71),
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('৳${total.toStringAsFixed(0)}',
              style: GoogleFonts.hindSiliguri(
                  color: const Color(0xFF2ECC71),
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ],
      ),
    );
  }
}

// --- Delivery Image Pickers (below delivery charge section) ---

class _DeliveryImagePickers extends StatelessWidget {
  final File? bkashImage;
  final File? nagadImage;
  final File? rocketImage;
  final Future<void> Function(String channel) onPickImage;
  final void Function(String channel) onRemoveImage;

  const _DeliveryImagePickers({
    required this.bkashImage,
    required this.nagadImage,
    required this.rocketImage,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📎 ডেলিভারি চার্জের প্রমাণ (ঐচ্ছিক)',
          style: GoogleFonts.hindSiliguri(
              color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _channelPicker(
              channel: 'bkash',
              label: 'বিকাশ',
              color: const Color(0xFFE91E8C),
              image: bkashImage,
            ),
            const SizedBox(width: 8),
            _channelPicker(
              channel: 'nagad',
              label: 'নগদ',
              color: const Color(0xFFFF6B35),
              image: nagadImage,
            ),
            const SizedBox(width: 8),
            _channelPicker(
              channel: 'rocket',
              label: 'রকেট',
              color: const Color(0xFF9B59B6),
              image: rocketImage,
            ),
          ],
        ),
      ],
    );
  }

  Widget _channelPicker({
    required String channel,
    required String label,
    required Color color,
    required File? image,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onPickImage(channel),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 80,
          decoration: BoxDecoration(
            color: image != null ? color.withAlpha(20) : Colors.white.withAlpha(8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: image != null ? color.withAlpha(120) : Colors.white.withAlpha(25),
              width: image != null ? 1.5 : 1,
            ),
          ),
          child: image != null
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Image.file(
                        image,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Gradient overlay at top for button contrast
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 28,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withAlpha(150),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Channel label badge at bottom
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(180),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          label,
                          style: GoogleFonts.hindSiliguri(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // Remove button at top right
                    Positioned(
                      top: 3,
                      right: 3,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onRemoveImage(channel),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE74C3C),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        color: color, size: 22),
                    const SizedBox(height: 4),
                    Text(label,
                        style: GoogleFonts.hindSiliguri(
                            color: color, fontSize: 10)),
                  ],
                ),
        ),
      ),
    );
  }
}

// --- Mini Proof Images for Moderator Card ---

class _ProofImagesMini extends StatelessWidget {
  final String? bkashUrl;
  final String? nagadUrl;
  final String? rocketUrl;

  const _ProofImagesMini({this.bkashUrl, this.nagadUrl, this.rocketUrl});

  @override
  Widget build(BuildContext context) {
    final items = <Map<String, dynamic>>[];
    if (bkashUrl != null) {
      items.add({'label': 'বিকাশ', 'url': bkashUrl!, 'color': const Color(0xFFE91E8C)});
    }
    if (nagadUrl != null) {
      items.add({'label': 'নগদ', 'url': nagadUrl!, 'color': const Color(0xFFFF6B35)});
    }
    if (rocketUrl != null) {
      items.add({'label': 'রকেট', 'url': rocketUrl!, 'color': const Color(0xFF9B59B6)});
    }
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('📎 প্রমাণ',
            style: GoogleFonts.hindSiliguri(
                color: Colors.white38, fontSize: 10)),
        const SizedBox(height: 4),
        Row(
          children: items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _showFullImage(context, item),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        item['url'] as String,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, prog) {
                          if (prog == null) return child;
                          return Container(
                            width: 56,
                            height: 56,
                            color: Colors.white10,
                            child: const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Color(0xFF2ECC71)),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (ctx3, e, st) => Container(
                          width: 56,
                          height: 56,
                          color: Colors.white10,
                          child: const Icon(Icons.broken_image_outlined,
                              color: Colors.white38, size: 22),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(item['label'] as String,
                        style: GoogleFonts.hindSiliguri(
                            color: item['color'] as Color, fontSize: 9)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showFullImage(BuildContext context, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text('${item["label"]} — প্রমাণ',
                      style: GoogleFonts.hindSiliguri(
                          color: item['color'] as Color,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(dialogCtx),
                  ),
                ],
              ),
            ),
            InteractiveViewer(
              child: Image.network(
                item['url'] as String,
                fit: BoxFit.contain,
                errorBuilder: (ctx2, e, st) => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Icon(Icons.broken_image_outlined,
                      color: Colors.white38, size: 64),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}