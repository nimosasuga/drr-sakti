// lib/screens/dashboard_home_screen.dart
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Penting untuk formatting bulan
import '../models/user.dart';
import '../models/dashboard_stats.dart';
import '../models/update_job.dart';
import '../models/unit.dart';
import '../services/api_service.dart';
import '../constants/colors.dart';
import 'unit_assets/unit_assets_screen.dart';
import 'update_job/update_job_screen.dart';
import 'profile_screen.dart';
import 'penarikan/penarikan_screen.dart';
import 'admin_dashboard_screen.dart';
import 'battery/battery_screen.dart';
import 'charger/charger_screen.dart';
import 'delivery/delivery_screen.dart';

class DashboardHomeScreen extends StatefulWidget {
  final User user;

  const DashboardHomeScreen({super.key, required this.user});

  @override
  State<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<DashboardHomeScreen> {
  final ApiService _apiService = ApiService();

  // Data State
  bool _isLoading = true;
  String? _errorMessage;
  DashboardStats? _stats;

  // Raw Data Containers
  List<UpdateJob> _allJobs = [];
  List<Unit> _allUnits = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _debugLoadData();
  }

  // LOGIKA UTAMA: Mengambil data berdasarkan Role (Sesuai referensi Admin Dashboard)
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      developer.log('🔄 === START LOADING DASHBOARD DATA ===');
      developer.log(
        'User: ${widget.user.name} | Branch: ${widget.user.branch}',
      );

      // Reset data
      _allJobs = [];
      _allUnits = [];

      if (widget.user.isSuperAdmin) {
        developer.log('👤 Mode: SUPER ADMIN (Loading global data)');

        try {
          _allJobs = await _apiService.fetchUpdateJobs();
          developer.log('✅ Jobs loaded: ${_allJobs.length}');
        } catch (e) {
          developer.log('⚠️ Jobs fetch failed: $e');
          _allJobs = [];
        }

        try {
          _allUnits = await _apiService.fetchUnits();
          developer.log('✅ Units loaded: ${_allUnits.length}');
        } catch (e) {
          developer.log('⚠️ Units fetch failed: $e');
          _allUnits = [];
        }
      } else {
        developer.log(
          '👤 Mode: BRANCH USER (Loading branch: ${widget.user.branch})',
        );

        // Load Jobs by Branch
        try {
          developer.log('📥 Fetching jobs...');
          _allJobs = await _apiService.fetchUpdateJobsByBranch(
            widget.user.branch,
          );
          developer.log('✅ Jobs loaded: ${_allJobs.length}');
        } catch (e) {
          developer.log('⚠️ Jobs fetch failed: $e, continuing...');
          _allJobs = [];
        }

        // Load Units by Branch (dengan strategy baru)
        try {
          developer.log('📦 Fetching units...');
          _allUnits = await _apiService.fetchUnitsByBranch(widget.user.branch);
          developer.log('✅ Units loaded: ${_allUnits.length}');
        } catch (e) {
          developer.log('⚠️ Units fetch failed: $e, continuing...');
          _allUnits = [];
        }
      }

      developer.log('📊 DATA SUMMARY:');
      developer.log('   - Total Jobs: ${_allJobs.length}');
      developer.log('   - Total Units: ${_allUnits.length}');

