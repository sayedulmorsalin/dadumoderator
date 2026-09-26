import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/app_user.dart';
import '../../models/sale_report.dart';
import '../../models/moderator_of_month.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import '../../services/ranking_service.dart';
import '../../utils/moderator_profile_utils.dart';

/// Full screen wrapper used when navigating from Admin view
class ModeratorProfileScreen extends StatelessWidget {
  final String moderatorId;
  final String moderatorName;
  final String moderatorEmail;

  const ModeratorProfileScreen({
    super.key,
    required this.moderatorId,
    required this.moderatorName,
    required this.moderatorEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '$moderatorName - প্রোফাইল',
          style: GoogleFonts.hindSiliguri(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: ModeratorProfileView(
        moderatorId: moderatorId,
        moderatorName: moderatorName,
        moderatorEmail: moderatorEmail,
        isSelfView: false,
      ),
    );
  }
}

/// Core profile widget usable both in Moderator Tab and Admin screens
class ModeratorProfileView extends StatefulWidget {
  final String moderatorId;
  final String moderatorName;
  final String moderatorEmail;
  final bool isSelfView;

  const ModeratorProfileView({
    super.key,
    required this.moderatorId,
    required this.moderatorName,
    required this.moderatorEmail,
    this.isSelfView = false,
  });

