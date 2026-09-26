import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/sale_report.dart';

class ReportCard extends StatelessWidget {
  final SaleReport report;
  final VoidCallback? onEdit; // null for moderator view, set for admin

  const ReportCard({super.key, required this.report, this.onEdit});

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
            _item('পার্সেল', '${report.parcel}টি', Icons.inventory_2_outlined,
                const Color(0xFF3498DB)),
            _item('সেল', '৳${report.sale.toStringAsFixed(0)}',
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
        ],
      ),
    );
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


