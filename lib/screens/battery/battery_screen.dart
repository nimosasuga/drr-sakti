// lib/screens/battery/battery_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;

// Packages External
import 'package:excel/excel.dart' as excel;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' as share_plus;
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../models/battery.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../constants/colors.dart';
import '../../constants/typography.dart';
import 'battery_detail_screen.dart';
import 'battery_form.dart';
import '../../widgets/custom_app_bar.dart';

class BatteryScreen extends StatefulWidget {
  final User user;
  final String? picFilterName;
  const BatteryScreen({super.key, required this.user, this.picFilterName});

  @override
  State<BatteryScreen> createState() => _BatteryScreenState();
}

class _BatteryScreenState extends State<BatteryScreen> {
  final ApiService api = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Battery> _allBattery = [];
  List<Battery> _filteredBattery = [];
  bool _loading = false;
  String _searchQuery = '';
  String? _error;

  Map<String, List<Battery>> _groupedBattery = {};
  Set<String> _expandedMonths = {};
  bool get _isPicFilterActive => widget.picFilterName?.isNotEmpty == true;

  // --- VARIABEL ADMOB ---
  RewardedAd? _rewardedAd;
  final String _adUnitId = 'ca-app-pub-3940256099942544/5224354917';
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBattery();
    _searchController.addListener(_onSearchChanged);
    _loadRewardedAd();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  // --- LOGIKA ADMOB ---
  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          developer.log('✅ Iklan AdMob Berhasil Dimuat');
          setState(() {
            _rewardedAd = ad;
            _isAdLoaded = true;
          });

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              developer.log('Iklan ditutup');
              ad.dispose();
              _loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              developer.log('Gagal menampilkan iklan: $err');
              ad.dispose();
              _loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (err) {
          developer.log('❌ Gagal memuat iklan: $err');
          setState(() {
            _isAdLoaded = false;
          });
        },
      ),
    );
  }

  void _showAdAndExport() {
    if (_rewardedAd != null && _isAdLoaded) {
      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem rewardItem) {
          developer.log('🎁 User mendapat reward: Export Excel dijalankan');
          _exportToExcel();
        },
      );
    } else {
      developer.log('⚠️ Iklan belum siap, langsung export');
      _exportToExcel();
      _loadRewardedAd();
    }
  }

  // --- LOGIKA EXCEL ---
  bool get _canExport {
    final allowed = ['ADMIN DRR', 'KOORDINATOR', 'PLANNER'];
    return allowed.contains(widget.user.statusUser.toUpperCase());
  }

  // ✅ FUNGSI FORMAT JOB TYPE
  String _formatJobType(dynamic jobType) {
    if (jobType == null) return '-';

    String val = jobType.toString();
    if (val.trim().isEmpty) return '-';

    // Bersihkan karakter aneh
    String clean = val
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .trim();

    if (clean.isEmpty) return '-';

    // Split dan join ulang agar rapi
    try {
      final items = clean
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      if (items.isEmpty) return '-';
      return items.join(', ');
    } catch (e) {
      return clean;
    }
  }

  Future<void> _exportToExcel() async {
    setState(() => _loading = true);
    try {
      var excelFile = excel.Excel.createExcel();
      excel.Sheet sheet = excelFile['BatteryData'];

      List<String> headers = [
        'category_job',
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
        'sn_battery',
        'battery_type',
        'battery_year',
        'customer',
        'location',
        'serial_number',
        'unit_type',
        'job_type',
        'status_unit',
        'problem_date',
        'rfu_date',
        'problem',
        'action',
        'recommendations',
        'install_parts',
        'created_at',
        'updated_at',
      ];

      // Menggunakan TextCellValue untuk setiap header
      sheet.appendRow(headers.map((e) => excel.TextCellValue(e)).toList());

      for (var item in _filteredBattery) {
        // PERHATIAN: Penggunaan `as dynamic` ini tidak disarankan jika Anda memiliki model data.
        // Lebih baik menggunakan tipe data yang spesifik untuk `item` jika memungkinkan.
        // Namun, untuk perbaikan saat ini, kita biarkan saja.
        final d = item as dynamic;
        List<excel.CellValue> row = [
          excel.TextCellValue(item.categoryJob ?? '-'),
          excel.TextCellValue(item.id?.toString() ?? '-'),
          excel.TextCellValue(item.branch ?? '-'),
          excel.TextCellValue(d.statusMekanik?.toString() ?? '-'),
          excel.TextCellValue(item.pic ?? '-'),
          excel.TextCellValue(d.partner?.toString() ?? '-'),
          excel.TextCellValue(d.inTime?.toString() ?? '-'),
          excel.TextCellValue(d.outTime?.toString() ?? '-'),
          excel.TextCellValue(d.vehicle?.toString() ?? '-'),
          excel.TextCellValue(d.nopol?.toString() ?? '-'),
          excel.TextCellValue(item.date ?? '-'),
          excel.TextCellValue(d.snBattery?.toString() ?? '-'),
          excel.TextCellValue(d.batteryType?.toString() ?? '-'),
          excel.TextCellValue(d.batteryYear?.toString() ?? '-'),
          excel.TextCellValue(item.customer ?? '-'),
          excel.TextCellValue(d.location?.toString() ?? '-'),
          excel.TextCellValue(item.serialNumber ?? '-'),
          excel.TextCellValue(d.unitType?.toString() ?? '-'),
          excel.TextCellValue(_formatJobType(item.jobType)),
          excel.TextCellValue(item.statusUnit ?? '-'),
          excel.TextCellValue(d.problemDate?.toString() ?? '-'),
          excel.TextCellValue(d.rfuDate?.toString() ?? '-'),
          excel.TextCellValue(d.problem?.toString() ?? '-'),
          excel.TextCellValue(d.action?.toString() ?? '-'),
          excel.TextCellValue(d.recommendations?.toString() ?? '-'),
          excel.TextCellValue(d.installParts?.toString() ?? '-'),
          excel.TextCellValue(item.createdAt ?? '-'),
          excel.TextCellValue(d.updatedAt?.toString() ?? '-'),
        ];
        sheet.appendRow(row);
      }

      // Mengganti fileBytes.cast<int>() dengan fileBytes
      var fileBytes = excelFile.save();
      var directory = await getTemporaryDirectory();
      String fileName =
          'Battery_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      File file = File('${directory.path}/$fileName');

      if (fileBytes != null) {
        // File.writeAsBytes menerima List<int>, tidak perlu cast jika `save()` sudah mengembalikan List<int>
        await file.writeAsBytes(fileBytes);

        // 🚀 Perbaikan Utama: Hapus parameter `body`
        final result = await share_plus.SharePlus.instance.share(
          share_plus.ShareParams(
            files: [
              share_plus.XFile(
                file.path,
                mimeType:
                    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
              ),
            ],
            // Menggabungkan subjek dan detail ke dalam `subject`
            subject: 'Export Data Battery - ${widget.user.branch}',
          ),
        );

        // Optional: Handle result
        if (result.status == share_plus.ShareResultStatus.success) {
          _showSnackBar('File berhasil dibagikan', AppColors.success);
        }
      }
    } catch (e) {
      _showSnackBar('Gagal export Excel: $e', AppColors.error);
    } finally {
      setState(() => _loading = false);
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query == _searchQuery) return;
    setState(() => _searchQuery = query);
    _applyFilter();
  }

  void _groupBatteryByMonth() {
    final Map<String, List<Battery>> grouped = {};

    for (final battery in _filteredBattery) {
      final monthKey = _getMonthKey(battery.date ?? battery.createdAt);
      if (!grouped.containsKey(monthKey)) {
        grouped[monthKey] = [];
      }
      grouped[monthKey]!.add(battery);
    }

    final Map<String, DateTime> monthDates = {};
    for (final key in grouped.keys) {
      monthDates[key] = _parseMonthKeyToDate(key);
    }

    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => monthDates[b]!.compareTo(monthDates[a]!));

    final sortedMap = <String, List<Battery>>{};
    for (final key in sortedKeys) {
      grouped[key]!.sort((a, b) {
        final dateA = _parseDate(a.date ?? a.createdAt);
        final dateB = _parseDate(b.date ?? b.createdAt);
        return dateB.compareTo(dateA);
      });
      sortedMap[key] = grouped[key]!;
    }

    setState(() {
      _groupedBattery = sortedMap;
      if (_groupedBattery.isNotEmpty && _expandedMonths.isEmpty) {
        _expandedMonths = {_groupedBattery.keys.first};
      }
    });
  }

  String _getMonthKey(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Unknown Date';
    try {
      final date = DateTime.parse(dateString);
      return '${_getMonthName(date.month)} ${date.year}';
    } catch (e) {
      return 'Unknown Date';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return month >= 1 && month <= 12 ? months[month - 1] : 'Unknown';
  }

  int _getMonthNumber(String monthName) {
    const months = {
      'Januari': 1,
      'Februari': 2,
      'Maret': 3,
      'April': 4,
      'Mei': 5,
      'Juni': 6,
      'Juli': 7,
      'Agustus': 8,
      'September': 9,
      'Oktober': 10,
      'November': 11,
      'Desember': 12,
    };
    return months[monthName] ?? 1;
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
    if (dateString == null || dateString.isEmpty) return DateTime(1970);
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

  Future<void> _loadBattery() async {
    // ✅ FIX 1: SET LOADING TRUE DI AWAL
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final fetchedBattery = await api.fetchBatteryByBranch(widget.user.branch);

      List<Battery> finalBattery = fetchedBattery;

      // ✅ FIX 2: Filter PIC jika aktif
      if (_isPicFilterActive) {
        final String finalPicName = widget.picFilterName!.trim().toLowerCase();

        finalBattery = fetchedBattery
            .where((b) => b.pic?.trim().toLowerCase() == finalPicName)
            .toList();
      }

      if (!mounted) return;

      setState(() {
        _allBattery = finalBattery;
        _filteredBattery = finalBattery;
        _loading = false; // ✅ SET FALSE SETELAH BERHASIL
      });

      // ✅ FIX 3: PANGGIL GROUPING SETELAH DATA DISET
      _groupBatteryByMonth();
    } catch (e) {
      developer.log('⚠️ Error loading battery: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _allBattery = [];
        _filteredBattery = [];
        _groupedBattery = {};
        _loading = false; // ✅ SET FALSE SAAT ERROR
      });
      _showSnackBar('Gagal memuat battery: $e', AppColors.error);
    }
  }

  // ✅ FIX 4: Update _applyFilter untuk konsisten dengan filter PIC
  void _applyFilter() {
    final q = _searchQuery.toLowerCase();

    // Base list dengan filter PIC
    List<Battery> baseList = _allBattery;
    if (_isPicFilterActive) {
      baseList = _allBattery
          .where(
            (b) => b.pic?.toLowerCase() == widget.picFilterName!.toLowerCase(),
          )
          .toList();
    }

    if (q.isEmpty) {
      setState(() => _filteredBattery = List.from(baseList));
    } else {
      setState(() {
        _filteredBattery = baseList.where((b) {
          final serial = (b.serialNumber ?? '').toLowerCase();
          final customer = (b.customer ?? '').toLowerCase();
          final branch = (b.branch ?? '').toLowerCase();
          final status = (b.statusUnit ?? '').toLowerCase();
          final pic = (b.pic ?? '').toLowerCase();
          final category = (b.categoryJob ?? '').toLowerCase();

          return serial.contains(q) ||
              customer.contains(q) ||
              branch.contains(q) ||
              status.contains(q) ||
              pic.contains(q) ||
              category.contains(q);
        }).toList();
      });
    }
    _groupBatteryByMonth();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  PreferredSizeWidget _buildAppBar() {
    return CustomAppBar(
      title: '🔋 Battery Management',
      subtitle: '${widget.user.name} • ${widget.user.branch}',
      bottom: SearchAppBarBottom(
        searchController: _searchController,
        hintText: 'Cari serial, customer, category...',
        itemCount: _filteredBattery.length,
        groupCount: _groupedBattery.length,
        onRefresh: _loadBattery,
        showGroupCount: true,
      ),
    );
  }

  // === COLOR HELPERS ===
  Color _getJobTypeColor(String jobType) {
    final lower = jobType.toLowerCase();
    if (lower.contains('troubleshooting')) return Colors.orange;
    if (lower.contains('install')) return Colors.blue;
    if (lower.contains('repair')) return Colors.green;
    if (lower.contains('peremajaan')) {
      return Colors.purple;
    } // Tambahan untuk battery
    return Colors.grey;
  }

  // === WIDGET CHIP KECIL UNTUK LIST ===
  Widget _buildJobTypeChipSmall(String jobTypeString) {
    if (jobTypeString.isEmpty || jobTypeString == '-') {
      return const SizedBox.shrink();
    }

    // Ambil hanya job type pertama untuk tampilan compact di list
    final firstJobType = jobTypeString.split(',').first.trim();
    final color = _getJobTypeColor(firstJobType);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        firstJobType,
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.w500,
        ),
        overflow: TextOverflow.ellipsis, // ✅ TAMBAHKAN INI
        maxLines: 1, // ✅ TAMBAHKAN INI
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
      default:
        return (
          label: status.toUpperCase(),
          color: AppColors.disabled,
          icon: Icons.help,
        );
    }
  }

  Widget _buildMonthSection(String monthKey, List<Battery> batteryList) {
    final isExpanded = _expandedMonths.contains(monthKey);
    final count = batteryList.length;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
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
                      color: AppColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calendar_month,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(
                          monthKey,
                          style: AppTextStyles.headlineSmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          '$count battery record${count > 1 ? 's' : ''}',
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
            ...batteryList.map((b) => _buildBatteryCard(b)),
          ],
        ],
      ),
    );
  }

  Widget _buildBatteryCard(Battery battery) {
    // 🔍 Mengambil job type yang sudah diformat bersih
    final formattedJobType = _formatJobType(battery.jobType);

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: InkWell(
        onTap: () => _navigateToDetail(battery),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.battery_charging_full,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      battery.customer ?? 'Battery',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (battery.serialNumber != null &&
                        battery.serialNumber!.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.tag,
                            size: 12,
                            color: AppColors.disabled,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: SelectableText(
                              battery.serialNumber!,
                              style: AppTextStyles.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
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
                            battery.pic ?? '-',
                            style: AppTextStyles.caption,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // BAGIAN KIRI: Status + Job Type (Bungkus Expanded agar mengisi ruang sisa)
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildStatusBadge(battery.statusUnit),
                              const SizedBox(width: 8),

                              // Chip Job Type (Bungkus Flexible agar bisa mengecil jika mentok)
                              if (formattedJobType != '-')
                                Flexible(
                                  child: _buildJobTypeChipSmall(
                                    formattedJobType,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // BAGIAN KANAN: Tanggal (Tetap ukurannya)
                        const SizedBox(width: 8),
                        SelectableText(
                          _formatDate(battery.date ?? battery.createdAt),
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

  void _navigateToDetail(Battery battery) async {
    final currentExpandedMonths = Set<String>.from(_expandedMonths);
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            BatteryDetailScreen(battery: battery, user: widget.user),
      ),
    );
    if (mounted) setState(() => _expandedMonths = currentExpandedMonths);
    if (changed == true) _loadBattery();
  }

  void _navigateToCreate() async {
    final currentExpandedMonths = Set<String>.from(_expandedMonths);
    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BatteryForm(user: widget.user)),
    );
    if (mounted) setState(() => _expandedMonths = currentExpandedMonths);
    if (created == true) _loadBattery();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_canExport) ...[
            FloatingActionButton(
              heroTag: "btnExcelBattery",
              onPressed: _showAdAndExport,
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              tooltip: 'Download Excel (Tonton Iklan)',
              child: const Icon(Icons.file_download),
            ),
            const SizedBox(height: 16),
          ],
          if (widget.user.canCreateJob)
            FloatingActionButton(
              heroTag: "btnCreateBattery",
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
              'Memuat data battery...',
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
              onPressed: _loadBattery,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_filteredBattery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.battery_alert,
              size: 64,
              color: AppColors.disabled,
            ),
            const SizedBox(height: 16),
            SelectableText(
              _searchQuery.isEmpty
                  ? 'Tidak ada data battery'
                  : 'Tidak ada hasil pencarian',
              style: AppTextStyles.bodyLarge,
            ),
            if (_searchQuery.isEmpty && widget.user.canCreateJob) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _navigateToCreate,
                child: const Text('Tambah Battery Pertama'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadBattery(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _groupedBattery.length,
        itemBuilder: (context, index) {
          final monthKey = _groupedBattery.keys.elementAt(index);
          final batteryList = _groupedBattery[monthKey]!;
          return _buildMonthSection(monthKey, batteryList);
        },
      ),
    );
  }
}
