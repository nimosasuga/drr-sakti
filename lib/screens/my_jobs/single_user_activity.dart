// lib/screens/my_jobs/single_user_activity.dart
import 'package:flutter/material.dart';
import 'dart:developer' as developer;

import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../constants/colors.dart';
import '../../constants/typography.dart';

// Import screens untuk navigasi
import '../update_job/update_job_screen.dart';
import '../penarikan/penarikan_screen.dart';
import '../delivery/delivery_screen.dart';
import '../charger/charger_screen.dart';
import '../battery/battery_screen.dart';

class SingleUserActivityScreen extends StatefulWidget {
  final User user;

  const SingleUserActivityScreen({super.key, required this.user});

  @override
  State<SingleUserActivityScreen> createState() =>
      _SingleUserActivityScreenState();
}

class _SingleUserActivityScreenState extends State<SingleUserActivityScreen>
    with SingleTickerProviderStateMixin {
  final ApiService api = ApiService();

  // Data stats
  int _updateJobCount = 0;
  int _penarikanCount = 0;
  int _deliveryCount = 0;
  int _chargerCount = 0;
  int _batteryCount = 0;

  bool _loading = true;
  String? _error;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadActivityStats();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadActivityStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Fetch data untuk setiap kategori dengan filter PIC
      await Future.wait([
        _fetchUpdateJobCount(),
        _fetchPenarikanCount(),
        _fetchDeliveryCount(),
        _fetchChargerCount(),
        _fetchBatteryCount(),
      ]);

      if (mounted) {
        setState(() {
          _loading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      developer.log('Error loading activity stats: $e');
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat data aktivitas';
          _loading = false;
        });
      }
    }
  }

  Future<void> _fetchUpdateJobCount() async {
    try {
      final jobs = await api.fetchUpdateJobsByBranch(widget.user.branch);
      final filtered = jobs
          .where((j) => j.pic?.toLowerCase() == widget.user.name.toLowerCase())
          .toList();

      if (mounted) {
        setState(() {
          _updateJobCount = filtered.length;
        });
      }
    } catch (e) {
      developer.log('Error fetching update jobs: $e');
    }
  }

  Future<void> _fetchPenarikanCount() async {
    try {
      final data = await api.fetchPenarikanByBranch(widget.user.branch);
      final filtered = data
          .where((p) => p.pic?.toLowerCase() == widget.user.name.toLowerCase())
          .toList();

      if (mounted) {
        setState(() {
          _penarikanCount = filtered.length;
        });
      }
    } catch (e) {
      developer.log('Error fetching penarikan: $e');
    }
  }

  Future<void> _fetchDeliveryCount() async {
    try {
      final data = await api.fetchDelivery();
      final filtered = data
          .where((d) => d.pic?.toLowerCase() == widget.user.name.toLowerCase())
          .toList();

      if (mounted) {
        setState(() {
          _deliveryCount = filtered.length;
        });
      }
    } catch (e) {
      developer.log('Error fetching delivery: $e');
    }
  }

  Future<void> _fetchChargerCount() async {
    try {
      final data = await api.fetchChargerByBranch(widget.user.branch);
      final filtered = data
          .where((c) => c.pic?.toLowerCase() == widget.user.name.toLowerCase())
          .toList();

      if (mounted) {
        setState(() {
          _chargerCount = filtered.length;
        });
      }
    } catch (e) {
      developer.log('Error fetching charger: $e');
    }
  }

  Future<void> _fetchBatteryCount() async {
    try {
      final data = await api.fetchBatteryByBranch(widget.user.branch);
      final filtered = data
          .where((b) => b.pic?.toLowerCase() == widget.user.name.toLowerCase())
          .toList();

      if (mounted) {
        setState(() {
          _batteryCount = filtered.length;
        });
      }
    } catch (e) {
      developer.log('Error fetching battery: $e');
    }
  }

  // Navigation Methods - Pass picFilterName
  void _navigateToUpdateJob() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            UpdateJobScreen(user: widget.user, picFilterName: widget.user.name),
      ),
    ).then((_) => _loadActivityStats()); // Refresh saat kembali
  }

  void _navigateToPenarikan() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PenarikanScreen(user: widget.user, picFilterName: widget.user.name),
      ),
    ).then((_) => _loadActivityStats());
  }

  void _navigateToDelivery() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DeliveryScreen(user: widget.user, picFilterName: widget.user.name),
      ),
    ).then((_) => _loadActivityStats());
  }

  void _navigateToCharger() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ChargerScreen(user: widget.user, picFilterName: widget.user.name),
      ),
    ).then((_) => _loadActivityStats());
  }

  void _navigateToBattery() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            BatteryScreen(user: widget.user, picFilterName: widget.user.name),
      ),
    ).then((_) => _loadActivityStats());
  }

  Widget _buildActivityCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required int count,
    required List<Color> gradientColors,
    required VoidCallback onTap,
    required int index,
  }) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(
                  index * 0.1,
                  0.6 + (index * 0.1),
                  curve: Curves.easeOutCubic,
                ),
              ),
            ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withAlpha((255 * 0.3).round()),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    // Icon Container
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((255 * 0.3).round()),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(icon, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withAlpha(
                                (255 * 0.9).round(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Count Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((255 * 0.3).round()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        count.toString(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white.withAlpha((255 * 0.8).round()),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withAlpha((255 * 0.8).round()),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha((255 * 0.3).round()),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((255 * 0.1).round()),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Activities',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.user.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha((255 * 0.1).round()),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withAlpha((255 * 0.3).round()),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Branch: ${widget.user.branch}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalActivities =
        _updateJobCount +
        _penarikanCount +
        _deliveryCount +
        _chargerCount +
        _batteryCount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha((255 * 0.1).round()),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha((255 * 0.1).round()),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Ringkasan Aktivitas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Update Job', _updateJobCount),
              const SizedBox(width: 12),
              _buildSummaryItem('Tarik Unit', _penarikanCount),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Delivery', _deliveryCount),
              const SizedBox(width: 12),
              _buildSummaryItem('Charger', _chargerCount),
            ],
          ),
          const SizedBox(height: 12),
          // PERBAIKAN: Dibungkus Row agar Expanded bekerja horizontal
          Row(children: [_buildSummaryItem('Battery', _batteryCount)]),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withAlpha((255 * 0.1).round()),
                  AppColors.secondary.withAlpha((255 * 0.1).round()),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Aktivitas',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  totalActivities.toString(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Memuat aktivitas Anda...',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.disabled,
                    ),
                  ),
                ],
              ),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error.withAlpha((255 * 0.8).round()),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loadActivityStats,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadActivityStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          _buildActivityCard(
                            title: 'Update Job',
                            subtitle: 'Pekerjaan unit rental',
                            icon: Icons.assignment_turned_in_rounded,
                            count: _updateJobCount,
                            gradientColors: [
                              const Color(0xFF667eea),
                              const Color(0xFF764ba2),
                            ],
                            onTap: _navigateToUpdateJob,
                            index: 0,
                          ),
                          _buildActivityCard(
                            title: 'Tarik Unit',
                            subtitle: 'Penarikan unit',
                            icon: Icons.local_shipping_rounded,
                            count: _penarikanCount,
                            gradientColors: [
                              const Color(0xFFf093fb),
                              const Color(0xFFf5576c),
                            ],
                            onTap: _navigateToPenarikan,
                            index: 1,
                          ),
                          _buildActivityCard(
                            title: 'Delivery',
                            subtitle: 'Pengiriman unit',
                            icon: Icons.directions_car_rounded,
                            count: _deliveryCount,
                            gradientColors: [
                              const Color(0xFF4facfe),
                              const Color(0xFF00f2fe),
                            ],
                            onTap: _navigateToDelivery,
                            index: 2,
                          ),
                          _buildActivityCard(
                            title: 'Charger',
                            subtitle: 'Manajemen charger',
                            icon: Icons.power_rounded,
                            count: _chargerCount,
                            gradientColors: [
                              const Color(0xFFfa709a),
                              const Color(0xFFfee140),
                            ],
                            onTap: _navigateToCharger,
                            index: 3,
                          ),
                          _buildActivityCard(
                            title: 'Battery',
                            subtitle: 'Manajemen baterai',
                            icon: Icons.battery_charging_full_rounded,
                            count: _batteryCount,
                            gradientColors: [
                              const Color(0xFF30cfd0),
                              const Color(0xFF330867),
                            ],
                            onTap: _navigateToBattery,
                            index: 4,
                          ),
                        ],
                      ),
                    ),
                    _buildSummaryCard(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }
}
