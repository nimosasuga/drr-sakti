// lib/screens/update_job_screen.dart
import 'dart:io';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as excel;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/update_job.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../services/ad_service.dart';
import 'update_job_form.dart';
import 'update_job_detail_screen.dart';
import '../../constants/colors.dart';
import '../../constants/typography.dart';
import '../../widgets/custom_app_bar.dart';

class UpdateJobScreen extends StatefulWidget {
  final User user;
  final String? picFilterName;
  const UpdateJobScreen({super.key, required this.user, this.picFilterName});

  @override
  State<UpdateJobScreen> createState() => _UpdateJobScreenState();
}

class _UpdateJobScreenState extends State<UpdateJobScreen> {
  final ApiService api = ApiService();
  final AdService _adService = AdService();
  final TextEditingController _searchController = TextEditingController();

  List<UpdateJob> _allJobs = [];
  List<UpdateJob> _filteredJobs = [];
  bool _loading = false;
  String _searchQuery = '';
  String? _error;

  // Map untuk grouping by month
  Map<String, dynamic> _groupedJobs = {};
  // Set untuk track expanded/collapsed sections
  Set<String> _expandedMonths = {};
  bool get _isPicFilterActive => widget.picFilterName?.isNotEmpty == true;

  @override
  void initState() {
    super.initState();
    _loadJobs();
    _loadAds();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadAds() async {
    await _adService.loadInterstitialAd();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- LOGIKA FILTER & GROUPING ---

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query == _searchQuery) return;
    setState(() => _searchQuery = query);
    _applyFilter();
  }

  void _applyFilter() {
    final q = _searchQuery.toLowerCase();

    // ✅ TAMBAHKAN: Base list dengan filter PIC
    List<UpdateJob> baseList = _allJobs;
    if (_isPicFilterActive) {
      baseList = _allJobs
          .where(
            (job) =>
                job.pic?.toLowerCase() == widget.picFilterName!.toLowerCase(),
          )
          .toList();
    }

    if (q.isEmpty) {
      setState(() => _filteredJobs = List.from(baseList));
    } else {
      setState(() {
        _filteredJobs = baseList.where((j) {
          final serial = (j.serialNumber ?? '').toLowerCase();
          final customer = (j.customer ?? '').toLowerCase();
          final branch = (j.branch ?? '').toLowerCase();
          final status = (j.statusUnit ?? '').toLowerCase();
          final jobType = (j.jobType ?? '').toLowerCase();
          final pic = (j.pic ?? '').toLowerCase();

          return serial.contains(q) ||
              customer.contains(q) ||
              branch.contains(q) ||
              status.contains(q) ||
              jobType.contains(q) ||
              pic.contains(q);
        }).toList();
      });
    }
    _groupJobs();
  }