      // Hitung statistik dari data yang ada
      _stats = _calculateLocalStats();
      developer.log('✅ Statistics calculated');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        developer.log('✅ === DATA LOAD COMPLETED ===');
      }
    } catch (e) {
      developer.log('❌ === CRITICAL ERROR IN _loadData ===');
      developer.log('Error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Terjadi kesalahan saat memuat data: ${e.toString()}';
        });
      }
    }
  }

  void _debugLoadData() async {
    developer.log('🐛 === DEBUG MODE - DIRECT UNIT FETCH ===');

    try {
      developer.log('Fetching ALL units directly...');
      final allUnits = await _apiService.fetchAllUnitsForFiltering();
      developer.log('Total units in DB: ${allUnits.length}');

      for (var unit in allUnits.take(5)) {
        developer.log('  - ${unit.serialNumber} | Branch: ${unit.branch}');
      }

      developer.log('Now filtering for branch: ${widget.user.branch}');
      final filtered = allUnits.where((u) {
        final unitBranch = u.branch?.toUpperCase() ?? '';
        final targetBranch = widget.user.branch.toUpperCase();
        return unitBranch == targetBranch;
      }).toList();

      developer.log('Filtered units: ${filtered.length}');
      for (var unit in filtered.take(5)) {
        developer.log('  - ${unit.serialNumber} | Branch: ${unit.branch}');
      }
    } catch (e) {
      developer.log('Debug error: $e');
    }
  }

  // LOGIKA KALKULASI: Mengubah List Jobs/Units menjadi DashboardStats
  DashboardStats _calculateLocalStats() {
    final now = DateTime.now();
    final currentMonthStr = DateFormat('yyyy-MM').format(now);

    // Hitung bulan lalu
    final prevMonthDate = DateTime(now.year, now.month - 1, 1);
    final prevMonthStr = DateFormat('yyyy-MM').format(prevMonthDate);

    // Nama Bulan untuk UI
    final currentMonthName = DateFormat('MMMM').format(now);
    final previousMonthName = DateFormat('MMMM').format(prevMonthDate);

    // MODIFIKASI: Variables counters
    int curTrb = 0;
    int lastTrb = 0;

    // MODIFIKASI: Gunakan Set untuk unique serial numbers (Preventive)
    Set<String> curPrevUnits = {};
    Set<String> lastPrevUnits = {};

    // MODIFIKASI: Loop jobs dengan logic yang benar
    for (var job in _allJobs) {
      if (job.date == null || job.date!.length < 7) continue;

      String jobMonth = job.date!.substring(0, 7);

      // MODIFIKASI: Normalisasi jobType - trim, uppercase, remove extra spaces
      final jobTypeRaw = (job.jobType ?? '').trim();
      if (jobTypeRaw.isEmpty) continue;

      // Split by comma, normalize each type
      final jobTypes = jobTypeRaw
          .split(',')
          .map((e) => e.trim()) // Trim dulu
          .where((e) => e.isNotEmpty)
          .map((e) => e.toUpperCase()) // Uppercase setelah trim
          .toList();

      // MODIFIKASI: Cek dengan exact match atau contains PREVENTIVE/TROUBLESHOOTING
      bool hasPreventive = jobTypes.any(
        (t) => t == 'PREVENTIVE MAINTENANCE' || t.contains('PREVENTIVE'),
      );

      bool hasTroubleshooting = jobTypes.any(
        (t) =>
            t == 'TROUBLESHOOTING' ||
            t.contains('TROUBLESHOOT'), // Typo-tolerant
      );

      developer.log(
        'Job ID: ${job.id} | Month: $jobMonth | Raw: "$jobTypeRaw" | '
        'Parsed: $jobTypes | Prev: $hasPreventive | Trb: $hasTroubleshooting',
      );

      // MODIFIKASI: Current Month Stats
      if (jobMonth == currentMonthStr) {
        // MODIFIKASI: Preventive - count unique units only
        if (hasPreventive &&
            job.serialNumber != null &&
            job.serialNumber!.trim().isNotEmpty) {
          curPrevUnits.add(job.serialNumber!.trim());
        }
        // Troubleshooting - count total jobs
        if (hasTroubleshooting) curTrb++;
      }
      // MODIFIKASI: Previous Month Stats
      else if (jobMonth == prevMonthStr) {
        // MODIFIKASI: Preventive - count unique units only
        if (hasPreventive &&
            job.serialNumber != null &&
            job.serialNumber!.trim().isNotEmpty) {
          lastPrevUnits.add(job.serialNumber!.trim());
        }
        // Troubleshooting - count total jobs
        if (hasTroubleshooting) lastTrb++;
      }
    }

    // MODIFIKASI: Hitung dari Set (unique units untuk Preventive)
    int curPrev = curPrevUnits.length;
    int lastPrev = lastPrevUnits.length;

    developer.log('📊 STATISTICS CALCULATION:');
    developer.log('Current Month ($currentMonthStr):');
    developer.log('  - Preventive (Unique Units): $curPrev');
    developer.log('  - Troubleshooting (Total Jobs): $curTrb');
    developer.log('Previous Month ($prevMonthStr):');
    developer.log('  - Preventive (Unique Units): $lastPrev');
    developer.log('  - Troubleshooting (Total Jobs): $lastTrb');

    // MODIFIKASI: PM Progress - gunakan Set untuk unique serial numbers
    Set<String> unitsWithPreventiveThisMonth = {};

    for (var job in _allJobs) {
      if (job.date == null || job.date!.length < 7) continue;

      String jobMonth = job.date!.substring(0, 7);

      // Filter HANYA bulan ini
      if (jobMonth != currentMonthStr) continue;

      // MODIFIKASI: Normalisasi jobType sama seperti di atas
      final jobTypeRaw = (job.jobType ?? '').trim();
      if (jobTypeRaw.isEmpty) continue;

      final jobTypes = jobTypeRaw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .map((e) => e.toUpperCase())
          .toList();

      // MODIFIKASI: Cek PREVENTIVE dengan cara yang sama
      bool hasPreventive = jobTypes.any(
        (t) => t == 'PREVENTIVE MAINTENANCE' || t.contains('PREVENTIVE'),
      );

      // MODIFIKASI: Tambahkan ke Set hanya jika ada serialNumber yang valid
      if (hasPreventive &&
          job.serialNumber != null &&
          job.serialNumber!.trim().isNotEmpty) {
        final cleanSerialNumber = job.serialNumber!.trim();
        unitsWithPreventiveThisMonth.add(cleanSerialNumber);
        developer.log(
          '✅ PM Job Found: $cleanSerialNumber | Raw: "$jobTypeRaw" | Parsed: $jobTypes',
        );
      }
    }

    // Hitung berdasarkan unit yang ada di system
    int totalUnits = _allUnits.length;

    // MODIFIKASI: Cross-check dengan unit list (case-insensitive comparison)
    int sudahPreventive = 0;
    for (var unit in _allUnits) {
      if (unit.serialNumber == null || unit.serialNumber!.trim().isEmpty) {
        continue; // <-- Selalu gunakan {}
      }

      final unitSerial = unit.serialNumber!.trim();

      // MODIFIKASI: Case-insensitive match
      if (unitsWithPreventiveThisMonth.any(
        (pmSerial) => pmSerial.toUpperCase() == unitSerial.toUpperCase(),
      )) {
        sudahPreventive++;
      }
    }

    int belumPreventive = totalUnits > sudahPreventive
        ? (totalUnits - sudahPreventive)
        : 0;

    double preventivePercentage = totalUnits > 0
        ? (sudahPreventive / totalUnits) * 100
        : 0.0;

    developer.log('📊 PM PROGRESS CALCULATION:');
    developer.log('Current Month: $currentMonthStr');
    developer.log('Total Units in System: $totalUnits');
    developer.log(
      'Unique Serial Numbers with PM Job: ${unitsWithPreventiveThisMonth.length}',
    );
    developer.log('Matched Units (Sudah Preventive): $sudahPreventive');
    developer.log('Belum Preventive: $belumPreventive');
    developer.log(
      'Preventive Percentage: ${preventivePercentage.toStringAsFixed(1)}%',
    );

    // MODIFIKASI: Debug - tampilkan 5 sample serial numbers
    developer.log('Sample PM Serial Numbers:');
    for (var serial in unitsWithPreventiveThisMonth.take(5)) {
      developer.log('  - "$serial"');
    }

    // MODIFIKASI: Validasi - pastikan angka Statistics dan PM Progress match
    if (curPrev != sudahPreventive) {
      developer.log(
        '⚠️ WARNING: Statistics Preventive ($curPrev) != PM Progress ($sudahPreventive)',
      );
      developer.log('   This should not happen! Check the logic.');
    } else {
      developer.log(
        '✅ VALIDATION: Statistics and PM Progress match! ($curPrev = $sudahPreventive)',
      );
    }

    return DashboardStats(
      currentMonthTroubleshooting: curTrb,
      currentMonthPreventive: curPrev, // MODIFIKASI: Sekarang unique units
      previousMonthTroubleshooting: lastTrb,
      previousMonthPreventive: lastPrev, // MODIFIKASI: Sekarang unique units
      totalUnits: totalUnits,
      sudahPM: sudahPreventive,
      belumPM: belumPreventive,
      pmPercentage: preventivePercentage,
      currentMonthName: currentMonthName,
      previousMonthName: previousMonthName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📊 Dashboard'),
            Text(
              widget.user.isSuperAdmin
                  ? '${widget.user.name} • Global Data' // Tampilan Super Admin
                  : '${widget.user.name} • ${widget.user.branch}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _buildErrorState()
            : _stats == null
            ? const Center(child: Text('No data available'))
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 3: PM Status (Paling Penting)
                      _buildPMStatusSection(_stats!),
                      const SizedBox(height: 24),

                      // Section 1: Statistics Header
                      _buildStatisticsSection(_stats!),
                      const SizedBox(height: 24),

                      // Section 2: Menu Grid
                      _buildMenuSection(context),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $_errorMessage'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }

  // ===== SECTION 1: STATISTICS =====
  Widget _buildStatisticsSection(DashboardStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📈 Maintenance Statistics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${stats.currentMonthName} vs ${stats.previousMonthName}',
          style: const TextStyle(fontSize: 12, color: AppColors.disabled),
        ),
        const SizedBox(height: 16),

        // Troubleshooting Card
        _buildStatCard(
          title: '🔧 TROUBLESHOOTING',
          currentMonth: stats.currentMonthTroubleshooting,
          previousMonth: stats.previousMonthTroubleshooting,
          currentMonthName: stats.currentMonthName,
          previousMonthName: stats.previousMonthName,
          diff: stats.troubleshootingDiff,
          changePercent: stats.troubleshootingChangePercent,
          trendUp: stats.troubleshootingTrendUp,
          color: Colors.orange,
        ),
        const SizedBox(height: 12),

        // Preventive Maintenance Card
        _buildStatCard(
          title: '✅ PREVENTIVE MAINTENANCE',
          currentMonth: stats.currentMonthPreventive,
          previousMonth: stats.previousMonthPreventive,
          currentMonthName: stats.currentMonthName,
          previousMonthName: stats.previousMonthName,
          diff: stats.preventiveDiff,
          changePercent: stats.preventiveChangePercent,
          trendUp: stats.preventiveTrendUp,
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required int currentMonth,
    required int previousMonth,
    required String currentMonthName,
    required String previousMonthName,
    required int diff,
    required double changePercent,
    required bool trendUp,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(51), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This Month ($currentMonthName)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.disabled,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentMonth.toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Last Month ($previousMonthName)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.disabled,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    previousMonth.toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.disabled,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: trendUp
                  ? Colors.green.withAlpha(26)
                  : Colors.red.withAlpha(26),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  trendUp ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: trendUp ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  '${trendUp ? '+' : ''}$diff (${trendUp ? '+' : ''}${changePercent.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: trendUp ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== SECTION 2: MENU GRID =====
  Widget _buildMenuSection(BuildContext context) {
    bool canAccessAdmin = widget.user.isSuperAdmin || widget.user.isCoordinator;

    final List<Map<String, dynamic>> menuItems = [
      {
        'icon': Icons.inventory_2,
        'label': 'Unit Assets',
        'color': Colors.blue,
        'gradient': [Colors.blue.shade400, Colors.blue.shade600],
        'route': UnitAssetsScreen(user: widget.user),
      },
      {
        'icon': Icons.build_circle,
        'label': 'Update Jobs',
        'color': Colors.orange,
        'gradient': [Colors.orange.shade400, Colors.orange.shade600],
        'route': UpdateJobScreen(user: widget.user),
      },
      {
        'icon': Icons.battery_charging_full,
        'label': 'Battery Management',
        'color': Colors.amber,
        'gradient': [Colors.amber.shade400, Colors.amber.shade600],
        'route': BatteryScreen(user: widget.user),
      },
      {
        'icon': Icons.charging_station,
        'label': 'Charger Management',
        'color': const Color(0xFF3CF92F),
        'gradient': [const Color(0xFF4CAF50), const Color(0xFF45C945)],
        'route': ChargerScreen(user: widget.user),
      },
      {
        'icon': Icons.forklift,
        'label': 'Delivery',
        'color': Colors.teal,
        'gradient': [Colors.teal.shade400, Colors.teal.shade600],
        'route': DeliveryScreen(user: widget.user),
      },
      {
        'icon': Icons.download,
        'label': 'Penarikan Units',
        'color': Colors.purple,
        'gradient': [Colors.purple.shade400, Colors.purple.shade600],
        'route': PenarikanScreen(user: widget.user),
      },
      if (canAccessAdmin)
        {
          'icon': Icons.admin_panel_settings,
          'label': 'Admin Dashboard',
          'color': AppColors.warning,
          'gradient': [Colors.red.shade400, Colors.red.shade600],
          'route': AdminDashboardScreen(user: widget.user),
        }
      else
        {
          'icon': Icons.person,
          'label': 'Profile',
          'color': Colors.teal,
          'gradient': [Colors.teal.shade400, Colors.teal.shade600],
          'route': ProfileScreen(user: widget.user),
        },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            children: [
              Icon(Icons.dashboard, size: 20, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Quick Access Menu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 20,
            mainAxisSpacing: 24,
            childAspectRatio: 0.85,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: menuItems.length,
          itemBuilder: (context, index) {
            final item = menuItems[index];
            return _buildModernMenuButton(
              icon: item['icon'] as IconData,
              label: item['label'] as String,
              gradient: item['gradient'] as List<Color>,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => item['route'] as Widget,
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildModernMenuButton({
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        // Modern circular button with gradient
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: gradient.first.withAlpha(102),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(36),
              splashColor: Colors.white.withAlpha(77),
              highlightColor: Colors.white.withAlpha(51),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Icon(icon, size: 30, color: Colors.white)],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            height: 1.2,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ===== SECTION 3: PM STATUS =====
  Widget _buildPMStatusSection(DashboardStats stats) {
    final preventiveProgress = stats.totalUnits > 0
        ? (stats.sudahPM / stats.totalUnits).toDouble()
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // MODIFIKASI: Title yang jelas
        Text(
          '✅ Preventive Maintenance Progress - ${stats.currentMonthName}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Units completed Preventive Maintenance this month vs Total Units',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.disabled,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.success.withAlpha(51),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withAlpha(26),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info box untuk clarity
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(13),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 18,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Based on update_jobs with jobType containing "PREVENTIVE MAINTENANCE"',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.success,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Status Cards Row dengan label yang benar
              Row(
                children: [
                  Expanded(
                    child: _buildStatusCard(
                      icon: Icons.check_circle,
                      label: 'SUDAH PREVENTIVE',
                      value: stats.sudahPM.toString(),
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatusCard(
                      icon: Icons.pending_actions,
                      label: 'BELUM PREVENTIVE',
                      value: stats.belumPM.toString(),
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatusCard(
                      icon: Icons.inventory_2,
                      label: 'TOTAL UNIT',
                      value: stats.totalUnits.toString(),
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Progress',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.disabled,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: preventiveProgress,
                      minHeight: 24,
                      backgroundColor: Colors.orange.withAlpha(51),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        preventiveProgress >= 0.8
                            ? AppColors.success
                            : preventiveProgress >= 0.5
                            ? Colors.orange
                            : Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(preventiveProgress * 100).toStringAsFixed(1)}% Complete',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                      Text(
                        '${stats.sudahPM} of ${stats.totalUnits}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.disabled,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Reference note
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(13),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.link, size: 14, color: AppColors.disabled),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Synced with "PREVENTIVE MAINTENANCE" count in Statistics',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.disabled,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
