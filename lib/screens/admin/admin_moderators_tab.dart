import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/app_user.dart';
import '../../models/sale_report.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../utils/moderator_profile_utils.dart';
import '../profile/moderator_profile_view.dart';

class AdminModeratorsTab extends StatefulWidget {
  const AdminModeratorsTab({super.key});

  @override
  State<AdminModeratorsTab> createState() => _AdminModeratorsTabState();
}

class _AdminModeratorsTabState extends State<AdminModeratorsTab> {
  late DateTime _selectedMonth;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _prevMonth() {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    if (next.isAfter(DateTime(now.year, now.month + 1, 1))) return;
    setState(() {
      _selectedMonth = next;
    });
  }

  void _jumpToCurrentMonth() {
    final now = DateTime.now();
    setState(() {
      _selectedMonth = DateTime(now.year, now.month, 1);
    });
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
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
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month, 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final rp = context.read<ReportProvider>();
    final wp = context.watch<WalletProvider>();

    return Column(
      children: [
        // Month Selector Bar
        _buildMonthBar(),

        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: TextField(
            controller: _searchCtrl,
            style: GoogleFonts.hindSiliguri(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'মডারেটরের নাম বা ইমেইল দিয়ে খুঁজুন...',
              hintStyle: GoogleFonts.hindSiliguri(color: Colors.white38, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
                      onPressed: () => _searchCtrl.clear(),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withAlpha(10),
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withAlpha(20)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withAlpha(20)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2ECC71), width: 1.5),
              ),
            ),
          ),
        ),

        // Content
        Expanded(
          child: StreamBuilder<List<SaleReport>>(
            stream: rp.getMonthlyReports(_selectedMonth.year, _selectedMonth.month),
            builder: (ctx, reportSnap) {
              if (reportSnap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2ECC71)),
                );
              }

              final monthlyReports = reportSnap.data ?? [];

              // Map reports by moderator ID
              final Map<String, List<SaleReport>> reportsByMod = {};
              for (final r in monthlyReports) {
                reportsByMod.putIfAbsent(r.moderatorId, () => []).add(r);
              }

