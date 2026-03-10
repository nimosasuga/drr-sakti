import 'package:drr_sakti/screens/my_jobs/single_user_activity.dart';
import 'package:flutter/material.dart';
import 'dart:developer';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../models/user.dart';
import 'login_screen.dart';
import '../constants/colors.dart';
import '../constants/typography.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final User user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late ApiService api;
  Map<String, dynamic>? mechanicStats;
  bool loadingStats = false;
  int pendingBreakdowns = 0;

  // State untuk section ubah password
  bool _showChangePasswordSection = false;
  bool _changingPassword = false;

  // Form controllers
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Form key untuk validasi
  final GlobalKey<FormState> _changePasswordFormKey = GlobalKey<FormState>();

  // Method untuk toggle section
  void _toggleChangePasswordSection() {
    setState(() {
      _showChangePasswordSection = !_showChangePasswordSection;
      // Reset form ketika section ditutup
      if (!_showChangePasswordSection) {
        _resetPasswordForm();
      }
    });
  }

  // Method untuk reset form
  void _resetPasswordForm() {
    _oldPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    _changePasswordFormKey.currentState?.reset();
  }

  // Method untuk validasi password
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password harus mengandung angka';
    }
    if (!value.contains(RegExp(r'[a-zA-Z]'))) {
      return 'Password harus mengandung huruf';
    }
    return null;
  }

  // Method untuk validasi konfirmasi password
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password tidak boleh kosong';
    }
    if (value != _newPasswordController.text) {
      return 'Konfirmasi password tidak sesuai';
    }
    return null;
  }

  // Method untuk proses ubah password - IMPROVED VERSION
  Future<void> _changePassword() async {
    if (!_changePasswordFormKey.currentState!.validate()) {
      return;
    }

    // Hapus penyimpanan 'final context = this.context;'
    // Kita akan langsung menggunakan this.context dengan perlindungan 'mounted'

    if (!mounted) return; // Guard awal
    setState(() => _changingPassword = true);

    // Show loading dialog
    // Gunakan this.context secara langsung (aman karena belum ada await)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        // Gunakan nama lain untuk menghindari kebingungan
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Mengubah password...'),
            ],
          ),
        );
      },
    );

    try {
      final result = await api.changePassword(
        userId: user.id,
        nrpp: user.nrpp,
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      // Setelah await, SELALU cek mounted sebelum menggunakan context
      if (!mounted) return;

      // Close loading dialog
      // Menggunakan context yang dilindungi oleh if (!mounted) return;
      Navigator.of(context).pop();

      if (result['ok'] == true) {
        // Success - show success dialog dan auto logout
        _showPasswordChangeSuccess();
      } else {
        // Error - show error dialog
        final errorMessage = result['message'] ?? 'Gagal mengubah password';
        _showPasswordChangeError(errorMessage);
      }
    } catch (e) {
      // Setelah await, SELALU cek mounted sebelum menggunakan context
      if (!mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();
      _showPasswordChangeError('Terjadi kesalahan: $e');
    } finally {
      // Selalu cek mounted sebelum setState
      if (mounted) {
        setState(() => _changingPassword = false);
      }
    }
  }

  // Method untuk menampilkan dialog success
  void _showPasswordChangeSuccess() {
    final context = this.context;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success),
              SizedBox(width: 8),
              Text('Password Berhasil Diubah'),
            ],
          ),
          content: Text(
            'Password Anda berhasil diubah. Anda akan logout otomatis untuk keamanan.',
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performLogoutAfterPasswordChange();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Method untuk menampilkan dialog error
  void _showPasswordChangeError(String message) {
    final context = this.context;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: AppColors.error),
              SizedBox(width: 8),
              Text('Gagal Mengubah Password'),
            ],
          ),
          content: Text(message, style: AppTextStyles.bodyMedium),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Tutup',
                style: AppTextStyles.button.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  // Method untuk logout setelah password berubah
  void _performLogoutAfterPasswordChange() {
    final context = this.context;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    api = ApiService();
    // Initialize dengan default values yang type-safe
    mechanicStats = {
      'totalJobs': 0,
      'efficiency': 0.0,
      'pendingBreakdowns': 0,
      'jobTypes': [],
      'month': 'Current Month',
      'matchedPic': null,
    };
    _loadMechanicStats();
  }

  Future<void> _loadMechanicStats() async {
    if (!widget.user.isFieldService && !widget.user.isFMC) return;

    if (mounted) {
      setState(() => loadingStats = true);
    }

    try {
      log('🔄 Loading mechanic stats for: ${widget.user.name}');

      final stats = await api.getMechanicStats(widget.user.name);

      log('🔍 RAW API RESPONSE:');
      log('  - success: ${stats['success']}');
      log(
        '  - totalJobs: ${stats['totalJobs']} (type: ${stats['totalJobs']?.runtimeType})',
      );
      log(
        '  - efficiency: ${stats['efficiency']} (type: ${stats['efficiency']?.runtimeType})',
      );
      log(
        '  - pendingBreakdowns: ${stats['pendingBreakdowns']} (type: ${stats['pendingBreakdowns']?.runtimeType})',
      );
      log('  - jobTypes: ${stats['jobTypes']}');

      if (stats['success'] == true) {
        // DEBUG: Print setiap value sebelum konversi
        final totalJobsStr = stats['totalJobs']?.toString() ?? '0';
        final efficiencyStr = stats['efficiency']?.toString() ?? '0';
        final pendingStr = stats['pendingBreakdowns']?.toString() ?? '0';

        log('🔧 BEFORE CONVERSION:');
        log('  - totalJobsStr: "$totalJobsStr"');
        log('  - efficiencyStr: "$efficiencyStr"');
        log('  - pendingStr: "$pendingStr"');

        // Konversi dengan safety
        final totalJobs = int.tryParse(totalJobsStr) ?? 0;
        final efficiency = double.tryParse(efficiencyStr) ?? 0.0;
        final pendingBreakdowns = int.tryParse(pendingStr) ?? 0;

        log('🔧 AFTER CONVERSION:');
        log('  - totalJobs: $totalJobs (type: ${totalJobs.runtimeType})');
        log('  - efficiency: $efficiency (type: ${efficiency.runtimeType})');
        log(
          '  - pendingBreakdowns: $pendingBreakdowns (type: ${pendingBreakdowns.runtimeType})',
        );

        // Simpan data dengan type yang benar - check mounted
        if (mounted) {
          setState(() {
            mechanicStats = {
              'totalJobs': totalJobs,
              'jobTypes': stats['jobTypes'] ?? [],
              'pendingBreakdowns': pendingBreakdowns,
              'efficiency': efficiency,
              'month': stats['month'] ?? 'Current Month',
              'matchedPic': stats['matched_pic'],
            };
            this.pendingBreakdowns = pendingBreakdowns;
          });
        }

        log('✅ Stats successfully loaded and converted');
      } else {
        log('❌ API returned success: false');
        if (mounted) {
          _loadFallbackStats();
        }
      }
    } catch (error) {
      log('❌ Error loading real stats: $error');
      log('❌ Error type: ${error.runtimeType}');
      // StackTrace hanya available untuk Exception, bukan Object
      if (error is Exception) {
        log('❌ Stack trace: ${error.toString()}');
      }
      if (mounted) {
        _loadFallbackStats();
      }
    } finally {
      if (mounted) {
        setState(() => loadingStats = false);
      }
    }
  }

  void _loadFallbackStats() {
    log('🔄 Loading fallback stats');
    setState(() {
      mechanicStats = {
        'totalJobs': 0,
        'jobTypes': [],
        'pendingBreakdowns': 0,
        'efficiency': 0.0,
        'month': 'Current Month',
        'matchedPic': null,
      };
      pendingBreakdowns = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // 1. PROFILE HEADER
              _buildProfileHeader(context),
              _buildMyActivitiesButton(context),

              // 2. STATISTIK MEKANIK (hanya untuk Field Service & FMC)
              if (widget.user.isFieldService || widget.user.isFMC)
                _buildMechanicStatsSection(),

              // 3. DETAIL INFORMASI
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DETAIL AKUN',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.disabled,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildDetailTile(Icons.badge, 'NRPP', user.nrpp),
                          const Divider(height: 0),
                          _buildDetailTile(
                            Icons.business,
                            'Branch',
                            user.branch,
                          ),
                          const Divider(height: 0),
                          _buildDetailTile(
                            Icons.person_pin_circle,
                            'Role',
                            user.statusUser,
                          ),
                          const Divider(height: 0),
                          _buildDetailTile(
                            Icons.key,
                            'Token (Base64)',
                            user.token.length > 10
                                ? '${user.token.substring(0, 10)}...'
                                : user.token,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 4. TOMBOL UBAH PASSWORD (Expandable Section Trigger)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => _toggleChangePasswordSection(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.info,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.lock, size: 20),
                        label: Text(
                          'UBAH PASSWORD',
                          style: AppTextStyles.button.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    // 5. SECTION UBAH PASSWORD (Expandable)
                    if (_showChangePasswordSection)
                      _buildChangePasswordSection(),

                    const SizedBox(height: 24),

                    // 6. PERMISSIONS & ROLES (yang sudah ada)
                    Text(
                      'HAK AKSES & PERAN',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.disabled,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPermissionItem(
                              'Super Admin',
                              user.isSuperAdmin,
                            ),
                            _buildPermissionItem(
                              'Koordinator',
                              user.isCoordinator,
                            ),
                            _buildPermissionItem(
                              'Field Service',
                              user.isFieldService,
                            ),
                            _buildPermissionItem('FMC', user.isFMC),
                            const Divider(),
                            _buildPermissionItem(
                              'View All Units',
                              user.canViewAllUnits,
                            ),
                            _buildPermissionItem(
                              'View All Jobs',
                              user.canViewAllJobs,
                            ),
                            _buildPermissionItem(
                              'Create Unit',
                              user.canCreateUnit,
                            ),
                            _buildPermissionItem(
                              'Create Job',
                              user.canCreateJob,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 7. TOMBOL LOGOUT (yang sudah ada)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => _showLogoutConfirmation(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.logout, size: 20),
                        label: Text(
                          'LOGOUT DARI ${user.name}',
                          style: AppTextStyles.button.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Text(
              user.name.isNotEmpty
                  ? user.name.substring(0, 1).toUpperCase()
                  : '?',
              style: AppTextStyles.headlineLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user.name,
            style: AppTextStyles.headlineMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              user.statusUser,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMechanicStatsSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'STATISTIK KINERJA ${mechanicStats?['month'] ?? 'BULAN INI'}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (loadingStats)
            _buildLoadingStats()
          else if (mechanicStats != null)
            Column(
              children: [
                // Ringkasan Statistik
                _buildStatsSummary(),
                const SizedBox(height: 16),

                // Chart Distribusi Job Type
                _buildJobTypeChart(),
                const SizedBox(height: 16),

                // Peringatan Breakdown
                if (pendingBreakdowns > 0) _buildBreakdownAlert(),
              ],
            )
          else
            _buildNoStatsAvailable(),
        ],
      ),
    );
  }

  Widget _buildLoadingStats() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        height: 200,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Memuat statistik kinerja...'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSummary() {
    final totalJobs = mechanicStats?['totalJobs'] is int
        ? mechanicStats!['totalJobs'] as int
        : 0;
    final efficiency = mechanicStats?['efficiency'] is double
        ? mechanicStats!['efficiency'] as double
        : 0.0;
    final pending = mechanicStats?['pendingBreakdowns'] is int
        ? mechanicStats!['pendingBreakdowns'] as int
        : 0;

    log('📋 Stats Summary:');
    log('  - totalJobs: $totalJobs (type: ${totalJobs.runtimeType})');
    log('  - efficiency: $efficiency (type: ${efficiency.runtimeType})');
    log('  - pending: $pending (type: ${pending.runtimeType})');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total Jobs',
                  totalJobs.toString(),
                  Icons.work,
                  AppColors.primary,
                ),
                _buildStatItem(
                  'Efisiensi',
                  '${efficiency.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  efficiency >= 80 ? AppColors.success : AppColors.warning,
                ),
                _buildStatItem(
                  'Pending RFU',
                  pending.toString(),
                  Icons.warning,
                  pending > 0 ? AppColors.error : AppColors.success,
                ),
              ],
            ),
            if (mechanicStats?['matchedPic'] != null) ...[
              const SizedBox(height: 12),
              Text(
                'Data untuk: ${mechanicStats?['matchedPic']}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.disabled,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: AppTextStyles.caption.copyWith(color: AppColors.disabled),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildJobTypeChart() {
    final jobTypes = mechanicStats?['jobTypes'] ?? [];

    log('📊 Building chart with jobTypes: $jobTypes');
    log('📊 jobTypes type: ${jobTypes.runtimeType}');

    // Peta untuk menyimpan hitungan job type yang sudah difilter
    final Map<String, int> filteredJobCounts = {};

    // Konversi API data format ke chart format dengan safety dan filter
    // FINAL: List ini akan digunakan untuk chart (hanya berisi PM dan TS)
    final List<Map<String, dynamic>> chartData = [];

    for (final job in jobTypes) {
      try {
        if (job is Map<String, dynamic>) {
          final jobTypeApi = job['job_type']?.toString() ?? 'Unknown';
          final countStr = job['count']?.toString() ?? '0';
          final count = int.tryParse(countStr) ?? 0;

          if (count > 0) {
            // Memisahkan job type jika ada koma (contoh: "Preventive Maintenance, Install")
            final types = jobTypeApi.split(',').map((e) => e.trim()).toList();

            // Logika Pemfilteran: Hanya hitung Preventive Maintenance (PM) dan Troubleshooting (TS)
            for (final type in types) {
              final upperType = type.toUpperCase();

              if (upperType.contains('PREVENTIVE MAINTENANCE')) {
                // Aturan: Hitung PM. Jika ada PM dan TS, keduanya dihitung.
                filteredJobCounts[type] =
                    (filteredJobCounts[type] ?? 0) + count;
                log('  - HIT: $type (Count: $count) added.');
              } else if (upperType.contains('TROUBLESHOOTING')) {
                // Aturan: Hitung TS. Jika ada PM dan TS, keduanya dihitung.
                filteredJobCounts[type] =
                    (filteredJobCounts[type] ?? 0) + count;
                log('  - HIT: $type (Count: $count) added.');
              } else {
                // Aturan: Jenis pekerjaan lain diabaikan dalam distribusi ini.
                log('  - SKIP: $type (Bukan PM/TS)');
              }
            }
          }
        } else {
          log('  - Skipping invalid job item: $job (type: ${job.runtimeType})');
        }
      } catch (e) {
        log('  - Error processing job item: $e');
      }
    }

    // Mengubah Map hitungan ke List untuk digunakan di SfCircularChart
    filteredJobCounts.forEach((key, value) {
      chartData.add({'type': key, 'count': value});
    });

    log('📈 Final chart data: $chartData');
    log('📈 Chart data length: ${chartData.length}');

    // Check if we have valid data untuk chart
    final hasValidData =
        chartData.isNotEmpty &&
        chartData.any((item) => (item['count'] as int) > 0);

    log('📈 Has valid data for chart: $hasValidData');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribusi Jenis Pekerjaan',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Berdasarkan kategori job type ${mechanicStats?['month'] ?? 'ini'}',
              style: AppTextStyles.caption.copyWith(color: AppColors.disabled),
            ),
            const SizedBox(height: 16),

            if (hasValidData)
              SizedBox(
                height: 200,
                child: SfCircularChart(
                  palette: [
                    AppColors.primary,
                    const Color.fromARGB(255, 255, 0, 0),
                    AppColors.success,
                    AppColors.warning,
                    AppColors.error,
                    AppColors.info,
                  ],
                  series: <CircularSeries>[
                    DoughnutSeries<Map<String, dynamic>, String>(
                      dataSource: chartData,
                      xValueMapper: (data, _) =>
                          data['type']?.toString() ?? 'Unknown',
                      yValueMapper: (data, _) =>
                          data['count'] as int, // Explicit cast ke int
                      dataLabelMapper: (data, _) =>
                          '${data['type']}\n${data['count']} jobs',
                      dataLabelSettings: const DataLabelSettings(
                        isVisible: true,
                        labelPosition: ChartDataLabelPosition.outside,
                        textStyle: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      radius: '70%',
                      innerRadius: '50%',
                    ),
                  ],
                  legend: Legend(
                    isVisible: true,
                    position: LegendPosition.bottom,
                    overflowMode: LegendItemOverflowMode.wrap,
                    textStyle: AppTextStyles.caption,
                  ),
                ),
              )
            else
              Container(
                height: 200,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart, size: 48, color: AppColors.disabled),
                    const SizedBox(height: 8),
                    Text(
                      'Tidak ada data pekerjaan\nbulan ini',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.disabled,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownAlert() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withAlpha(13),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withAlpha(76)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Perhatian: Unit Breakdown Menunggu RFU',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ada $pendingBreakdowns unit breakdown yang belum diupdate ke status RFU. Segera selesaikan untuk meningkatkan efisiensi.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoStatsAvailable() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.bar_chart, size: 48, color: AppColors.disabled),
            const SizedBox(height: 12),
            Text(
              'Belum Ada Data Statistik',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.disabled,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Statistik kinerja akan tersedia setelah Anda menyelesaikan beberapa pekerjaan.',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: AppTextStyles.headlineSmall.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
      ),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildPermissionItem(String permission, bool isGranted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isGranted ? Icons.check_circle : Icons.cancel,
            color: isGranted ? AppColors.success : AppColors.disabled,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              permission,
              style: AppTextStyles.bodySmall.copyWith(
                color: isGranted ? AppColors.textPrimary : AppColors.disabled,
                fontWeight: isGranted ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyActivitiesButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Container(
        // TAMBAHKAN: Gradient background
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primary.withAlpha(220)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(76),
              blurRadius: 16,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SingleUserActivityScreen(user: user),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            splashColor: Colors.white.withAlpha(76),
            highlightColor: Colors.white.withAlpha(38),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Row(
                children: [
                  // TAMBAHKAN: Animated icon container
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(204),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.assignment_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // TAMBAHKAN: Text content dengan subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TUGAS SAYA',
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kelola semua aktivitas & pekerjaan Anda',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withAlpha(204),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // TAMBAHKAN: Arrow icon
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white.withAlpha(204),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.logout, color: AppColors.error),
              SizedBox(width: 8),
              Text('Konfirmasi Logout'),
            ],
          ),
          content: Text(
            'Apakah Anda yakin ingin logout dari akun ${user.name}?',
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Batal',
                style: AppTextStyles.button.copyWith(color: AppColors.primary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performLogout(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Logout',
                style: AppTextStyles.button.copyWith(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _performLogout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Widget _buildChangePasswordSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.info.withAlpha(76)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _changePasswordFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'UBAH PASSWORD',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Untuk keamanan, masukkan password lama dan buat password baru',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.disabled,
                ),
              ),
              const SizedBox(height: 16),

              // Password Lama
              TextFormField(
                controller: _oldPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password Lama',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password lama harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Password Baru
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password Baru',
                  prefixIcon: Icon(Icons.lock_reset),
                  border: OutlineInputBorder(),
                ),
                validator: _validatePassword,
              ),
              const SizedBox(height: 12),

              // Konfirmasi Password Baru
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Konfirmasi Password Baru',
                  prefixIcon: Icon(Icons.lock_clock),
                  border: OutlineInputBorder(),
                ),
                validator: _validateConfirmPassword,
              ),
              const SizedBox(height: 16),

              // Tombol Aksi
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _changingPassword
                          ? null
                          : _toggleChangePasswordSection,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.disabled,
                        side: BorderSide(color: AppColors.disabled),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('BATAL'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _changingPassword ? null : _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.info,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _changingPassword
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('UBAH PASSWORD'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Getter untuk mengakses widget.user dengan mudah
  User get user => widget.user;
}