  void _groupJobs() {
    // Admin DRR/Super Admin memiliki canViewAllJobs = true
    final bool groupByBranch = widget.user.canViewAllJobs;

    if (groupByBranch) {
      // === LEVEL 1: GROUP BY BRANCH -> LEVEL 2: GROUP BY MONTH (Untuk Admin DRR) ===

      // Struktur Map: Map<BranchKey, Map<MonthKey, List<UpdateJob>>>
      final Map<String, Map<String, List<UpdateJob>>> groupedByBranch = {};

      // 1. Grouping
      for (final job in _filteredJobs) {
        final branchKey = job.branch?.toUpperCase() ?? 'UNKNOWN BRANCH';
        if (!groupedByBranch.containsKey(branchKey)) {
          groupedByBranch[branchKey] = {};
        }

        final monthKey = _getMonthKey(job.date ?? job.createdAt);
        if (!groupedByBranch[branchKey]!.containsKey(monthKey)) {
          groupedByBranch[branchKey]![monthKey] = [];
        }
        groupedByBranch[branchKey]![monthKey]!.add(job);
      }

      // 2. Sorting (Branches alphabetically, Months reverse chronological, Jobs reverse chronological)
      final sortedBranchKeys = groupedByBranch.keys.toList()..sort();

      final Map<String, dynamic> sortedMap = {};
      for (final branchKey in sortedBranchKeys) {
        final monthGroups = groupedByBranch[branchKey]!;

        // Sort Months (reverse chronological)
        final Map<String, DateTime> monthDates = {};
        for (final key in monthGroups.keys) {
          monthDates[key] = _parseMonthKeyToDate(key);
        }
        final sortedMonthKeys = monthGroups.keys.toList()
          ..sort((a, b) => monthDates[b]!.compareTo(monthDates[a]!));

        final Map<String, List<UpdateJob>> sortedMonthMap = {};
        for (final monthKey in sortedMonthKeys) {
          // Sort Jobs within the month (reverse chronological)
          monthGroups[monthKey]!.sort((a, b) {
            final dateA = _parseDate(a.date ?? a.createdAt);
            final dateB = _parseDate(b.date ?? b.createdAt);
            return dateB.compareTo(dateA);
          });
          sortedMonthMap[monthKey] = monthGroups[monthKey]!;
        }
        sortedMap[branchKey] = sortedMonthMap;
      }

      setState(() {
        _groupedJobs = sortedMap;
        if (_groupedJobs.isNotEmpty && _expandedMonths.isEmpty) {
          _expandedMonths = {_groupedJobs.keys.first};
        }
      });
    } else {
      // === SINGLE LEVEL: GROUP BY MONTH (Untuk User Cabang) ===
      final Map<String, List<UpdateJob>> grouped = {};

      // ... (Logika Grouping per Bulan yang sudah ada) ...
      for (final job in _filteredJobs) {
        final monthKey = _getMonthKey(job.date ?? job.createdAt);
        if (!grouped.containsKey(monthKey)) {
          grouped[monthKey] = [];
        }
        grouped[monthKey]!.add(job);
      }

      final Map<String, DateTime> monthDates = {};
      for (final key in grouped.keys) {
        monthDates[key] = _parseMonthKeyToDate(key);
      }

      final sortedKeys = grouped.keys.toList()
        ..sort((a, b) => monthDates[b]!.compareTo(monthDates[a]!));

      final Map<String, dynamic> sortedMap = {}; // Use dynamic for consistency
      for (final key in sortedKeys) {
        grouped[key]!.sort((a, b) {
          final dateA = _parseDate(a.date ?? a.createdAt);
          final dateB = _parseDate(b.date ?? b.createdAt);
          return dateB.compareTo(dateA);
        });
        sortedMap[key] = grouped[key]!;
      }

      setState(() {
        _groupedJobs = sortedMap;
        if (_groupedJobs.isNotEmpty && _expandedMonths.isEmpty) {
          _expandedMonths = {_groupedJobs.keys.first};
        }
      });
    }
  }

  // --- HELPERS DATE ---