  @override
  State<ModeratorProfileView> createState() => _ModeratorProfileViewState();
}

class _ModeratorProfileViewState extends State<ModeratorProfileView> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
  }

  void _prevMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    // Don't navigate into far future
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
    final rp = context.read<ReportProvider>();
    final auth = context.watch<AuthProvider>();

    return StreamBuilder<AppUser?>(
      stream: auth.getUserStream(widget.moderatorId),
      builder: (ctx, userSnap) {
        final liveName = userSnap.data?.name.isNotEmpty == true
            ? userSnap.data!.name
            : widget.moderatorName;
        final liveEmail = userSnap.data?.email.isNotEmpty == true
            ? userSnap.data!.email
            : widget.moderatorEmail;

        return StreamBuilder<List<SaleReport>>(
          stream: rp.getModeratorReports(widget.moderatorId),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF2ECC71)),
              );
            }

            final allReports = snap.data ?? [];
            final monthlyReports = allReports.where((r) =>
                r.date.year == _selectedMonth.year &&
                r.date.month == _selectedMonth.month).toList();

            // Monthly Aggregations
            final monthlySale =
                monthlyReports.fold<double>(0, (sum, r) => sum + r.sale);
            final monthlyParcel =
                monthlyReports.fold<int>(0, (sum, r) => sum + r.parcel);
            final monthlyReturn =
                monthlyReports.fold<int>(0, (sum, r) => sum + r.returns);
            final monthlyCommission =
                monthlyReports.fold<double>(0, (sum, r) => sum + r.commission);
            final monthlyBkash =
                monthlyReports.fold<double>(0, (sum, r) => sum + r.bkash);
            final monthlyNagad =
                monthlyReports.fold<double>(0, (sum, r) => sum + r.nagad);
            final monthlyApp =
                monthlyReports.fold<double>(0, (sum, r) => sum + r.appCharge);

            final ratioInfo = DeliveryRatioInfo(
              delivered: monthlyParcel,
              returned: monthlyReturn,
            );

            // All-Time Aggregations
            final allTimeSale =
                allReports.fold<double>(0, (sum, r) => sum + r.sale);
            final allTimeParcel =
                allReports.fold<int>(0, (sum, r) => sum + r.parcel);
            final allTimeReturn =
                allReports.fold<int>(0, (sum, r) => sum + r.returns);

            return StreamBuilder<ModeratorOfMonth?>(
              stream: RankingService().getModeratorOfMonthStream(
                  _selectedMonth.year, _selectedMonth.month),
              builder: (ctx, winnerSnap) {
                final isWinner =
                    winnerSnap.data?.moderatorId == widget.moderatorId;

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Moderator Profile Header
                      _buildHeaderCard(context, liveName, liveEmail, monthlySale,
                          isMonthWinner: isWinner),
                      const SizedBox(height: 16),

                      // Winner Announcement Banner
                      if (isWinner) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2D2305), Color(0xFF1B1B0A)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFFFFD700).withAlpha(120)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.emoji_events,
                                  color: Color(0xFFFFD700), size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '🏆 অভিনন্দন! এই মডারেটর ${ProfileFormatUtils.formatMonthYear(_selectedMonth)}-এর সেরা মডারেটর হিসেবে নির্বাচিত!',
                                  style: GoogleFonts.hindSiliguri(
                                    color: const Color(0xFFFFD700),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 2. Month Selector
                      _buildMonthSelector(),
                      const SizedBox(height: 16),

                      // 3. Total Monthly Sell Card
                      _buildTotalMonthlySellCard(monthlySale),
                      const SizedBox(height: 16),

                  // 4. Three Milestones Section
                  _buildMilestonesSection(monthlySale),
                  const SizedBox(height: 20),

                  // 5. Delivery vs Return Ratio Card
                  _buildDeliveryVsReturnCard(ratioInfo),
                  const SizedBox(height: 20),

                  // 6. Additional Monthly Stats
                  _buildMonthlySummaryGrid(
                    commission: monthlyCommission,
                    bkash: monthlyBkash,
                    nagad: monthlyNagad,
                    app: monthlyApp,
                    reportCount: monthlyReports.length,
                  ),
                  const SizedBox(height: 20),

                  // 7. All-Time Lifetime Performance Summary
                  _buildAllTimeSummaryCard(
                    allTimeSale: allTimeSale,
                    allTimeParcel: allTimeParcel,
                    allTimeReturn: allTimeReturn,
                    totalReports: allReports.length,
                  ),
                  const SizedBox(height: 24),

                  // 8. Daily Breakdown of the selected month
                  _buildDailyReportsSection(monthlyReports),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  },
);
  }

  // ─── 1. Header Card ────────────────────────────────────────────────────────
  Widget _buildHeaderCard(
      BuildContext context, String name, String email, double currentSale,
      {bool isMonthWinner = false}) {
    final highestLevel = MilestoneConstants.getHighestAchievedLevel(currentSale);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B2A3B), Color(0xFF132232)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withAlpha(25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2ECC71).withAlpha(80),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'M',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: GoogleFonts.hindSiliguri(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.isSelfView)
                      GestureDetector(
                        onTap: () => _showEditNameDialog(context),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2ECC71).withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.edit_outlined,
                              size: 14, color: Color(0xFF2ECC71)),
                        ),
                      ),
                  ],
                ),
                Text(
                  email,
                  style: GoogleFonts.outfit(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2ECC71).withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF2ECC71).withAlpha(70)),
                      ),
                      child: Text(
                        'মডারেটর',
                        style: GoogleFonts.hindSiliguri(
                          color: const Color(0xFF2ECC71),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isMonthWinner)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFD4AC0D)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withAlpha(60),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.emoji_events, size: 12, color: Colors.black),
                            const SizedBox(width: 3),
                            Text(
                              'মাস সেরা 🏆',
                              style: GoogleFonts.hindSiliguri(
                                color: Colors.black,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (highestLevel > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: MilestoneConstants.tiers[highestLevel - 1].color.withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: MilestoneConstants.tiers[highestLevel - 1].color.withAlpha(90),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              MilestoneConstants.tiers[highestLevel - 1].icon,
                              size: 12,
                              color: MilestoneConstants.tiers[highestLevel - 1].color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              MilestoneConstants.tiers[highestLevel - 1].badgeName,
                              style: GoogleFonts.hindSiliguri(
                                color: MilestoneConstants.tiers[highestLevel - 1].color,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 2. Month Selector ─────────────────────────────────────────────────────
  Widget _buildMonthSelector() {
    final now = DateTime.now();
    final isCurrentMonth = _selectedMonth.year == now.year && _selectedMonth.month == now.month;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: Colors.white70, size: 24),
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
                  const Icon(Icons.calendar_month_outlined, color: Color(0xFF2ECC71), size: 17),
                  const SizedBox(width: 8),
                  Text(
                    ProfileFormatUtils.formatMonthYear(_selectedMonth),
                    style: GoogleFonts.hindSiliguri(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 18),
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
                  size: 24,
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

  // ─── 3. Total Monthly Sell Card ────────────────────────────────────────────
  Widget _buildTotalMonthlySellCard(double monthlySale) {
    final highestLevel = MilestoneConstants.getHighestAchievedLevel(monthlySale);
    final nextMilestone = MilestoneConstants.getNextMilestone(monthlySale);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E3A5F).withAlpha(220),
            const Color(0xFF0F2038).withAlpha(240),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3498DB).withAlpha(60)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A5F).withAlpha(60),
            blurRadius: 12,
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3498DB).withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.trending_up_rounded,
                        color: Color(0xFF3498DB), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'মাসের মোট সেল',
                    style: GoogleFonts.hindSiliguri(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  DateFormat('MMMM yyyy').format(_selectedMonth),
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              ProfileFormatUtils.formatMoney(monthlySale),
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),
          // Milestone summary indicator
          if (highestLevel == 3) ...[
            Row(
              children: [
                const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'অভিনন্দন! সব মাইলস্টোন অর্জিত হয়েছে (১০ লাখ+ সেল)! 🎉',
                    style: GoogleFonts.hindSiliguri(
                      color: const Color(0xFFFFD700),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (nextMilestone != null) ...[
            Row(
              children: [
                Icon(nextMilestone.icon, color: nextMilestone.color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'পরবর্তী লক্ষ্য: ${nextMilestone.title} (${nextMilestone.targetBn}) • আর বাকি ${ProfileFormatUtils.formatMoney(nextMilestone.remaining(monthlySale))}',
                    style: GoogleFonts.hindSiliguri(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── 4. Three Milestones Section ───────────────────────────────────────────
  Widget _buildMilestonesSection(double monthlySale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.flag_rounded, color: Color(0xFFF1C40F), size: 20),
                const SizedBox(width: 8),
                Text(
                  'সেল মাইলস্টোন (৩টি পর্যায়)',
                  style: GoogleFonts.hindSiliguri(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF1C40F).withAlpha(25),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '২ লাখ • ৫ লাখ • ১০ লাখ',
                style: GoogleFonts.hindSiliguri(
                  color: const Color(0xFFF1C40F),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Milestone cards
        ...MilestoneConstants.tiers.map((tier) {
          return _buildMilestoneCard(tier, monthlySale);
        }),
      ],
    );
  }

  Widget _buildMilestoneCard(MilestoneTier tier, double currentSale) {
    final isAchieved = tier.isAchieved(currentSale);
    final progress = tier.progress(currentSale);
    final remaining = tier.remaining(currentSale);
    final percent = (progress * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAchieved
            ? tier.color.withAlpha(20)
            : Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAchieved
              ? tier.color.withAlpha(90)
              : Colors.white.withAlpha(20),
          width: isAchieved ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isAchieved
                        ? [tier.gradientStart, tier.gradientEnd]
                        : [Colors.white24, Colors.white12],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isAchieved
                      ? [
                          BoxShadow(
                            color: tier.color.withAlpha(70),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Icon(
                  tier.icon,
                  color: isAchieved ? Colors.white : Colors.white38,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${tier.title} (${tier.targetBn})',
                          style: GoogleFonts.hindSiliguri(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isAchieved)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2ECC71).withAlpha(35),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle, color: Color(0xFF2ECC71), size: 11),
                                const SizedBox(width: 3),
                                Text(
                                  'অর্জিত',
                                  style: GoogleFonts.hindSiliguri(
                                    color: const Color(0xFF2ECC71),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    Text(
                      'টার্গেট: ${ProfileFormatUtils.formatMoney(tier.target)} • ${tier.badgeName}',
                      style: GoogleFonts.hindSiliguri(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Percentage Text
              Text(
                '$percent%',
                style: GoogleFonts.outfit(
                  color: isAchieved ? tier.color : Colors.white54,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withAlpha(20),
              valueColor: AlwaysStoppedAnimation<Color>(
                isAchieved ? const Color(0xFF2ECC71) : tier.color,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'বর্তমান: ${ProfileFormatUtils.formatMoney(currentSale)}',
                style: GoogleFonts.outfit(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
              Text(
                isAchieved
                    ? '🎉 লক্ষ্য সম্পন্ন!'
                    : 'আর বাকি: ${ProfileFormatUtils.formatMoney(remaining)}',
                style: GoogleFonts.hindSiliguri(
                  color: isAchieved ? const Color(0xFF2ECC71) : Colors.white70,
                  fontSize: 11,
                  fontWeight: isAchieved ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 5. Delivery vs Return Ratio Card ──────────────────────────────────────
  Widget _buildDeliveryVsReturnCard(DeliveryRatioInfo ratioInfo) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withAlpha(25)),
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
                      color: const Color(0xFF2ECC71).withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.sync_alt_rounded,
                        color: Color(0xFF2ECC71), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'ডেলিভারি বনাম রিটার্ন রেশিও',
                    style: GoogleFonts.hindSiliguri(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ratioInfo.statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ratioInfo.statusColor.withAlpha(70)),
                ),
                child: Text(
                  ratioInfo.statusTitle,
                  style: GoogleFonts.hindSiliguri(
                    color: ratioInfo.statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Ratio Big Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1B2A3B).withAlpha(200),
                  const Color(0xFF0F1E2E).withAlpha(200),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'অনুপাত (Delivery : Return)',
                        style: GoogleFonts.hindSiliguri(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ratioInfo.ratioString,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.white12),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ডেলিভারি সাকসেস রেট',
                        style: GoogleFonts.hindSiliguri(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${ratioInfo.deliveryRate.toStringAsFixed(1)}%',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2ECC71),
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Visual Segmented Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: ratioInfo.totalHandled == 0
                  ? Container(color: Colors.white12)
                  : Row(
                      children: [
                        Expanded(
                          flex: (ratioInfo.deliveryRate * 10).round().clamp(1, 1000),
                          child: Container(color: const Color(0xFF2ECC71)),
                        ),
                        if (ratioInfo.returnRate > 0)
                          Expanded(
                            flex: (ratioInfo.returnRate * 10).round().clamp(1, 1000),
                            child: Container(color: const Color(0xFFE74C3C)),
                          ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 14),

          // 3 Column details: Delivered, Returned, Total
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'ডেলিভারি',
                  value: '${ratioInfo.delivered} টি',
                  subtext: '${ratioInfo.deliveryRate.toStringAsFixed(1)}%',
                  icon: Icons.local_shipping_outlined,
                  color: const Color(0xFF2ECC71),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'রিটার্ন',
                  value: '${ratioInfo.returned} টি',
                  subtext: '${ratioInfo.returnRate.toStringAsFixed(1)}%',
                  icon: Icons.assignment_return_outlined,
                  color: const Color(0xFFE74C3C),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'মোট হ্যান্ডেল্ড',
                  value: '${ratioInfo.totalHandled} টি',
                  subtext: '১০০%',
                  icon: Icons.inventory_2_outlined,
                  color: const Color(0xFF3498DB),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.hindSiliguri(
                  color: Colors.white60,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtext,
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── 6. Additional Monthly Stats ───────────────────────────────────────────
  Widget _buildMonthlySummaryGrid({
    required double commission,
    required double bkash,
    required double nagad,
    required double app,
    required int reportCount,
  }) {
    final totalDeliveryCharge = bkash + nagad + app;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'মাসের আয় ও ডেলিভারি চার্জ সংক্ষেপ ($reportCount দিন রিপোর্ট)',
            style: GoogleFonts.hindSiliguri(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSmallStatCard(
                  label: 'মোট কমিশন',
                  value: ProfileFormatUtils.formatMoney(commission),
                  icon: Icons.monetization_on_outlined,
                  color: const Color(0xFF2ECC71),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSmallStatCard(
                  label: 'ডেলিভারি চার্জ',
                  value: ProfileFormatUtils.formatMoney(totalDeliveryCharge),
                  icon: Icons.local_shipping_outlined,
                  color: const Color(0xFF3498DB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSmallStatCard(
                  label: 'বিকাশ',
                  value: ProfileFormatUtils.formatMoney(bkash),
                  icon: Icons.phone_android,
                  color: const Color(0xFFE91E8C),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSmallStatCard(
                  label: 'নগদ',
                  value: ProfileFormatUtils.formatMoney(nagad),
                  icon: Icons.account_balance_wallet,
                  color: const Color(0xFFFF6B35),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSmallStatCard(
                  label: 'রকেট',
                  value: ProfileFormatUtils.formatMoney(app),
                  icon: Icons.rocket_launch_outlined,
                  color: const Color(0xFF9B59B6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.hindSiliguri(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 7. All-Time Summary Card ──────────────────────────────────────────────
  Widget _buildAllTimeSummaryCard({
    required double allTimeSale,
    required int allTimeParcel,
    required int allTimeReturn,
    required int totalReports,
  }) {
    final allTimeRatio = DeliveryRatioInfo(
      delivered: allTimeParcel,
      returned: allTimeReturn,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A2634).withAlpha(200),
            const Color(0xFF131D28).withAlpha(200),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded, color: Color(0xFF3498DB), size: 18),
              const SizedBox(width: 8),
              Text(
                'সর্বমোট লাইফটাইম পারফর্ম্যান্স ($totalReports টি রিপোর্ট)',
                style: GoogleFonts.hindSiliguri(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('সর্বমোট সেল',
                        style: GoogleFonts.hindSiliguri(color: Colors.white54, fontSize: 11)),
                    Text(
                      ProfileFormatUtils.formatMoney(allTimeSale),
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('লাইফটাইম রেশিও',
                        style: GoogleFonts.hindSiliguri(color: Colors.white54, fontSize: 11)),
                    Text(
                      '${allTimeRatio.deliveryRate.toStringAsFixed(1)}% সাকসেস',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2ECC71),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '($allTimeParcel ডেলিভারি / $allTimeReturn রিটার্ন)',
                      style: GoogleFonts.hindSiliguri(color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 8. Daily Reports Section ──────────────────────────────────────────────
  Widget _buildDailyReportsSection(List<SaleReport> monthlyReports) {
    if (monthlyReports.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            const Icon(Icons.calendar_today_outlined, color: Colors.white24, size: 40),
            const SizedBox(height: 8),
            Text(
              'এই মাসে কোনো সেল রিপোর্ট পাওয়া যায়নি।',
              style: GoogleFonts.hindSiliguri(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'এই মাসের দৈনিক বিবরণী (${monthlyReports.length} দিন)',
          style: GoogleFonts.hindSiliguri(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: monthlyReports.length,
          separatorBuilder: (ctx, i) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final r = monthlyReports[i];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withAlpha(15)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2ECC71).withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      DateFormat('dd MMM').format(r.date),
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2ECC71),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'সেল: ${ProfileFormatUtils.formatMoney(r.sale)}',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'পার্সেল: ${r.parcel}টি • রিটার্ন: ${r.returns}টি',
                          style: GoogleFonts.hindSiliguri(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'কমিশন: ৳${r.commission.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2ECC71),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'ডেলিভারি চার্জ: ৳${r.totalDeliveryCharge.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ─── Edit Name Dialog ──────────────────────────────────────────────────────
  Future<void> _showEditNameDialog(BuildContext context) async {
    final auth = context.read<AuthProvider>();
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
      final success = await auth.updateName(nameCtrl.text.trim());
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          success ? '✅ নাম আপডেট হয়েছে!' : 'নাম আপডেট ব্যর্থ হয়েছে।',
          style: GoogleFonts.hindSiliguri(color: Colors.white),
        ),
        backgroundColor: success ? const Color(0xFF27AE60) : const Color(0xFFE74C3C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }
}
