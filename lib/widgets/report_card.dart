import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/sale_report.dart';

class ReportCard extends StatelessWidget {
  final SaleReport report;
  final VoidCallback? onEdit; // null for moderator view, set for admin
  final VoidCallback? onApprove; // admin only
  final VoidCallback? onReject; // admin only

  const ReportCard({
    super.key,
    required this.report,
    this.onEdit,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _statusBorderColor().withAlpha(60)),
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
                      color: const Color(0xFF2ECC71).withAlpha(30),
                    ),
                    child: const Icon(Icons.person_outline,
                        color: Color(0xFF2ECC71), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.moderatorName,
                        style: GoogleFonts.hindSiliguri(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy  hh:mm a')
                            .format(report.createdAt),
                        style: GoogleFonts.outfit(
                            color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  // Status badge
                  _StatusBadge(
                    status: report.status,
                    isEditRequested: report.isEditRequested,
                    isDeliveredPending: report.isDeliveredPending,
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2ECC71).withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      DateFormat('dd MMM').format(report.date),
                      style: GoogleFonts.outfit(
                          color: const Color(0xFF2ECC71),
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (onEdit != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onEdit,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3498DB).withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.edit_outlined,
                            color: Color(0xFF3498DB), size: 16),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),
          // Data grid
          _twoCol(
            _item('বুকিং পার্সেল', '${report.parcel}টি', Icons.inventory_2_outlined,
                const Color(0xFF3498DB)),
            _item('বুকিং সেল', '৳${report.sale.toStringAsFixed(0)}',
                Icons.attach_money, const Color(0xFF2ECC71)),
          ),
          const SizedBox(height: 8),
          _twoCol(
            _item('বিকাশ', '৳${report.bkash.toStringAsFixed(0)}',
                Icons.phone_android, const Color(0xFFE91E8C)),
            _item('নগদ', '৳${report.nagad.toStringAsFixed(0)}',
                Icons.account_balance_wallet, const Color(0xFFFF6B35)),
          ),
          const SizedBox(height: 8),
          _twoCol(
            _item('রকেট', '৳${report.appCharge.toStringAsFixed(0)}',
                Icons.rocket_launch_outlined, const Color(0xFF9B59B6)),
            _item('রিটার্ন', '${report.returns}টি',
                Icons.assignment_return, const Color(0xFFE74C3C)),
          ),
          const SizedBox(height: 6),
          _totalDeliveryRow(report),
          if (report.totalParcel > 0 || report.totalSale > 0) ...[
            const SizedBox(height: 8),
            _twoCol(
              _item('ডেলিভার্ড পার্সেল', '${report.totalParcel}টি',
                  Icons.local_shipping_outlined, const Color(0xFF3498DB)),
              _item('ডেলিভার্ড সেল', '৳${report.totalSale.toStringAsFixed(0)}',
                  Icons.payments_outlined, const Color(0xFF2ECC71)),
            ),
          ],

          // Proof images (bkash / nagad / rocket)
          if (report.bkashImageUrl != null ||
              report.nagadImageUrl != null ||
              report.rocketImageUrl != null) ...[
            const SizedBox(height: 10),
            _ProofImagesRow(
              bkashUrl: report.bkashImageUrl,
              nagadUrl: report.nagadImageUrl,
              rocketUrl: report.rocketImageUrl,
              context: context,
            ),
          ],

          const SizedBox(height: 8),
          // Commission and Extra row
          if (report.commission > 0 || report.extraType != 'none')
            _twoCol(
              _item('কমিশন', '৳${report.commission.toStringAsFixed(0)}',
                  Icons.monetization_on_outlined, const Color(0xFF2ECC71)),
              report.extraType == 'bonus'
                  ? _item('বোনাস', '৳${report.extra.abs().toStringAsFixed(0)}',
                      Icons.star_outline, const Color(0xFFF1C40F))
                  : report.extraType == 'fine'
                      ? _item(
                          'জরিমানা',
                          '৳${report.extra.abs().toStringAsFixed(0)}',
                          Icons.warning_amber_outlined,
                          const Color(0xFFE74C3C))
                      : _item('কমিশন', '৳${report.commission.toStringAsFixed(0)}',
                          Icons.monetization_on_outlined, const Color(0xFF2ECC71)),
            )
          else
            _twoCol(
              _item('কমিশন', '৳${report.commission.toStringAsFixed(0)}',
                  Icons.monetization_on_outlined, const Color(0xFF2ECC71)),
              _item('এক্সট্রা', '—',
                  Icons.add_circle_outline, Colors.white24),
            ),
          if (report.extraType != 'none' && report.extraNote.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                children: [
                  Icon(Icons.notes_rounded,
                      size: 13,
                      color: report.extraType == 'bonus'
                          ? const Color(0xFFF1C40F)
                          : const Color(0xFFE74C3C)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'নোট: ${report.extraNote}',
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

          // Admin rejection note
          if (report.isRejected && report.adminNote.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
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

          // Admin approve/reject buttons
          if ((onApprove != null || onReject != null) && report.isPending) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                if (onReject != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close_rounded,
                          size: 16, color: Color(0xFFE74C3C)),
                      label: Text('প্রত্যাখ্যান',
                          style: GoogleFonts.hindSiliguri(
                              color: const Color(0xFFE74C3C),
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE74C3C)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                if (onApprove != null && onReject != null)
                  const SizedBox(width: 8),
                if (onApprove != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check_rounded,
                          size: 16, color: Colors.white),
                      label: Text('অনুমোদন',
                          style: GoogleFonts.hindSiliguri(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2ECC71),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
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

  Color _statusBorderColor() {
    if (report.isApproved) return const Color(0xFF2ECC71);
    if (report.isRejected) return const Color(0xFFE74C3C);
    return const Color(0xFFF39C12);
  }

  Widget _twoCol(Widget left, Widget right) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 8),
        Expanded(child: right),
      ],
    );
  }

  Widget _totalDeliveryRow(SaleReport report) {
    final total = report.totalDeliveryCharge;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('৳${total.toStringAsFixed(0)}',
              style: GoogleFonts.outfit(
                  color: const Color(0xFF2ECC71),
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ],
      ),
    );
  }

  Widget _item(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.hindSiliguri(
                        color: Colors.white54, fontSize: 10)),
                Text(value,
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  final bool isEditRequested;
  final bool isDeliveredPending;
  const _StatusBadge({
    required this.status,
    this.isEditRequested = false,
    this.isDeliveredPending = false,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;
    if (isDeliveredPending) {
      color = const Color(0xFF3498DB);
      label = 'ডেলিভারি অপেক্ষারত';
      icon = Icons.local_shipping_outlined;
    } else if (isEditRequested) {
      color = const Color(0xFFE67E22);
      label = 'সম্পাদনা অপেক্ষারত';
      icon = Icons.edit_note_rounded;
    } else {
      switch (status) {
        case 'approved':
          color = const Color(0xFF2ECC71);
          label = 'অনুমোদিত';
          icon = Icons.check_circle_outline;
          break;
        case 'rejected':
          color = const Color(0xFFE74C3C);
          label = 'প্রত্যাখ্যাত';
          icon = Icons.cancel_outlined;
          break;
        default:
          color = const Color(0xFFF39C12);
          label = 'অপেক্ষারত';
          icon = Icons.hourglass_top_rounded;
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(label,
              style: GoogleFonts.hindSiliguri(
                  color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ─── Proof Images Row ─────────────────────────────────────────────────────────

class _ProofImagesRow extends StatelessWidget {
  final String? bkashUrl;
  final String? nagadUrl;
  final String? rocketUrl;
  final BuildContext context;

  const _ProofImagesRow({
    this.bkashUrl,
    this.nagadUrl,
    this.rocketUrl,
    required this.context,
  });

  @override
  Widget build(BuildContext outerCtx) {
    final items = <_ProofItem>[];
    if (bkashUrl != null) {
      items.add(_ProofItem(label: 'বিকাশ', url: bkashUrl!, color: const Color(0xFFE91E8C)));
    }
    if (nagadUrl != null) {
      items.add(_ProofItem(label: 'নগদ', url: nagadUrl!, color: const Color(0xFFFF6B35)));
    }
    if (rocketUrl != null) {
      items.add(_ProofItem(label: 'রকেট', url: rocketUrl!, color: const Color(0xFF9B59B6)));
    }
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('📎 ডেলিভারি চার্জের প্রমাণ',
            style: GoogleFonts.hindSiliguri(
                color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Row(
          children: items
              .map((item) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => _showFullImage(outerCtx, item),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item.url,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              loadingBuilder: (_, child, prog) {
                                if (prog == null) return child;
                                return Container(
                                  width: 72,
                                  height: 72,
                                  color: Colors.white10,
                                  child: const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF2ECC71)),
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (ctx2, e, st) => Container(
                                width: 72,
                                height: 72,
                                color: Colors.white10,
                                child: const Icon(Icons.broken_image_outlined,
                                    color: Colors.white38, size: 28),
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(item.label,
                              style: GoogleFonts.hindSiliguri(
                                  color: item.color, fontSize: 10)),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  void _showFullImage(BuildContext ctx, _ProofItem item) {
    showDialog(
      context: ctx,
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
                  Text('${item.label} — প্রমাণ',
                      style: GoogleFonts.hindSiliguri(
                          color: item.color,
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
                item.url,
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

class _ProofItem {
  final String label;
  final String url;
  final Color color;
  const _ProofItem({required this.label, required this.url, required this.color});
}