  String _getMonthKey(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'Unknown Date';
    }
    try {
      final date = DateTime.parse(dateString);
      return '${_getMonthName(date.month)} ${date.year}';
    } catch (e) {
      return 'Unknown Date';
    }
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'Januari';
      case 2:
        return 'Februari';
      case 3:
        return 'Maret';
      case 4:
        return 'April';
      case 5:
        return 'Mei';
      case 6:
        return 'Juni';
      case 7:
        return 'Juli';
      case 8:
        return 'Agustus';
      case 9:
        return 'September';
      case 10:
        return 'Oktober';
      case 11:
        return 'November';
      case 12:
        return 'Desember';
      default:
        return 'Unknown';
    }
  }

  int _getMonthNumber(String monthName) {
    switch (monthName) {
      case 'Januari':
        return 1;
      case 'Februari':
        return 2;
      case 'Maret':
        return 3;
      case 'April':
        return 4;
      case 'Mei':
        return 5;
      case 'Juni':
        return 6;
      case 'Juli':
        return 7;
      case 'Agustus':
        return 8;
      case 'September':
        return 9;
      case 'Oktober':
        return 10;
      case 'November':
        return 11;
      case 'Desember':
        return 12;
      default:
        return 1;
    }
  }

  DateTime _parseMonthKeyToDate(String monthKey) {
    if (monthKey == 'Unknown Date') return DateTime(1970);
    try {
      final parts = monthKey.split(' ');
      final monthName = parts[0];
      final year = int.tryParse(parts[1]) ?? 1970;
      final month = _getMonthNumber(monthName);
      return DateTime(year, month, 1);
    } catch (e) {
      return DateTime(1970);
    }
  }

  DateTime _parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return DateTime(1970);
    }
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return DateTime(1970);
    }
  }

  void _toggleMonthExpansion(String monthKey) {
    setState(() {
      if (_expandedMonths.contains(monthKey)) {
        _expandedMonths.remove(monthKey);
      } else {
        _expandedMonths.add(monthKey);
      }
    });
  }

  // --- API LOAD ---

  Future<void> _loadJobs() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      List<UpdateJob> list;
      if (widget.user.canViewAllJobs) {
        list = await api.fetchUpdateJobs();
      } else {
        list = await api.fetchUpdateJobsByBranch(widget.user.branch);
      }

      // ✅ MODIFIKASI: Filter berdasarkan picFilterName jika aktif
      if (_isPicFilterActive) {
        list = list
            .where(
              (job) =>
                  job.pic?.toLowerCase() == widget.picFilterName!.toLowerCase(),
            )
            .toList();
      }

      if (!mounted) return;
      setState(() {
        _allJobs = list;
        _filteredJobs = List.from(list);
        _loading = false;
      });
      _applyFilter(); // ✅ Pastikan grouping dipanggil
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _allJobs = [];
        _filteredJobs = [];
        _groupedJobs = {};
        _loading = false;
      });
      _showSnackBar('Gagal memuat jobs: $e', AppColors.error);
    }
  }

  // --- EXPORT TO EXCEL ---

  bool get _canExport {
    final allowed = ['ADMIN DRR', 'KOORDINATOR', 'PLANNER'];
    return allowed.contains(widget.user.statusUser.toUpperCase());
  }

  Future<void> _exportToExcel() async {
    // 1. Tampilkan Iklan
    await _adService.initialize();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Menyiapkan file Excel...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      var excelFile = excel.Excel.createExcel();
      excel.Sheet sheet = excelFile['Update Jobs'];
      // Hapus default Sheet1 jika ada
      if (excelFile.sheets.containsKey('Sheet1')) {
        excelFile.delete('Sheet1');
      }
      // Header sesuai request
      List<String> headers = [
        'id',
        'branch',
        'status_mekanik',
        'pic',
        'partner',
        'in_time',
        'out_time',
        'vehicle',
        'nopol',
        'date',
        'serial_number',
        'unit_type',
        'year',
        'hour_meter',
        'nomor_lambung',
        'customer',
        'location',
        'job_type',
        'status_unit',
        'problem_date',
        'rfu_date',
        'lead_time_rfu',
        'pm',
        'rm',
        'problem',
        'action',
        'recommendations',
        'install_parts',
        'created_at',
        'updated_at',
      ];
      sheet.appendRow(headers.map((e) => excel.TextCellValue(e)).toList());

      // Data
      for (var j in _filteredJobs) {
        List<excel.CellValue> row = [
          excel.TextCellValue(j.id?.toString() ?? '-'),
          excel.TextCellValue(j.branch ?? '-'),
          excel.TextCellValue(j.statusMekanik ?? '-'),
          excel.TextCellValue(j.pic ?? '-'),
          excel.TextCellValue(j.partner ?? '-'),
          excel.TextCellValue(j.inTime ?? '-'),
          excel.TextCellValue(j.outTime ?? '-'),
          excel.TextCellValue(j.vehicle ?? '-'),
          excel.TextCellValue(j.nopol ?? '-'),
          excel.TextCellValue(j.date ?? '-'),
          excel.TextCellValue(j.serialNumber ?? '-'),
          excel.TextCellValue(j.unitType ?? '-'),
          excel.TextCellValue(j.year?.toString() ?? '-'),
          excel.TextCellValue(j.hourMeter?.toString() ?? '-'),
          excel.TextCellValue(j.nomorLambung ?? '-'),
          excel.TextCellValue(j.customer ?? '-'),
          excel.TextCellValue(j.location ?? '-'),
          excel.TextCellValue(_formatJobTypeString(j.jobType)),
          excel.TextCellValue(j.statusUnit ?? '-'),
          excel.TextCellValue(j.problemDate ?? '-'),
          excel.TextCellValue(j.rfuDate ?? '-'),
          excel.TextCellValue(j.leadTimeRfu ?? '-'),
          excel.TextCellValue((j.pm ?? '-').toString()),
          excel.TextCellValue((j.rm ?? '-').toString()),
          excel.TextCellValue((j.problem ?? '-').toString()),
          excel.TextCellValue((j.action ?? '-').toString()),
          excel.TextCellValue((j.recommendations ?? '-').toString()),
          excel.TextCellValue((j.installParts ?? '-').toString()),
          excel.TextCellValue(j.createdAt ?? '-'),
          excel.TextCellValue(j.updatedAt ?? '-'),
        ];
        sheet.appendRow(row);
      }

      final directory = await getTemporaryDirectory();
      final path =
          "${directory.path}/update_jobs_${DateTime.now().millisecondsSinceEpoch}.xlsx";
      final file = File(path);
      final fileBytes = excelFile.save();

      if (fileBytes != null) {
        await file.writeAsBytes(fileBytes);
        if (!mounted) return;

        // 🚀 PERBAIKAN: Menggunakan SharePlus.instance.share() dengan ShareParams
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(path)],
            subject: 'Export Update Jobs', // Mengganti parameter `text` lama
          ),
        );
      }
    } catch (e) {
      log('Error exporting excel: ${e.toString()}');
      // Baris 342
      _showSnackBar('Gagal export excel: ${e.toString()}', AppColors.error);
    }
  }

  String _formatJobTypeString(dynamic jobType) {
    if (jobType == null) return '-';
    if (jobType is List) return jobType.join(', ');
    return jobType.toString();
  }

  // --- BUILD UI ---

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  PreferredSizeWidget _buildAppBar() {
    return CustomAppBar(
      title: 'Update Jobs',
      bottom: SearchAppBarBottom(
        searchController: _searchController,
        hintText: 'Cari job, serial, customer, PIC...',
        itemCount: _filteredJobs.length,
        groupCount: _groupedJobs.length,
        onRefresh: _loadJobs,
        showGroupCount: true,
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    final statusData = _getStatusData(status ?? '');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusData.color.withAlpha(38),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusData.icon, size: 12, color: statusData.color),
          const SizedBox(width: 4),
          SelectableText(
            statusData.label,
            style: TextStyle(
              color: statusData.color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  ({String label, Color color, IconData icon}) _getStatusData(String status) {
    switch (status.toUpperCase()) {
      case 'RFU':
        return (label: 'RFU', color: AppColors.rfu, icon: Icons.check_circle);
      case 'BREAKDOWN':
        return (
          label: 'BREAKDOWN',
          color: AppColors.breakdown,
          icon: Icons.error,
        );
      case 'MONITORING':
        return (
          label: 'MONITORING',
          color: AppColors.monitoring,
          icon: Icons.remove_red_eye,
        );
      case 'WAITING PART':
        return (
          label: 'WAITING PART',
          color: AppColors.waitingPart,
          icon: Icons.schedule,
        );
      default:
        return (label: 'UNKNOWN', color: AppColors.disabled, icon: Icons.help);
    }
  }

  // --- BUILD SECTION UNTUK BULAN (LEVEL 2 / SINGLE LEVEL) ---
  Widget _buildMonthSection(
    String monthKey,
    List<UpdateJob> jobs, {
    bool isNested = false,
  }) {
    final isExpanded = _expandedMonths.contains(monthKey);
    final jobCount = jobs.length;

    // Icon dan Warna untuk Bulan
    final IconData icon = Icons.calendar_month;
    final Color iconColor = AppColors.primary;
    final double horizontalPadding = isNested ? 8.0 : 16.0;

    return Padding(
      padding: EdgeInsets.only(
        left: isNested ? 16.0 : 0.0,
      ), // Padding jika bersarang
      child: Card(
        margin: EdgeInsets.symmetric(
          vertical: 4,
          horizontal: horizontalPadding,
        ),
        elevation: isNested ? 1 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            InkWell(
              onTap: () => _toggleMonthExpansion(monthKey),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: iconColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            monthKey,
                            style: AppTextStyles.headlineSmall.copyWith(
                              fontWeight: isNested
                                  ? FontWeight.w600
                                  : FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            '$jobCount job${jobCount > 1 ? 's' : ''}',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
            if (isExpanded) ...[
              const Divider(height: 1),
              ...jobs.map((job) => _buildJobCard(job)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildJobCard(UpdateJob job) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: InkWell(
        onTap: () => _navigateToDetail(job),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getJobIcon(job.jobType),
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      job.serialNumber?.isNotEmpty == true
                          ? job.serialNumber!
                          : (job.customer?.isNotEmpty == true
                                ? job.customer!
                                : '-'),
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      job.customer ?? '-',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.person,
                          size: 12,
                          color: AppColors.disabled,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: SelectableText(
                            job.pic ?? '-',
                            style: AppTextStyles.caption,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildStatusBadge(job.statusUnit),
                        const Spacer(),
                        SelectableText(
                          _formatDate(job.date ?? job.createdAt),
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  IconData _getJobIcon(String? jobType) {
    if (jobType?.toLowerCase().contains('preventive') ?? false) {
      return Icons.medical_services;
    } else if (jobType?.toLowerCase().contains('install') ?? false) {
      return Icons.build;
    } else if (jobType?.toLowerCase().contains('repair') ?? false) {
      return Icons.handyman;
    } else if (jobType?.toLowerCase().contains('troubleshoot') ?? false) {
      return Icons.search;
    }
    return Icons.work;
  }

  void _navigateToDetail(UpdateJob job) async {
    if (!widget.user.canAccessJob(job)) {
      _showSnackBar('Tidak memiliki akses ke data ini', AppColors.error);
      return;
    }

    final currentExpandedMonths = Set<String>.from(_expandedMonths);

    final changed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UpdateJobDetailScreen(job: job, user: widget.user),
      ),
    );

    if (mounted) {
      setState(() {
        _expandedMonths = currentExpandedMonths;
      });
    }

    if (changed == true) {
      _loadJobs();
    }
  }

  void _navigateToCreate() async {
    final currentExpandedMonths = Set<String>.from(_expandedMonths);

    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UpdateJobForm(user: widget.user)),
    );

    if (mounted) {
      setState(() {
        _expandedMonths = currentExpandedMonths;
      });
    }

    if (created == true) {
      _loadJobs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_canExport) ...[
            FloatingActionButton(
              heroTag: 'export_jobs',
              onPressed: _exportToExcel,
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              tooltip: 'Export Excel',
              child: const Icon(Icons.file_download),
            ),
            const SizedBox(height: 16),
          ],
          if (widget.user.canCreateJob)
            FloatingActionButton(
              heroTag: 'create_job',
              onPressed: _navigateToCreate,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            SelectableText(
              'Memuat data jobs...',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            SelectableText('Error: $_error', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadJobs,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_filteredJobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.work_outline, size: 64, color: AppColors.disabled),
            const SizedBox(height: 16),
            SelectableText(
              _searchQuery.isEmpty
                  ? 'Tidak ada data jobs'
                  : 'Tidak ada hasil pencarian',
              style: AppTextStyles.bodyLarge,
            ),
            if (_searchQuery.isEmpty && widget.user.canCreateJob) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _navigateToCreate,
                child: const Text('Buat Job Pertama'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadJobs(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _groupedJobs.length,
        itemBuilder: (context, index) {
          final groupKey = _groupedJobs.keys.elementAt(index);
          final groupValue = _groupedJobs[groupKey];

          // Cek apakah ini mode bersarang (Admin DRR)
          final bool isBranchGrouping =
              widget.user.canViewAllJobs && groupValue is Map;

          if (isBranchGrouping) {
            // Level 1: Branch Grouping (Admin DRR)
            return _buildBranchSection(
              groupKey,
              groupValue as Map<String, List<UpdateJob>>,
            );
          } else {
            // Single Level: Month Grouping (User Cabang)
            return _buildMonthSection(groupKey, groupValue as List<UpdateJob>);
          }
        },
      ),
    );
  }

  // --- BUILD SECTION UNTUK BRANCH (LEVEL 1) ---
  Widget _buildBranchSection(
    String branchKey,
    Map<String, List<UpdateJob>> monthGroups,
  ) {
    final isExpanded = _expandedMonths.contains(branchKey);
    final jobCount = monthGroups.values.fold<int>(
      0,
      (sum, list) => sum + list.length,
    );

    // Header Branch
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 4, // Sedikit lebih menonjol
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleMonthExpansion(branchKey),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.location_city_rounded,
                      color: AppColors.warning,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(
                          'BRANCH: $branchKey',
                          style: AppTextStyles.headlineSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.warning,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          '$jobCount total job${jobCount > 1 ? 's' : ''} in branch',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            // LEVEL 2: Nested Month Groups
            ...monthGroups.keys.map((monthKey) {
              // Panggil fungsi pembangun bulan
              return _buildMonthSection(
                monthKey,
                monthGroups[monthKey]!,
                isNested: true,
              );
            }),
          ],
        ],
      ),
    );
  }
}
