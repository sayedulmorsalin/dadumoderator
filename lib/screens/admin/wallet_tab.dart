import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/wallet.dart';
import '../../models/payout_request.dart';
import '../../providers/wallet_provider.dart';
import '../profile/moderator_profile_view.dart';

class WalletTab extends StatefulWidget {
  const WalletTab({super.key});

  @override
  State<WalletTab> createState() => _WalletTabState();
}

class _WalletTabState extends State<WalletTab>
    with SingleTickerProviderStateMixin {
  late TabController _innerTab;

  @override
  void initState() {
    super.initState();
    _innerTab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _innerTab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _innerTab,
          indicatorColor: const Color(0xFF2ECC71),
          indicatorWeight: 3,
          labelColor: const Color(0xFF2ECC71),
          unselectedLabelColor: Colors.white38,
          labelStyle:
              GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'ওয়ালেট', icon: Icon(Icons.account_balance_wallet, size: 18)),
            Tab(text: 'পেআউট রিকোয়েস্ট', icon: Icon(Icons.payments_outlined, size: 18)),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _innerTab,
            children: const [
              _AllWalletsView(),
              _AllPayoutRequestsView(),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── All Wallets ──────────────────────────────────────────────────────────────

class _AllWalletsView extends StatelessWidget {
  const _AllWalletsView();

  @override
  Widget build(BuildContext context) {
    final wp = context.watch<WalletProvider>();
    return StreamBuilder<List<Wallet>>(
      stream: wp.getAllWallets(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2ECC71)));
        }
        final wallets = snap.data ?? [];
        if (wallets.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_balance_wallet_outlined,
                    color: Colors.white24, size: 64),
                const SizedBox(height: 12),
                Text('এখনো কোনো ওয়ালেট নেই।',
                    style: GoogleFonts.hindSiliguri(color: Colors.white38)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: wallets.length,
          itemBuilder: (_, i) => _WalletCard(wallet: wallets[i]),
        );
      },
    );
  }
}

class _WalletCard extends StatelessWidget {
  final Wallet wallet;

