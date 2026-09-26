import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Milestone definition: 2 Lakhs, 5 Lakhs, 10 Lakhs
class MilestoneTier {
  final int level;
  final double target;
  final String title;
  final String targetBn;
  final String badgeName;
  final IconData icon;
  final Color color;
  final Color gradientStart;
  final Color gradientEnd;

  const MilestoneTier({
    required this.level,
    required this.target,
    required this.title,
    required this.targetBn,
    required this.badgeName,
    required this.icon,
    required this.color,
    required this.gradientStart,
    required this.gradientEnd,
  });

  bool isAchieved(double currentSale) => currentSale >= target;

  double progress(double currentSale) {
    if (target <= 0) return 0.0;
    return (currentSale / target).clamp(0.0, 1.0);
  }

  double remaining(double currentSale) {
    if (currentSale >= target) return 0.0;
    return target - currentSale;
  }
}

class MilestoneConstants {
  static const double milestone1 = 200000;  // 2 Lakhs (200,000)
  static const double milestone2 = 500000;  // 5 Lakhs (500,000)
  static const double milestone3 = 1000000; // 10 Lakhs (1,000,000)

  static const List<MilestoneTier> tiers = [
    MilestoneTier(
      level: 1,
      target: milestone1,
      title: 'মাইলস্টোন ১',
      targetBn: '২ লাখ',
      badgeName: 'ব্রোঞ্জ এচিভার',
      icon: Icons.military_tech_rounded,
      color: Color(0xFFE67E22),
      gradientStart: Color(0xFFD35400),
      gradientEnd: Color(0xFFE67E22),
    ),
    MilestoneTier(
      level: 2,
      target: milestone2,
      title: 'মাইলস্টোন ২',
      targetBn: '৫ লাখ',
      badgeName: 'সিলভার স্টার',
      icon: Icons.workspace_premium_rounded,
      color: Color(0xFF3498DB),
      gradientStart: Color(0xFF2980B9),
      gradientEnd: Color(0xFF3498DB),
    ),
    MilestoneTier(
      level: 3,
      target: milestone3,
      title: 'মাইলস্টোন ৩',
      targetBn: '১০ লাখ',
      badgeName: 'গোল্ড চ্যাম্পিয়ন',
      icon: Icons.emoji_events_rounded,
      color: Color(0xFFFFD700),
      gradientStart: Color(0xFFF39C12),
      gradientEnd: Color(0xFFFFD700),
    ),
  ];

  static int getHighestAchievedLevel(double currentSale) {
    if (currentSale >= milestone3) return 3;
    if (currentSale >= milestone2) return 2;
    if (currentSale >= milestone1) return 1;
    return 0;
  }

  static MilestoneTier? getNextMilestone(double currentSale) {
    for (final tier in tiers) {
      if (!tier.isAchieved(currentSale)) {
        return tier;
      }
    }
    return null; // All achieved
  }
}

/// Helper model for Delivery vs Return metrics
class DeliveryRatioInfo {
  final int delivered;
  final int returned;

  const DeliveryRatioInfo({
    required this.delivered,
    required this.returned,
  });

  int get totalHandled => delivered + returned;

  double get deliveryRate =>
      totalHandled > 0 ? (delivered / totalHandled) * 100 : 0.0;

  double get returnRate =>
      totalHandled > 0 ? (returned / totalHandled) * 100 : 0.0;

  String get ratioString {
    if (totalHandled == 0) return '০ : ০';
    if (returned == 0) return '$delivered : ০';
    final ratio = delivered / returned;
    return '${ratio.toStringAsFixed(1)} : ১';
  }

  String get statusTitle {
    if (totalHandled == 0) return 'কোনো অর্ডার নেই';
    if (deliveryRate >= 92) return 'অসাধারণ ডেলিভারি রেশিও';
    if (deliveryRate >= 85) return 'চমৎকার ডেলিভারি পারফর্ম্যান্স';
    if (deliveryRate >= 75) return 'সন্তোষজনক অনুপাত';
    return 'রিটার্ন কমানোর চেষ্টা করুন';
  }

  Color get statusColor {
    if (totalHandled == 0) return Colors.white38;
    if (deliveryRate >= 90) return const Color(0xFF2ECC71);
    if (deliveryRate >= 80) return const Color(0xFF3498DB);
    if (deliveryRate >= 70) return const Color(0xFFF1C40F);
    return const Color(0xFFE74C3C);
  }
}

/// Currency & Bangla formatting utilities
class ProfileFormatUtils {
  static const List<String> bnMonths = [
    'জানুয়ারি',
    'ফেব্রুয়ারি',
    'মার্চ',
    'এপ্রিল',
    'মে',
    'জুন',
    'জুলাই',
    'আগস্ট',
    'সেপ্টেম্বর',
    'অক্টোবর',
    'নভেম্বর',
    'ডিসেম্বর'
  ];

  static String formatMonthYear(DateTime dt) {
    final monthName = bnMonths[dt.month - 1];
    return '$monthName ${dt.year}';
  }

  static String formatMoney(double amount) {
    try {
      final formatter = NumberFormat('#,##,##0', 'en_IN');
      return '৳${formatter.format(amount.round())}';
    } catch (_) {
      return '৳${amount.toStringAsFixed(0)}';
    }
  }

  static String toBnNumber(String input) {
    const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    var output = input;
    for (int i = 0; i < en.length; i++) {
      output = output.replaceAll(en[i], bn[i]);
    }
    return output;
  }
}
