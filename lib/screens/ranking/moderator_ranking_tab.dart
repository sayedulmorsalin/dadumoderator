import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/app_user.dart';
import '../../models/sale_report.dart';
import '../../models/moderator_of_month.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../services/ranking_service.dart';
import '../../utils/moderator_profile_utils.dart';
import '../profile/moderator_profile_view.dart';

class ModeratorRankingTab extends StatefulWidget {
  final bool isAdmin;

  const ModeratorRankingTab({super.key, this.isAdmin = false});

  @override
  State<ModeratorRankingTab> createState() => _ModeratorRankingTabState();
}

class _ModeratorRankingTabState extends State<ModeratorRankingTab> {
  late DateTime _selectedMonth;
  final TextEditingController _searchCtrl = TextEditingController();
  final RankingService _rankingService = RankingService();
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
    final currentUserId = auth.user?.uid ?? '';

    return Column(
      children: [
        // Month Selector Bar & Hall of Fame button
        _buildMonthBar(),

        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(
            controller: _searchCtrl,
            style: GoogleFonts.hindSiliguri(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'মডারেটরের নাম দিয়ে খুঁজুন...',
              hintStyle:
                  GoogleFonts.hindSiliguri(color: Colors.white38, fontSize: 12),
              prefixIcon:
                  const Icon(Icons.search_rounded, color: Colors.white38, size: 18),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white38, size: 16),
                      onPressed: () => _searchCtrl.clear(),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withAlpha(10),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withAlpha(20)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withAlpha(20)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Color(0xFF2ECC71), width: 1.5),
              ),
            ),
          ),
        ),

        // Body with Ranking Stream
        Expanded(
          child: StreamBuilder<List<SaleReport>>(
            stream: rp.getMonthlyReports(
                _selectedMonth.year, _selectedMonth.month),
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

              return StreamBuilder<List<AppUser>>(
                stream: auth.getAllModerators(),
                builder: (ctx, userSnap) {
                  final registeredUsers = userSnap.data ?? [];

                  return StreamBuilder<List<dynamic>>(
                    stream: wp.getAllWallets(),
                    builder: (ctx, walletSnap) {
                      final wallets = walletSnap.data ?? [];

                      // Aggregate distinct moderators
                      final Map<String, _ModEntry> modMap = {};
                      for (final u in registeredUsers) {
                        modMap[u.uid] = _ModEntry(
                          id: u.uid,
                          name: u.name.isNotEmpty ? u.name : 'মডারেটর',
                          email: u.email,
                        );
                      }
                      for (final w in wallets) {
                        if (!modMap.containsKey(w.moderatorId)) {
                          modMap[w.moderatorId] = _ModEntry(
                            id: w.moderatorId,
                            name: w.moderatorName,
                            email: '',
                          );
                        }
                      }
                      for (final r in monthlyReports) {
                        if (!modMap.containsKey(r.moderatorId)) {
                          modMap[r.moderatorId] = _ModEntry(
                            id: r.moderatorId,
                            name: r.moderatorName,
                            email: '',
                          );
                        }
                      }

                      // Build ranking items
                      final List<_RankingItem> allRankings = [];
                      for (final m in modMap.values) {
                        final reps = reportsByMod[m.id] ?? [];
                        final sale = reps.fold<double>(0, (s, r) => s + r.sale);
                        final parcels = reps.fold<int>(0, (s, r) => s + r.parcel);
                        final returns = reps.fold<int>(0, (s, r) => s + r.returns);
                        final ratio = DeliveryRatioInfo(
                            delivered: parcels, returned: returns);

                        allRankings.add(_RankingItem(
                          id: m.id,
                          name: m.name,
                          email: m.email,
                          totalSale: sale,
                          delivered: parcels,
                          returned: returns,
                          ratio: ratio,
                          reportsCount: reps.length,
                        ));
                      }

                      // Sort by total sale descending, then delivery rate descending
                      allRankings.sort((a, b) {
                        final comp = b.totalSale.compareTo(a.totalSale);
                        if (comp != 0) return comp;
                        return b.ratio.deliveryRate.compareTo(a.ratio.deliveryRate);
                      });

                      // Assign rank numbers
                      for (int i = 0; i < allRankings.length; i++) {
                        allRankings[i].rank = i + 1;
                      }

                      // Check auto-save if month has ended and #1 has sale > 0
                      final now = DateTime.now();
                      final isPastMonth = now.isAfter(DateTime(
                          _selectedMonth.year, _selectedMonth.month + 1, 1));
                      if (isPastMonth &&
                          allRankings.isNotEmpty &&
                          allRankings.first.totalSale > 0) {
                        final top = allRankings.first;
                        _rankingService.autoFinalizePastMonthIfPending(
                          year: _selectedMonth.year,
                          month: _selectedMonth.month,
                          candidate: ModeratorOfMonth(
                            id: RankingService.docIdFor(
                                _selectedMonth.year, _selectedMonth.month),
                            year: _selectedMonth.year,
                            month: _selectedMonth.month,
                            moderatorId: top.id,
                            moderatorName: top.name,
                            moderatorEmail: top.email,
                            totalSale: top.totalSale,
                            deliveryCount: top.delivered,
                            returnCount: top.returned,
                            deliveryRate: top.ratio.deliveryRate,
                            crownedAt: DateTime.now(),
                            note: 'স্বয়ংক্রিয়ভাবে সর্বোচ্চ সেল অনুযায়ী নির্বাচিত',
                          ),
                        );
                      }

                      // Filter for search
                      var displayRankings = allRankings;
                      if (_searchQuery.isNotEmpty) {
                        displayRankings = allRankings
                            .where((r) =>
                                r.name.toLowerCase().contains(_searchQuery) ||
                                r.email.toLowerCase().contains(_searchQuery))
                            .toList();
                      }

                      return StreamBuilder<ModeratorOfMonth?>(
                        stream: _rankingService.getModeratorOfMonthStream(
                            _selectedMonth.year, _selectedMonth.month),
                        builder: (ctx, winnerSnap) {
                          final savedWinner = winnerSnap.data;

                          return ListView(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            children: [
                              // 1. Moderator of the Month Showcase Card
                              _buildModeratorOfMonthShowcase(
                                savedWinner: savedWinner,
                                currentLeader: allRankings.isNotEmpty &&
                                        allRankings.first.totalSale > 0
                                    ? allRankings.first
                                    : null,
                                isPastMonth: isPastMonth,
                                canAdminCrown: widget.isAdmin &&
                                    isPastMonth &&
                                    allRankings.isNotEmpty &&
                                    allRankings.first.totalSale > 0,
                                topRanked: allRankings.isNotEmpty
                                    ? allRankings.first
                                    : null,
                              ),
                              const SizedBox(height: 18),

                              // 2. Podium View for Top 3 (if at least 1 has sales)
                              if (_searchQuery.isEmpty &&
                                  allRankings.isNotEmpty &&
                                  allRankings.first.totalSale > 0) ...[
                                _buildPodiumSection(allRankings),
                                const SizedBox(height: 20),
                              ],

                              // 3. Section Header
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.format_list_numbered_rounded,
                                          color: Color(0xFF2ECC71), size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        'পূর্ণাঙ্গ র‍্যাংকিং তালিকা (${displayRankings.length} জন)',
                                        style: GoogleFonts.hindSiliguri(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'সেল ও রেশিও ভিত্তিক',
                                    style: GoogleFonts.hindSiliguri(
                                      color: Colors.white38,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              if (displayRankings.isEmpty)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Text(
                                      'কোনো মডারেটর খুঁজে পাওয়া যায়নি।',
                                      style: GoogleFonts.hindSiliguri(
                                          color: Colors.white38),
                                    ),
                                  ),
                                )
                              else
                                ...displayRankings.map((item) {
                                  final isSelf = item.id == currentUserId;
                                  return _buildRankingCard(item, isSelf);
                                }),
                              const SizedBox(height: 32),
                            ],
                          );
                        },
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

  // ─── Month Bar ─────────────────────────────────────────────────────────────
  Widget _buildMonthBar() {
    final now = DateTime.now();
    final isCurrentMonth =
        _selectedMonth.year == now.year && _selectedMonth.month == now.month;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded,
                    color: Colors.white70, size: 22),
                onPressed: _prevMonth,
                tooltip: 'পূর্ববর্তী মাস',
              ),
              InkWell(
                onTap: _pickMonth,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month,
                          color: Color(0xFF2ECC71), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        ProfileFormatUtils.formatMonthYear(_selectedMonth),
                        style: GoogleFonts.hindSiliguri(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down,
                          color: Colors.white54, size: 18),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.chevron_right_rounded,
                  color: isCurrentMonth ? Colors.white24 : Colors.white70,
                  size: 22,
                ),
                onPressed: isCurrentMonth ? null : _nextMonth,
                tooltip: 'পরবর্তী মাস',
              ),
            ],
          ),
          Row(
            children: [
              if (!isCurrentMonth)
                GestureDetector(
                  onTap: _jumpToCurrentMonth,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2ECC71).withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'চলতি মাস',
                      style: GoogleFonts.hindSiliguri(
                        color: const Color(0xFF2ECC71),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              // Hall of Fame button
              InkWell(
                onTap: _showHallOfFameSheet,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF39C12), Color(0xFFD35400)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF39C12).withAlpha(60),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events_rounded,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'মাস সেরা তালিকা',
                        style: GoogleFonts.hindSiliguri(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 1. Moderator of the Month Showcase Banner ─────────────────────────────
  Widget _buildModeratorOfMonthShowcase({
    required ModeratorOfMonth? savedWinner,
    required _RankingItem? currentLeader,
    required bool isPastMonth,
    required bool canAdminCrown,
    required _RankingItem? topRanked,
  }) {
    // Case A: Official Crowned Winner saved in Firestore
    if (savedWinner != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2D2305), Color(0xFF1B1B0A), Color(0xFF0F1E2E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFFD700).withAlpha(120), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withAlpha(40),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.emoji_events_rounded,
                          color: Color(0xFFFFD700), size: 22),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🏆 মাস সেরা মডারেটর (অফিসিয়াল)',
                          style: GoogleFonts.hindSiliguri(
                            color: const Color(0xFFFFD700),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          ProfileFormatUtils.formatMonthYear(_selectedMonth),
                          style: GoogleFonts.outfit(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFFFFD700).withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded,
                          color: Color(0xFFFFD700), size: 13),
                      const SizedBox(width: 4),
                      Text(
                        'সেরা পারফর্মার',
                        style: GoogleFonts.hindSiliguri(
                          color: const Color(0xFFFFD700),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                // Avatar with crown
                Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFD4AC0D)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withAlpha(80),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          savedWinner.moderatorName.isNotEmpty
                              ? savedWinner.moderatorName[0].toUpperCase()
                              : 'M',
                          style: GoogleFonts.outfit(
                            color: Colors.black,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const Icon(Icons.military_tech,
                        color: Color(0xFFFFD700), size: 20),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        savedWinner.moderatorName,
                        style: GoogleFonts.hindSiliguri(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'মোট সেল: ${ProfileFormatUtils.formatMoney(savedWinner.totalSale)}',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2ECC71),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ডেলিভারি সাকসেস রেট: ${savedWinner.deliveryRate.toStringAsFixed(1)}% (${savedWinner.deliveryCount}টি ডেলিভারি / ${savedWinner.returnCount}টি রিটার্ন)',
                        style: GoogleFonts.hindSiliguri(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (savedWinner.note.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'নোট: ${savedWinner.note}',
                  style: GoogleFonts.hindSiliguri(
                    color: Colors.white60,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            if (widget.isAdmin) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _showCrownDialog(
                    candidateId: savedWinner.moderatorId,
                    candidateName: savedWinner.moderatorName,
                    candidateEmail: savedWinner.moderatorEmail,
                    totalSale: savedWinner.totalSale,
                    deliveryCount: savedWinner.deliveryCount,
                    returnCount: savedWinner.returnCount,
                    deliveryRate: savedWinner.deliveryRate,
                    existingNote: savedWinner.note,
                  ),
                  icon: const Icon(Icons.edit, size: 14, color: Color(0xFFFFD700)),
                  label: Text('নোট বা তথ্য আপডেট করুন',
                      style: GoogleFonts.hindSiliguri(
                          color: const Color(0xFFFFD700), fontSize: 11)),
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Case B: Live Current Month Leader or Pending Past Month
    if (currentLeader != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A5F), Color(0xFF132232)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF3498DB).withAlpha(80)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.stars_rounded,
                        color: Color(0xFFF1C40F), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      isPastMonth
                          ? 'মাসের শীর্ষ পারফর্মার'
                          : 'চলতি মাসে শীর্ষে রয়েছেন 👑',
                      style: GoogleFonts.hindSiliguri(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ECC71).withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isPastMonth ? 'মাস শেষ হয়েছে' : 'লাইভ র‍্যাংক #১',
                    style: GoogleFonts.hindSiliguri(
                      color: const Color(0xFF2ECC71),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFF39C12), Color(0xFFD35400)],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      currentLeader.name.isNotEmpty
                          ? currentLeader.name[0].toUpperCase()
                          : 'M',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 20,
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
                      Text(
                        currentLeader.name,
                        style: GoogleFonts.hindSiliguri(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'মোট সেল: ${ProfileFormatUtils.formatMoney(currentLeader.totalSale)}',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2ECC71),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ডেলিভারি রেশিও: ${currentLeader.ratio.deliveryRate.toStringAsFixed(1)}% (${currentLeader.ratio.ratioString})',
                        style: GoogleFonts.hindSiliguri(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (canAdminCrown && topRanked != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showCrownDialog(
                    candidateId: topRanked.id,
                    candidateName: topRanked.name,
                    candidateEmail: topRanked.email,
                    totalSale: topRanked.totalSale,
                    deliveryCount: topRanked.delivered,
                    returnCount: topRanked.returned,
                    deliveryRate: topRanked.ratio.deliveryRate,
                  ),
                  icon: const Icon(Icons.military_tech_rounded,
                      size: 16, color: Colors.white),
                  label: Text('মাস সেরা মডারেটর নিশ্চিত ও সংরক্ষণ করুন',
                      style: GoogleFonts.hindSiliguri(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF39C12),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Default: Empty month
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.white38, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'এই মাসে এখনো কোনো সেলের তথ্য রেকর্ড হয়নি।',
              style: GoogleFonts.hindSiliguri(color: Colors.white54, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 2. Top 3 Podium Section ───────────────────────────────────────────────
  Widget _buildPodiumSection(List<_RankingItem> rankings) {
    final first = rankings.isNotEmpty ? rankings[0] : null;
    final second = rankings.length > 1 ? rankings[1] : null;
    final third = rankings.length > 2 ? rankings[2] : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.military_tech, color: Color(0xFFFFD700), size: 18),
              const SizedBox(width: 6),
              Text(
                'শীর্ষ ৩ মডারেটর (Top 3 Podium)',
                style: GoogleFonts.hindSiliguri(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 2nd Place (Silver)
              Expanded(
                child: _buildPodiumColumn(
                  item: second,
                  rank: 2,
                  medalColor: const Color(0xFFC0C0C0),
                  podiumHeight: 70,
                  badge: '🥈 ২য়',
                ),
              ),
              const SizedBox(width: 6),
              // 1st Place (Gold - Elevated)
              Expanded(
                child: _buildPodiumColumn(
                  item: first,
                  rank: 1,
                  medalColor: const Color(0xFFFFD700),
                  podiumHeight: 96,
                  badge: '🥇 ১ম (সেরা)',
                  isCenter: true,
                ),
              ),
              const SizedBox(width: 6),
              // 3rd Place (Bronze)
              Expanded(
                child: _buildPodiumColumn(
                  item: third,
                  rank: 3,
                  medalColor: const Color(0xFFCD7F32),
                  podiumHeight: 54,
                  badge: '🥉 ৩য়',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumColumn({
    required _RankingItem? item,
    required int rank,
    required Color medalColor,
    required double podiumHeight,
    required String badge,
    bool isCenter = false,
  }) {
    if (item == null || item.totalSale <= 0) {
      return Column(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withAlpha(10),
            ),
            child: const Icon(Icons.person_outline,
                color: Colors.white24, size: 20),
          ),
          const SizedBox(height: 6),
          Text('—',
              style: GoogleFonts.hindSiliguri(
                  color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 6),
          Container(
            height: podiumHeight,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text('$rank',
                  style: GoogleFonts.outfit(
                      color: Colors.white24,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ModeratorProfileScreen(
              moderatorId: item.id,
              moderatorName: item.name,
              moderatorEmail: item.email,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Column(
        children: [
          if (isCenter)
            const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700), size: 18),
          Container(
            width: isCenter ? 48 : 40,
            height: isCenter ? 48 : 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isCenter
                    ? [const Color(0xFFFFD700), const Color(0xFFD4AC0D)]
                    : [medalColor, medalColor.withAlpha(180)],
              ),
              boxShadow: [
                BoxShadow(
                  color: medalColor.withAlpha(70),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Center(
              child: Text(
                item.name.isNotEmpty ? item.name[0].toUpperCase() : 'M',
                style: GoogleFonts.outfit(
                  color: Colors.black,
                  fontSize: isCenter ? 20 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.name,
            style: GoogleFonts.hindSiliguri(
              color: Colors.white,
              fontSize: isCenter ? 12 : 11,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          Text(
            ProfileFormatUtils.formatMoney(item.totalSale),
            style: GoogleFonts.outfit(
              color: const Color(0xFF2ECC71),
              fontSize: isCenter ? 11 : 10,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${item.ratio.deliveryRate.toStringAsFixed(0)}% Deliv',
            style: GoogleFonts.outfit(
              color: Colors.white60,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 6),
          // Podium Base Block
          Container(
            height: podiumHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  medalColor.withAlpha(50),
                  medalColor.withAlpha(15),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              border: Border.all(color: medalColor.withAlpha(60)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  badge,
                  style: GoogleFonts.hindSiliguri(
                    color: medalColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  item.ratio.ratioString,
                  style: GoogleFonts.outfit(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 3. Full Ranking List Card ─────────────────────────────────────────────
  Widget _buildRankingCard(_RankingItem item, bool isSelf) {
    Color rankColor = Colors.white70;
    IconData? rankIcon;

    if (item.rank == 1) {
      rankColor = const Color(0xFFFFD700);
      rankIcon = Icons.emoji_events;
    } else if (item.rank == 2) {
      rankColor = const Color(0xFFC0C0C0);
      rankIcon = Icons.military_tech;
    } else if (item.rank == 3) {
      rankColor = const Color(0xFFCD7F32);
      rankIcon = Icons.military_tech;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelf
            ? const Color(0xFF2ECC71).withAlpha(15)
            : Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelf
              ? const Color(0xFF2ECC71).withAlpha(90)
              : Colors.white.withAlpha(18),
          width: isSelf ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ModeratorProfileScreen(
                  moderatorId: item.id,
                  moderatorName: item.name,
                  moderatorEmail: item.email,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Rank number / medal
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: rankColor.withAlpha(25),
                    shape: BoxShape.circle,
                    border: Border.all(color: rankColor.withAlpha(80)),
                  ),
                  child: Center(
                    child: rankIcon != null
                        ? Icon(rankIcon, color: rankColor, size: 18)
                        : Text(
                            '#${item.rank}',
                            style: GoogleFonts.outfit(
                              color: rankColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 10),

                // Moderator Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: GoogleFonts.hindSiliguri(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelf)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(left: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2ECC71).withAlpha(30),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'আপনি',
                                style: GoogleFonts.hindSiliguri(
                                  color: const Color(0xFF2ECC71),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            'সেল: ${ProfileFormatUtils.formatMoney(item.totalSale)}',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF2ECC71),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${item.reportsCount} দিন)',
                            style: GoogleFonts.hindSiliguri(
                              color: Colors.white38,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Mini Delivery vs Return Split Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: SizedBox(
                          height: 5,
                          child: item.ratio.totalHandled == 0
                              ? Container(color: Colors.white12)
                              : Row(
                                  children: [
                                    Expanded(
                                      flex: (item.ratio.deliveryRate * 10)
                                          .round()
                                          .clamp(1, 1000),
                                      child: Container(
                                          color: const Color(0xFF2ECC71)),
                                    ),
                                    if (item.ratio.returnRate > 0)
                                      Expanded(
                                        flex: (item.ratio.returnRate * 10)
                                            .round()
                                            .clamp(1, 1000),
                                        child: Container(
                                            color: const Color(0xFFE74C3C)),
                                      ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'রেশিও: ${item.ratio.ratioString}',
                            style: GoogleFonts.hindSiliguri(
                              color: Colors.white60,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            'ডেলিভারি: ${item.delivered}টি • রিটার্ন: ${item.returned}টি (${item.ratio.deliveryRate.toStringAsFixed(1)}%)',
                            style: GoogleFonts.hindSiliguri(
                              color: item.ratio.statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded,
                    color: Colors.white24, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Hall of Fame Bottom Sheet ─────────────────────────────────────────────
  void _showHallOfFameSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF132232),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (ctx, scrollCtrl) {
            return Column(
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.emoji_events_rounded,
                              color: Color(0xFFFFD700), size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'মাস সেরা তালিকা (সকল মাসের সেরা মডারেটর)',
                            style: GoogleFonts.hindSiliguri(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.white54, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white12),
                Expanded(
                  child: StreamBuilder<List<ModeratorOfMonth>>(
                    stream: _rankingService.getAllPastWinnersStream(),
                    builder: (ctx, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF2ECC71)),
                        );
                      }
                      final winners = snap.data ?? [];
                      if (winners.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.military_tech_outlined,
                                  color: Colors.white24, size: 48),
                              const SizedBox(height: 10),
                              Text(
                                'এখনো কোনো মাস সেরা মডারেটর রেকর্ড সংরক্ষিত হয়নি।',
                                style: GoogleFonts.hindSiliguri(
                                    color: Colors.white38),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.all(16),
                        itemCount: winners.length,
                        separatorBuilder: (_, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          final w = winners[i];
                          final monthDate = DateTime(w.year, w.month, 1);
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(8),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: const Color(0xFFFFD700).withAlpha(50)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFFD700),
                                        Color(0xFFD4AC0D)
                                      ],
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.emoji_events,
                                        color: Colors.black, size: 22),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ProfileFormatUtils.formatMonthYear(
                                            monthDate),
                                        style: GoogleFonts.hindSiliguri(
                                          color: const Color(0xFFFFD700),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        w.moderatorName,
                                        style: GoogleFonts.hindSiliguri(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'মোট সেল: ${ProfileFormatUtils.formatMoney(w.totalSale)} • ডেলিভারি রেট: ${w.deliveryRate.toStringAsFixed(1)}%',
                                        style: GoogleFonts.hindSiliguri(
                                          color: Colors.white60,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── Admin Crown / Confirm Dialog ──────────────────────────────────────────
  Future<void> _showCrownDialog({
    required String candidateId,
    required String candidateName,
    required String candidateEmail,
    required double totalSale,
    required int deliveryCount,
    required int returnCount,
    required double deliveryRate,
    String existingNote = '',
  }) async {
    final noteCtrl = TextEditingController(
        text: existingNote.isNotEmpty
            ? existingNote
            : 'মাস সেরা মডারেটর হিসেবে অ্যাডমিন কর্তৃক আনুষ্ঠানিকভাবে পুরস্কৃত!');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B2A3B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700)),
            const SizedBox(width: 8),
            Text(
              'মাস সেরা মডারেটর ঘোষণা',
              style: GoogleFonts.hindSiliguri(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'মাস: ${ProfileFormatUtils.formatMonthYear(_selectedMonth)}',
                style: GoogleFonts.hindSiliguri(
                    color: const Color(0xFFFFD700), fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'নির্বাচিত মডারেটর: $candidateName',
                style: GoogleFonts.hindSiliguri(
                    color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Text(
                'মোট সেল: ${ProfileFormatUtils.formatMoney(totalSale)} • সাকসেস: ${deliveryRate.toStringAsFixed(1)}%',
                style: GoogleFonts.hindSiliguri(
                    color: const Color(0xFF2ECC71), fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: noteCtrl,
                maxLines: 2,
                style: GoogleFonts.hindSiliguri(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'অ্যাওয়ার্ড নোট বা বার্তা',
                  labelStyle:
                      GoogleFonts.hindSiliguri(color: Colors.white54, fontSize: 12),
                  filled: true,
                  fillColor: Colors.white.withAlpha(10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.white.withAlpha(20)),
                  ),
                ),
              ),
            ],
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
                backgroundColor: const Color(0xFFF39C12)),
            child: Text('সংরক্ষণ করুন',
                style: GoogleFonts.hindSiliguri(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      final record = ModeratorOfMonth(
        id: RankingService.docIdFor(
            _selectedMonth.year, _selectedMonth.month),
        year: _selectedMonth.year,
        month: _selectedMonth.month,
        moderatorId: candidateId,
        moderatorName: candidateName,
        moderatorEmail: candidateEmail,
        totalSale: totalSale,
        deliveryCount: deliveryCount,
        returnCount: returnCount,
        deliveryRate: deliveryRate,
        crownedAt: DateTime.now(),
        note: noteCtrl.text.trim(),
      );

      await _rankingService.saveModeratorOfMonth(record);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          '🎉 $candidateName কে সফলভাবে মাস সেরা মডারেটর ঘোষণা ও সংরক্ষণ করা হয়েছে!',
          style: GoogleFonts.hindSiliguri(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF27AE60),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }
}

class _ModEntry {
  final String id;
  final String name;
  final String email;

  _ModEntry({required this.id, required this.name, required this.email});
}

class _RankingItem {
  final String id;
  final String name;
  final String email;
  final double totalSale;
  final int delivered;
  final int returned;
  final DeliveryRatioInfo ratio;
  final int reportsCount;
  int rank = 0;

  _RankingItem({
    required this.id,
    required this.name,
    required this.email,
    required this.totalSale,
    required this.delivered,
    required this.returned,
    required this.ratio,
    required this.reportsCount,
  });
}
