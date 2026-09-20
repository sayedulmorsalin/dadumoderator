import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../login_screen.dart';
import 'daily_report_tab.dart';
import 'monthly_report_tab.dart';
import 'yearly_report_tab.dart';

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
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
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
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: const Color(0xFF2ECC71),
          indicatorWeight: 3,
          labelColor: const Color(0xFF2ECC71),
          unselectedLabelColor: Colors.white38,
          labelStyle: GoogleFonts.hindSiliguri(
              fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle:
              GoogleFonts.hindSiliguri(fontSize: 12),
          tabs: const [
            Tab(text: 'দৈনিক', icon: Icon(Icons.today, size: 18)),
            Tab(text: 'মাসিক', icon: Icon(Icons.calendar_month, size: 18)),
            Tab(text: 'বার্ষিক', icon: Icon(Icons.bar_chart, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          DailyReportTab(),
          MonthlyReportTab(),
          YearlyReportTab(),
        ],
      ),
    );
  }
}
