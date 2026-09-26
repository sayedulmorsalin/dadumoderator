import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../login_screen.dart';
import 'daily_report_tab.dart';
import 'monthly_report_tab.dart';
import 'yearly_report_tab.dart';
import 'wallet_tab.dart';
import '../ranking/moderator_ranking_tab.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _showEditNameDialog(AuthProvider auth) async {
    final nameCtrl = TextEditingController(text: auth.user?.name ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B2A3B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('নাম পরিবর্তন করুন',
            style: GoogleFonts.hindSiliguri(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameCtrl,
          style: GoogleFonts.hindSiliguri(color: Colors.white),
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'আপনার নাম',
            labelStyle: GoogleFonts.hindSiliguri(color: Colors.white54),
            prefixIcon:
                const Icon(Icons.person_outline, color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withAlpha(10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.white.withAlpha(30)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFF2ECC71), width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('বাতিল',
                style: GoogleFonts.hindSiliguri(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2ECC71)),
            child: Text('সংরক্ষণ',
                style: GoogleFonts.hindSiliguri(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true && nameCtrl.text.trim().isNotEmpty && mounted) {
      // ignore: use_build_context_synchronously
      final success = await auth.updateName(nameCtrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            success ? '✅ নাম আপডেট হয়েছে!' : 'নাম আপডেট ব্যর্থ হয়েছে।',
            style: GoogleFonts.hindSiliguri(color: Colors.white)),
        backgroundColor:
            success ? const Color(0xFF27AE60) : const Color(0xFFE74C3C),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'অ্যাডমিন ড্যাশবোর্ড',
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
                  onTap: () => _showEditNameDialog(auth),
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
              fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: GoogleFonts.hindSiliguri(fontSize: 10),
          isScrollable: true,
          tabs: const [
            Tab(text: 'দৈনিক', icon: Icon(Icons.today, size: 18)),
            Tab(text: 'মাসিক', icon: Icon(Icons.calendar_month, size: 18)),
            Tab(text: 'বার্ষিক', icon: Icon(Icons.bar_chart, size: 18)),
            Tab(
                text: 'ওয়ালেট',
                icon: Icon(Icons.account_balance_wallet, size: 18)),
            Tab(
                text: 'র‍্যাংকিং',
                icon: Icon(Icons.emoji_events_outlined, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          DailyReportTab(),
          MonthlyReportTab(),
          YearlyReportTab(),
          WalletTab(),
          ModeratorRankingTab(isAdmin: true),
        ],
      ),
    );
  }
}