  const _WalletCard({required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A3A2A).withAlpha(200),
            const Color(0xFF0D2A1A).withAlpha(200),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2ECC71).withAlpha(40)),
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
                  shape: BoxShape.circle,
                  color: const Color(0xFF2ECC71).withAlpha(30),
                ),
                child: const Icon(Icons.person_outline,
                    color: Color(0xFF2ECC71), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(wallet.moderatorName,
                        style: GoogleFonts.hindSiliguri(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    Text(
                      'সর্বশেষ আপডেট: ${DateFormat('dd MMM yyyy').format(wallet.lastUpdated)}',
                      style: GoogleFonts.outfit(
                          color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '৳ ${wallet.balance.toStringAsFixed(2)}',
                    style: GoogleFonts.outfit(
                        color: const Color(0xFF2ECC71),
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  ),
                  Text('ব্যালেন্স',
                      style: GoogleFonts.hindSiliguri(
                          color: Colors.white38, fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _miniStat('মোট আয়',
                  '৳${wallet.totalEarned.toStringAsFixed(0)}',
                  const Color(0xFF2ECC71)),
              const SizedBox(width: 10),
              _miniStat('মোট উত্তোলন',
                  '৳${wallet.totalWithdrawn.toStringAsFixed(0)}',
                  const Color(0xFFFF6B35)),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ModeratorProfileScreen(
                      moderatorId: wallet.moderatorId,
                      moderatorName: wallet.moderatorName,
                      moderatorEmail: '',
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('প্রোফাইল ও মাইলস্টোন দেখুন',
                        style: GoogleFonts.hindSiliguri(
                            color: const Color(0xFF3498DB),
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: Color(0xFF3498DB), size: 10),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.hindSiliguri(
                    color: Colors.white54, fontSize: 10)),
            Text(value,
                style: GoogleFonts.outfit(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ─── All Payout Requests ──────────────────────────────────────────────────────

class _AllPayoutRequestsView extends StatelessWidget {
  const _AllPayoutRequestsView();

  @override
  Widget build(BuildContext context) {
    final wp = context.watch<WalletProvider>();
    return StreamBuilder<List<PayoutRequest>>(
      stream: wp.getAllPayoutRequests(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2ECC71)));
        }
        final requests = snap.data ?? [];
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.payments_outlined,
                    color: Colors.white24, size: 64),
                const SizedBox(height: 12),
                Text('কোনো পেআউট রিকোয়েস্ট নেই।',
                    style: GoogleFonts.hindSiliguri(color: Colors.white38)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (_, i) =>
              _AdminPayoutCard(req: requests[i], wp: wp),
        );
      },
    );
  }
}

class _AdminPayoutCard extends StatelessWidget {
  final PayoutRequest req;
  final WalletProvider wp;

  const _AdminPayoutCard({required this.req, required this.wp});

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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF3498DB).withAlpha(30),
                    ),
                    child: const Icon(Icons.person_outline,
                        color: Color(0xFF3498DB), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(req.moderatorName,
                          style: GoogleFonts.hindSiliguri(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      Text(
                        DateFormat('dd MMM yyyy  hh:mm a')
                            .format(req.requestedAt),
                        style: GoogleFonts.outfit(
                            color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 13),
                    const SizedBox(width: 4),
                    Text(statusLabel,
                        style: GoogleFonts.hindSiliguri(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Amount
          Row(
            children: [
              const Icon(Icons.monetization_on_outlined,
                  color: Color(0xFFF39C12), size: 16),
              const SizedBox(width: 6),
              Text('৳${req.amount.toStringAsFixed(2)}',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ],
          ),
          if (req.note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(req.note,
                style: GoogleFonts.hindSiliguri(
                    color: Colors.white54, fontSize: 12)),
          ],
          // Action buttons for pending requests
          if (req.isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _resolveDialog(context, req, true),
                    icon: const Icon(Icons.check_rounded,
                        size: 16, color: Colors.white),
                    label: Text('অনুমোদন',
                        style: GoogleFonts.hindSiliguri(
                            fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF27AE60),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _resolveDialog(context, req, false),
                    icon: const Icon(Icons.close_rounded,
                        size: 16, color: Color(0xFFE74C3C)),
                    label: Text('প্রত্যাখ্যান',
                        style: GoogleFonts.hindSiliguri(
                            color: const Color(0xFFE74C3C),
                            fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE74C3C)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
          // Show resolve info
          if (!req.isPending && req.resolvedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              '${req.isApproved ? '✅ অনুমোদিত' : '❌ প্রত্যাখ্যাত'}: ${DateFormat('dd MMM yyyy').format(req.resolvedAt!)}',
              style: GoogleFonts.hindSiliguri(
                  color: Colors.white38, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _resolveDialog(
      BuildContext context, PayoutRequest req, bool approve) async {
    final noteCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B2A3B),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          approve ? 'পেআউট অনুমোদন' : 'পেআউট প্রত্যাখ্যান',
          style: GoogleFonts.hindSiliguri(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${req.moderatorName} — ৳${req.amount.toStringAsFixed(2)}',
              style: GoogleFonts.outfit(
                  color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              style: GoogleFonts.hindSiliguri(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'নোট (ঐচ্ছিক)',
                labelStyle:
                    GoogleFonts.hindSiliguri(color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withAlpha(8),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: Colors.white.withAlpha(25))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: Colors.white.withAlpha(25))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF2ECC71))),
              ),
            ),
          ],
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
              backgroundColor: approve
                  ? const Color(0xFF27AE60)
                  : const Color(0xFFE74C3C),
            ),
            child: Text(
              approve ? 'অনুমোদন করুন' : 'প্রত্যাখ্যান করুন',
              style: GoogleFonts.hindSiliguri(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final ok = await wp.resolvePayoutRequest(req, approve, noteCtrl.text);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (approve
                  ? '✅ পেআউট অনুমোদিত হয়েছে!'
                  : '❌ পেআউট প্রত্যাখ্যাত হয়েছে।')
              : wp.error ?? 'ত্রুটি হয়েছে।',
          style: GoogleFonts.hindSiliguri(color: Colors.white),
        ),
        backgroundColor:
            ok ? const Color(0xFF27AE60) : const Color(0xFFE74C3C),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
