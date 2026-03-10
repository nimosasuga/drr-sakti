// lib/screens/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:excel/excel.dart' hide Border;
import '../models/user.dart';
import '../models/update_job.dart';
import '../models/unit.dart';
import '../services/api_service.dart';
import '../constants/colors.dart';
import '../constants/typography.dart';

class AdminDashboardScreen extends StatefulWidget {
  final User user;
  const AdminDashboardScreen({super.key, required this.user});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  // Data Variables
  List<UpdateJob> _allJobs = [];
  List<Unit> _allUnits = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Filter UI
  String _unitFilterStatus = 'all'; // Options: all, done, not_done

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ==========================================
  // PERBAIKAN LOGIKA LOAD DATA DI SINI
  // ==========================================
  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Cek apakah user adalah Super Admin ATAU orang HO (Head Office)
      // Biasanya HO dianggap pusat yang bisa melihat semua data
      bool isAdminOrHO =
          widget.user.isSuperAdmin || widget.user.branch.toUpperCase() == 'HO';

      if (isAdminOrHO) {
        // === LOGIKA UNTUK SUPER ADMIN / HO ===
        // Ambil SEMUA data (Global)
        final jobs = await _apiService.fetchUpdateJobs();
        final units = await _apiService.fetchUnits();

        if (mounted) {
          setState(() {
            _allJobs = jobs;
            _allUnits = units;
          });
        }
      } else {
        // === LOGIKA UNTUK CABANG ===
        // Ambil data SPESIFIK Branch user
        final jobs = await _apiService.fetchUpdateJobsByBranch(
          widget.user.branch,
        );
        final units = await _apiService.fetchUnitsByBranch(widget.user.branch);

        if (mounted) {
          setState(() {
            _allJobs = jobs;
            _allUnits = units;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- LOGIC STATISTIK & DATA PROCESSING ---

  // Get PM statistics by month
  Map<String, PMStats> _getPMStatsByMonth() {
    Map<String, PMStats> stats = {};

    for (var job in _allJobs) {
      if (job.date == null) continue;

      // Filter: Hanya ambil job tipe 'PREVENTIVE' (case insensitive)
      if (job.jobType == null ||
          !job.jobType!.toUpperCase().contains('PREVENTIVE')) {
        continue;
      }

      // Key format: yyyy-MM (Contoh: 2023-11)
      String monthKey = job.date!.length >= 7
          ? job.date!.substring(0, 7)
          : job.date!;

      if (!stats.containsKey(monthKey)) {
        stats[monthKey] = PMStats(month: monthKey, done: 0, notDone: 0);
      }

      // Cek flag PM (boolean)
      if (job.pm == true) {
        stats[monthKey]!.done++;
      } else {
        // Ini jarang terjadi di update_job karena biasanya tercatat kalau sudah dikerjakan
        // Tapi kita simpan untuk jaga-jaga
        stats[monthKey]!.notDone++;
      }
    }

    return stats;
  }

  // Get total PM stats (Comparing Asset Database vs Job History)
  PMStats _getTotalPMStats() {
    // 1. Kumpulkan semua Serial Number Unit yang ada di database (Asset Master)
    Set<String> allUnitSerials = {};
    for (var unit in _allUnits) {
      if (unit.serialNumber != null && unit.serialNumber!.isNotEmpty) {
        allUnitSerials.add(unit.serialNumber!);
      }
    }

    // 2. Kumpulkan Serial Number yang SUDAH di-PM berdasarkan history Jobs
    Set<String> pmDoneSerials = {};
    for (var job in _allJobs) {
      // Filter: Hanya Preventive
      if (job.jobType?.toUpperCase().contains('PREVENTIVE') != true) continue;

      // Jika job ini status PM-nya true, catat serial numbernya
      if (job.pm == true &&
          job.serialNumber != null &&
          job.serialNumber!.isNotEmpty) {
        pmDoneSerials.add(job.serialNumber!);
      }
    }

    // 3. Hitung Statistik
    // Unit yang sudah PM = Jumlah serial unik di job history
    // Unit yang belum PM = Total Unit di Master - Unit yang sudah PM
    int done = pmDoneSerials.length;

    // Cegah nilai negatif jika data tidak sinkron
    int totalAssets = allUnitSerials.length;
    int notDone = (totalAssets > done) ? (totalAssets - done) : 0;

    return PMStats(month: 'Total', done: done, notDone: notDone);
  }

  // Filter list unit untuk Tab "Unit List"
  List<Unit> _getFilteredUnits() {
    // Ambil daftar SN yang sudah PM
    Set<String> pmDoneSerials = {};
    for (var job in _allJobs) {
      if (job.jobType?.toUpperCase().contains('PREVENTIVE') == true &&
          job.pm == true &&
          job.serialNumber != null) {
        pmDoneSerials.add(job.serialNumber!);
      }
    }

    return _allUnits.where((unit) {
      if (unit.serialNumber == null) return false;

      bool hasPM = pmDoneSerials.contains(unit.serialNumber);

      if (_unitFilterStatus == 'all') return true;
      if (_unitFilterStatus == 'done') return hasPM;
      if (_unitFilterStatus == 'not_done') return !hasPM;

      return true;
    }).toList();
  }

  // --- BUILD UI METHODS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin Dashboard',
              style: TextStyle(color: Colors.white),
            ),
            Text(
              widget.user.isSuperAdmin
                  ? 'Global Access'
                  : 'Branch: ${widget.user.branch}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart), text: 'Statistik'),
            Tab(icon: Icon(Icons.list), text: 'Unit List'),
            Tab(icon: Icon(Icons.download), text: 'Download'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildError()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildStatisticsTab(),
                _buildUnitListTab(),
                _buildDownloadTab(),
              ],
            ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Gagal Memuat Data', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Terjadi kesalahan yang tidak diketahui',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TAB 1: STATISTICS
  Widget _buildStatisticsTab() {
    if (_allUnits.isEmpty && _allJobs.isEmpty) {
      return const Center(child: Text('Belum ada data unit atau pekerjaan.'));
    }

    final pmStatsByMonth = _getPMStatsByMonth();
    final totalStats = _getTotalPMStats();

    List<PMStats> monthlyData = pmStatsByMonth.values.toList();
    monthlyData.sort((a, b) => a.month.compareTo(b.month));

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTotalStatsCard(totalStats),
            const SizedBox(height: 24),

            Text('Status PM (Total)', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 16),
            _buildDoughnutChart(totalStats),
            const SizedBox(height: 24),

            Text('Riwayat PM per Bulan', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 16),
            _buildMonthlyBarChart(monthlyData),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalStatsCard(PMStats stats) {
    int total = stats.done + stats.notDone; // Total Unit di Database
    double percentage = total > 0 ? (stats.done / total * 100) : 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Progress Preventive Maintenance',
              style: AppTextStyles.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Sudah PM',
                  stats.done.toString(),
                  AppColors.success,
                ),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                _buildStatItem(
                  'Belum PM',
                  stats.notDone.toString(),
                  AppColors.error,
                ),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                _buildStatItem('Total Unit', total.toString(), AppColors.info),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: total > 0 ? percentage / 100 : 0,
                backgroundColor: AppColors.error.withAlpha(50),
                valueColor: AlwaysStoppedAnimation<Color>(
                  percentage > 80
                      ? AppColors.success
                      : percentage > 50
                      ? Colors.orange
                      : AppColors.error,
                ),
                minHeight: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${percentage.toStringAsFixed(1)}% Completed',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildDoughnutChart(PMStats stats) {
    final List<ChartData> chartData = [
      ChartData('Sudah PM', stats.done.toDouble(), AppColors.success),
      ChartData('Belum PM', stats.notDone.toDouble(), AppColors.error),
    ];

    return SizedBox(
      height: 250,
      child: SfCircularChart(
        legend: Legend(isVisible: true, position: LegendPosition.bottom),
        series: <CircularSeries>[
          DoughnutSeries<ChartData, String>(
            dataSource: chartData,
            xValueMapper: (ChartData data, _) => data.x,
            yValueMapper: (ChartData data, _) => data.y,
            pointColorMapper: (ChartData data, _) => data.color,
            dataLabelSettings: const DataLabelSettings(
              isVisible: true,
              labelPosition: ChartDataLabelPosition.outside,
              textStyle: TextStyle(fontWeight: FontWeight.bold),
            ),
            enableTooltip: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyBarChart(List<PMStats> monthlyData) {
    // Tampilkan 6 bulan terakhir saja agar tidak penuh
    List<PMStats> recentData = monthlyData.length > 6
        ? monthlyData.sublist(monthlyData.length - 6)
        : monthlyData;

    if (recentData.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(child: Text("Belum ada data bulanan")),
      );
    }

    return SizedBox(
      height: 300,
      child: SfCartesianChart(
        primaryXAxis: CategoryAxis(),
        legend: Legend(isVisible: true, position: LegendPosition.bottom),
        tooltipBehavior: TooltipBehavior(enable: true),
        series: <CartesianSeries<PMStats, String>>[
          ColumnSeries<PMStats, String>(
            name: 'Sudah PM',
            dataSource: recentData,
            xValueMapper: (PMStats stats, _) => _formatMonth(stats.month),
            yValueMapper: (PMStats stats, _) => stats.done,
            color: AppColors.success,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      ),
    );
  }

  String _formatMonth(String monthStr) {
    try {
      // Input: yyyy-MM
      DateTime date = DateTime.parse('$monthStr-01');
      return DateFormat('MMM yy').format(date);
    } catch (e) {
      return monthStr;
    }
  }

  // TAB 2: UNIT LIST
  Widget _buildUnitListTab() {
    final filteredUnits = _getFilteredUnits();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.grey[50],
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Semua', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Sudah PM', 'done'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Belum PM', 'not_done'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey[200],
          child: Text(
            'Menampilkan ${filteredUnits.length} Unit',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: filteredUnits.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Tidak ada unit yang cocok dengan filter'),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredUnits.length,
                    padding: const EdgeInsets.all(12),
                    itemBuilder: (context, index) {
                      return _buildUnitCard(filteredUnits[index]);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    bool isSelected = _unitFilterStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _unitFilterStatus = value;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: AppColors.primary.withAlpha(50),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildUnitCard(Unit unit) {
    // Cek status PM berdasarkan job list yang sudah diload
    bool hasPM = _allJobs.any(
      (job) =>
          job.serialNumber == unit.serialNumber &&
          job.jobType?.toUpperCase().contains('PREVENTIVE') == true &&
          job.pm == true,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: hasPM
                ? AppColors.success.withAlpha(30)
                : AppColors.error.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            hasPM ? Icons.check_circle : Icons.warning,
            color: hasPM ? AppColors.success : AppColors.error,
          ),
        ),
        title: Text(
          unit.serialNumber ?? 'No Serial',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${unit.unitType ?? '-'} • ${unit.customer ?? '-'}'),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Branch: ${unit.branch ?? '-'}',
                style: const TextStyle(fontSize: 10, color: Colors.black54),
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              hasPM ? 'Sudah PM' : 'Belum PM',
              style: TextStyle(
                color: hasPM ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TAB 3: DOWNLOAD
  Widget _buildDownloadTab() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.table_view, size: 80, color: AppColors.primary),
            const SizedBox(height: 24),
            Text('Export Data ke Excel', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 16),
            const Text(
              'Unduh data Update Jobs lengkap beserta statusnya dalam format .xlsx',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                children: [
                  _buildInfoRow('Branch', widget.user.branch),
                  const Divider(),
                  _buildInfoRow('Total Records', '${_allJobs.length} Jobs'),
                  const Divider(),
                  _buildInfoRow(
                    'Status Akses',
                    widget.user.isSuperAdmin
                        ? 'Super Admin (All Data)'
                        : 'Branch User',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _allJobs.isEmpty ? null : _downloadExcel,
                icon: const Icon(Icons.download),
                label: const Text('DOWNLOAD EXCEL'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _downloadExcel() async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sedang membuat file Excel...')),
        );
      }

      final Directory directory = await getApplicationDocumentsDirectory();
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Update Jobs'];

      // Style Header
      CellStyle headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString(
          "#1976D2",
        ), // AppColors.primary
        fontColorHex: ExcelColor.fromHexString("#FFFFFF"),
        horizontalAlign: HorizontalAlign.Center,
      );

      List<String> headers = [
        'ID',
        'Branch',
        'Status Mekanik',
        'PIC',
        'Partner',
        'In Time',
        'Out Time',
        'Vehicle',
        'Nopol',
        'Date',
        'Serial Number',
        'Unit Type',
        'Year',
        'HM',
        'Lambung',
        'Customer',
        'Location',
        'Job Type',
        'Status Unit',
        'Prob Date',
        'RFU Date',
        'Lead Time',
        'PM Status',
        'RM Status',
        'Problem',
        'Action',
        'Recommendations',
        'Parts Installed',
      ];

      // Tulis Header
      for (int i = 0; i < headers.length; i++) {
        var cell = sheetObject.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      // Tulis Data
      for (int i = 0; i < _allJobs.length; i++) {
        final job = _allJobs[i];
        final row = i + 1;

        // Format list parts menjadi string
        String recText =
            job.recommendations
                ?.map((p) => '${p.partName} (${p.qty})')
                .join(', ') ??
            '';

        String partText =
            job.installParts
                ?.map((p) => '${p.partName} (${p.qty})')
                .join(', ') ??
            '';

        List<String> rowData = [
          job.id?.toString() ?? '',
          job.branch ?? '',
          job.statusMekanik ?? '',
          job.pic ?? '',
          job.partner ?? '',
          job.inTime ?? '',
          job.outTime ?? '',
          job.vehicle ?? '',
          job.nopol ?? '',
          job.date ?? '',
          job.serialNumber ?? '',
          job.unitType ?? '',
          job.year?.toString() ?? '',
          job.hourMeter ?? '',
          job.nomorLambung ?? '',
          job.customer ?? '',
          job.location ?? '',
          job.jobType ?? '',
          job.statusUnit ?? '',
          job.problemDate ?? '',
          job.rfuDate ?? '',
          job.leadTimeRfu ?? '',
          job.pm == true ? 'YES' : 'NO',
          job.rm == true ? 'YES' : 'NO',
          job.problem ?? '',
          job.action ?? '',
          recText,
          partText,
        ];

        for (int j = 0; j < rowData.length; j++) {
          sheetObject
              .cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: row))
              .value = TextCellValue(
            rowData[j],
          );
        }
      }

      // Nama file
      String roleSuffix = widget.user.isSuperAdmin
          ? 'GLOBAL'
          : widget.user.branch;
      String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      String fileName = 'Laporan_Jobs_${roleSuffix}_$timestamp.xlsx';

      String filePath = '${directory.path}/$fileName';

      // Simpan
      List<int>? fileBytes = excel.save();
      if (fileBytes == null) throw Exception('Gagal generate bytes Excel');

      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File disimpan: $fileName'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'BUKA',
              textColor: Colors.white,
              onPressed: () => OpenFilex.open(filePath),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error download: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Models Helper
class PMStats {
  final String month;
  int done;
  int notDone;
  PMStats({required this.month, required this.done, required this.notDone});
}

class ChartData {
  final String x;
  final double y;
  final Color color;
  ChartData(this.x, this.y, this.color);
}