              // Listen to all registered moderators
              return StreamBuilder<List<AppUser>>(
                stream: auth.getAllModerators(),
                builder: (ctx, userSnap) {
                  // In case user stream is still loading or users not populated, fallback to wallets
                  final registeredUsers = userSnap.data ?? [];

                  return StreamBuilder<List<dynamic>>(
                    stream: wp.getAllWallets(),
                    builder: (ctx, walletSnap) {
                      final wallets = walletSnap.data ?? [];

                      // Combine unique moderators from users, wallets, and reports
                      final Map<String, _ModeratorMeta> modMap = {};

                      // 1. From Users collection
                      for (final u in registeredUsers) {
                        modMap[u.uid] = _ModeratorMeta(
                          id: u.uid,
                          name: u.name.isNotEmpty ? u.name : 'মডারেটর',
                          email: u.email,
                        );
                      }

                      // 2. From Wallets (ensure any moderator not in users table is included)
                      for (final w in wallets) {
                        if (!modMap.containsKey(w.moderatorId)) {
                          modMap[w.moderatorId] = _ModeratorMeta(
                            id: w.moderatorId,
                            name: w.moderatorName,
                            email: '',
                          );
                        }
                      }

                      // 3. From Reports of this month (if any)
                      for (final r in monthlyReports) {
                        if (!modMap.containsKey(r.moderatorId)) {
                          modMap[r.moderatorId] = _ModeratorMeta(
                            id: r.moderatorId,
                            name: r.moderatorName,
                            email: '',
                          );
                        }
                      }

                      var moderators = modMap.values.toList();

                      // Filter by search query
                      if (_searchQuery.isNotEmpty) {
                        moderators = moderators.where((m) =>
                            m.name.toLowerCase().contains(_searchQuery) ||
                            m.email.toLowerCase().contains(_searchQuery)).toList();
                      }

                      // Sort by total sale of this month descending
                      moderators.sort((a, b) {
                        final saleA = (reportsByMod[a.id] ?? []).fold<double>(0, (s, r) => s + r.sale);
                        final saleB = (reportsByMod[b.id] ?? []).fold<double>(0, (s, r) => s + r.sale);
                        return saleB.compareTo(saleA);
                      });

                      if (moderators.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.people_outline, color: Colors.white24, size: 56),
                              const SizedBox(height: 10),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'কোনো মডারেটর খুঁজে পাওয়া যায়নি।'
                                    : 'কোনো মডারেটর অ্যাকাউন্ট নেই।',
                                style: GoogleFonts.hindSiliguri(color: Colors.white38),
                              ),
                            ],
                          ),
                        );
                      }

                      // Calculate Team Totals for summary banner
                      final totalTeamSale =
                          monthlyReports.fold<double>(0, (s, r) => s + r.sale);
                      final totalTeamParcel =
                          monthlyReports.fold<int>(0, (s, r) => s + r.parcel);
                      final totalTeamReturn =
                          monthlyReports.fold<int>(0, (s, r) => s + r.returns);

                      final teamRatio = DeliveryRatioInfo(
                        delivered: totalTeamParcel,
                        returned: totalTeamReturn,
                      );

                      int m1Count = 0;
                      int m2Count = 0;
                      int m3Count = 0;
                      for (final m in modMap.values) {
                        final sale = (reportsByMod[m.id] ?? []).fold<double>(0, (s, r) => s + r.sale);
                        final level = MilestoneConstants.getHighestAchievedLevel(sale);
                        if (level >= 1) m1Count++;
                        if (level >= 2) m2Count++;
                        if (level >= 3) m3Count++;
                      }

                      return ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        children: [
                          // Team Summary Banner
                          _buildTeamSummaryBanner(
                            totalSale: totalTeamSale,
                            teamRatio: teamRatio,
                            modCount: modMap.length,
                            m1Count: m1Count,
                            m2Count: m2Count,
                            m3Count: m3Count,
                          ),
                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'সকল মডারেটর (${moderators.length} জন)',
                                style: GoogleFonts.hindSiliguri(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'সেল অনুযায়ী সাজানো',
                                style: GoogleFonts.hindSiliguri(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Moderator list cards
                          ...moderators.asMap().entries.map((entry) {
                            final rank = entry.key + 1;
                            final mod = entry.value;
                            final reports = reportsByMod[mod.id] ?? [];
                            final sale = reports.fold<double>(0, (s, r) => s + r.sale);
                            final parcels = reports.fold<int>(0, (s, r) => s + r.parcel);
                            final returns = reports.fold<int>(0, (s, r) => s + r.returns);
                            final ratio = DeliveryRatioInfo(delivered: parcels, returned: returns);

                            return _buildModeratorCard(
                              context: context,
                              rank: rank,
                              mod: mod,
                              sale: sale,
                              ratio: ratio,
                              reportCount: reports.length,
                            );
                          }),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Month Navigation Bar ──────────────────────────────────────────────────
  Widget _buildMonthBar() {
    final now = DateTime.now();
    final isCurrentMonth =
        _selectedMonth.year == now.year && _selectedMonth.month == now.month;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: Colors.white70),
            onPressed: _prevMonth,
            tooltip: 'পূর্ববর্তী মাস',
          ),
          InkWell(
            onTap: _pickMonth,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, color: Color(0xFF2ECC71), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    ProfileFormatUtils.formatMonthYear(_selectedMonth),
                    style: GoogleFonts.hindSiliguri(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 20),
                ],
              ),
            ),
          ),
          Row(
            children: [
              if (!isCurrentMonth)
                GestureDetector(
                  onTap: _jumpToCurrentMonth,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2ECC71).withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'চলতি মাস',
                      style: GoogleFonts.hindSiliguri(
                        color: const Color(0xFF2ECC71),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              IconButton(
                icon: Icon(
                  Icons.chevron_right_rounded,
                  color: isCurrentMonth ? Colors.white24 : Colors.white70,
                ),
                onPressed: isCurrentMonth ? null : _nextMonth,
                tooltip: 'পরবর্তী মাস',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Team Summary Banner ───────────────────────────────────────────────────
  Widget _buildTeamSummaryBanner({
    required double totalSale,
    required DeliveryRatioInfo teamRatio,
    required int modCount,
    required int m1Count,
    required int m2Count,
    required int m3Count,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A5F), Color(0xFF132A45)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3498DB).withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'টিম ওভারভিউ ($modCount জন মডারেটর)',
                style: GoogleFonts.hindSiliguri(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: teamRatio.statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${teamRatio.deliveryRate.toStringAsFixed(1)}% ডেলিভারি রেট',
                  style: GoogleFonts.outfit(
                    color: teamRatio.statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                ProfileFormatUtils.formatMoney(totalSale),
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'মোট সেল',
                style: GoogleFonts.hindSiliguri(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Milestone achievements count pills
          Row(
            children: [
              _buildMilestoneAchieveBadge('২ লাখ', m1Count, const Color(0xFFE67E22)),
              const SizedBox(width: 8),
              _buildMilestoneAchieveBadge('৫ লাখ', m2Count, const Color(0xFF3498DB)),
              const SizedBox(width: 8),
              _buildMilestoneAchieveBadge('১০ লাখ', m3Count, const Color(0xFFFFD700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneAchieveBadge(String title, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          children: [
            Text(
              '$title টার্গেট',
              style: GoogleFonts.hindSiliguri(
                color: Colors.white54,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$count জন',
              style: GoogleFonts.hindSiliguri(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Moderator Card ────────────────────────────────────────────────────────
  Widget _buildModeratorCard({
    required BuildContext context,
    required int rank,
    required _ModeratorMeta mod,
    required double sale,
    required DeliveryRatioInfo ratio,
    required int reportCount,
  }) {
    final highestLevel = MilestoneConstants.getHighestAchievedLevel(sale);
    final nextMilestone = MilestoneConstants.getNextMilestone(sale);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highestLevel > 0
              ? MilestoneConstants.tiers[highestLevel - 1].color.withAlpha(60)
              : Colors.white.withAlpha(20),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ModeratorProfileScreen(
                  moderatorId: mod.id,
                  moderatorName: mod.name,
                  moderatorEmail: mod.email,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Moderator Info Row
                Row(
                  children: [
                    // Rank or Avatar
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: rank <= 3
                              ? [const Color(0xFFF39C12), const Color(0xFFD35400)]
                              : [const Color(0xFF2ECC71), const Color(0xFF27AE60)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          mod.name.isNotEmpty ? mod.name[0].toUpperCase() : 'M',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  mod.name,
                                  style: GoogleFonts.hindSiliguri(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (highestLevel > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: MilestoneConstants
                                        .tiers[highestLevel - 1]
                                        .color
                                        .withAlpha(30),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: MilestoneConstants
                                          .tiers[highestLevel - 1]
                                          .color
                                          .withAlpha(90),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        MilestoneConstants
                                            .tiers[highestLevel - 1].icon,
                                        size: 12,
                                        color: MilestoneConstants
                                            .tiers[highestLevel - 1].color,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        MilestoneConstants
                                            .tiers[highestLevel - 1].targetBn,
                                        style: GoogleFonts.hindSiliguri(
                                          color: MilestoneConstants
                                              .tiers[highestLevel - 1].color,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          if (mod.email.isNotEmpty)
                            Text(
                              mod.email,
                              style: GoogleFonts.outfit(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 12),

                // Sale and Ratio row
                Row(
                  children: [
                    // Monthly Sell
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('এই মাসের সেল',
                              style: GoogleFonts.hindSiliguri(
                                  color: Colors.white54, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(
                            ProfileFormatUtils.formatMoney(sale),
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF2ECC71),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (nextMilestone != null)
                            Text(
                              'বাকি: ${ProfileFormatUtils.formatMoney(nextMilestone.remaining(sale))}',
                              style: GoogleFonts.hindSiliguri(
                                color: Colors.white38,
                                fontSize: 10,
                              ),
                            )
                          else
                            Text(
                              'সব মাইলস্টোন অর্জিত! 🎉',
                              style: GoogleFonts.hindSiliguri(
                                color: const Color(0xFFFFD700),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 42, color: Colors.white10),
                    const SizedBox(width: 12),
                    // Delivery vs Return Ratio
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('ডেলিভারি vs রিটার্ন',
                                  style: GoogleFonts.hindSiliguri(
                                      color: Colors.white54, fontSize: 11)),
                              Text(
                                '${ratio.deliveryRate.toStringAsFixed(1)}%',
                                style: GoogleFonts.outfit(
                                  color: ratio.statusColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Mini bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: SizedBox(
                              height: 6,
                              child: ratio.totalHandled == 0
                                  ? Container(color: Colors.white12)
                                  : Row(
                                      children: [
                                        Expanded(
                                          flex: (ratio.deliveryRate * 10).round().clamp(1, 1000),
                                          child: Container(color: const Color(0xFF2ECC71)),
                                        ),
                                        if (ratio.returnRate > 0)
                                          Expanded(
                                            flex: (ratio.returnRate * 10).round().clamp(1, 1000),
                                            child: Container(color: const Color(0xFFE74C3C)),
                                          ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${ratio.delivered} ডেলিভারি • ${ratio.returned} রিটার্ন (${ratio.ratioString})',
                            style: GoogleFonts.hindSiliguri(
                              color: Colors.white38,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Tap to view profile indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'সম্পূর্ণ প্রোফাইল ও মাইলস্টোন দেখুন',
                      style: GoogleFonts.hindSiliguri(
                        color: const Color(0xFF3498DB),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: Color(0xFF3498DB), size: 11),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeratorMeta {
  final String id;
  final String name;
  final String email;

  _ModeratorMeta({
    required this.id,
    required this.name,
    required this.email,
  });
}
