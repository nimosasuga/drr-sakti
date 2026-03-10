// lib/models/dashboard_stats.dart
import 'dart:developer';

class DashboardStats {
  // Current Month Stats
  int currentMonthTroubleshooting;
  int currentMonthPreventive;

  // Previous Month Stats
  int previousMonthTroubleshooting;
  int previousMonthPreventive;

  // PM Status
  int totalUnits;
  int sudahPM;
  int belumPM;
  double pmPercentage;

  // Month/Year info
  String currentMonthName;
  String previousMonthName;

  DashboardStats({
    required this.currentMonthTroubleshooting,
    required this.currentMonthPreventive,
    required this.previousMonthTroubleshooting,
    required this.previousMonthPreventive,
    required this.totalUnits,
    required this.sudahPM,
    required this.belumPM,
    required this.pmPercentage,
    required this.currentMonthName,
    required this.previousMonthName,
  });

  // Calculated properties
  int get currentMonthTotal =>
      currentMonthTroubleshooting + currentMonthPreventive;
  int get previousMonthTotal =>
      previousMonthTroubleshooting + previousMonthPreventive;

  int get troubleshootingDiff =>
      currentMonthTroubleshooting - previousMonthTroubleshooting;
  int get preventiveDiff => currentMonthPreventive - previousMonthPreventive;

  bool get troubleshootingTrendUp => troubleshootingDiff > 0;
  bool get preventiveTrendUp => preventiveDiff > 0;

  double get troubleshootingChangePercent {
    if (previousMonthTroubleshooting == 0) return 0;
    return (troubleshootingDiff / previousMonthTroubleshooting) * 100;
  }

  double get preventiveChangePercent {
    if (previousMonthPreventive == 0) return 0;
    return (preventiveDiff / previousMonthPreventive) * 100;
  }

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    log('=== PARSING DASHBOARD STATS ===');
    log('Raw JSON: $json');

    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    // Parse month names
    final now = DateTime.now();
    final currentMonthName = _getMonthName(now.month);
    final previousMonth = now.month == 1 ? 12 : now.month - 1;
    final previousMonthName = _getMonthName(previousMonth);

    log('Current month name: $currentMonthName');
    log('Previous month name: $previousMonthName');

    // Ambil data dari 'data' key terlebih dahulu
    Map<String, dynamic> data = json['data'] ?? json;

    if (json['data'] == null) {
      log('⚠️ WARNING: data key is null, using root json');
    } else {
      log('✓ Using data from data key');
    }

    final currentMonth = data['current_month'] ?? {};
    final previousMonthData = data['previous_month'] ?? {};
    final pmStatus = data['pm_status'] ?? {};

    log('Current month data: $currentMonth');
    log('Previous month data: $previousMonthData');
    log('PM status data: $pmStatus');

    final stats = DashboardStats(
      currentMonthTroubleshooting: parseInt(currentMonth['troubleshooting']),
      currentMonthPreventive: parseInt(currentMonth['preventive']),
      previousMonthTroubleshooting: parseInt(
        previousMonthData['troubleshooting'],
      ),
      previousMonthPreventive: parseInt(previousMonthData['preventive']),
      totalUnits: parseInt(pmStatus['total_units']),
      sudahPM: parseInt(pmStatus['sudah_pm']),
      belumPM: parseInt(pmStatus['belum_pm']),
      pmPercentage: parseDouble(pmStatus['percentage']),
      currentMonthName: currentMonthName,
      previousMonthName: previousMonthName,
    );

    log('✓ Parsed stats:');
    log(
      '  - currentMonthTroubleshooting: ${stats.currentMonthTroubleshooting}',
    );
    log('  - currentMonthPreventive: ${stats.currentMonthPreventive}');
    log('  - totalUnits: ${stats.totalUnits}');
    log('  - sudahPM: ${stats.sudahPM}');
    log('=== DONE PARSING ===');
    return stats;
  }

  static String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  @override
  String toString() =>
      'DashboardStats('
      'currentMonthTroubleshooting: $currentMonthTroubleshooting, '
      'currentMonthPreventive: $currentMonthPreventive, '
      'previousMonthTroubleshooting: $previousMonthTroubleshooting, '
      'previousMonthPreventive: $previousMonthPreventive, '
      'totalUnits: $totalUnits, '
      'sudahPM: $sudahPM, '
      'belumPM: $belumPM'
      ')';
}
