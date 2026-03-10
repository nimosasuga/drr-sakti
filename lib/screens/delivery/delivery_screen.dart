// lib/screens/delivery/delivery_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:developer';
import 'package:excel/excel.dart' as excel;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/delivery.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../constants/colors.dart';
import '../../constants/typography.dart';
import '../../constants/constants.dart';
import 'delivery_detail_screen.dart';
import 'delivery_form.dart';
import '../../widgets/custom_app_bar.dart';

class DeliveryScreen extends StatefulWidget {
  final User user;
  final String? picFilterName;
  const DeliveryScreen({super.key, required this.user, this.picFilterName});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  final ApiService api = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Delivery> _allDelivery = [];
  List<Delivery> _filteredDelivery = [];
  bool _loading = false;
  String _searchQuery = '';
  String? _error;

  // 1. Ubah tipe menjadi dynamic untuk menampung (Branch -> Month) atau (Month)
  Map<String, dynamic> _groupedDelivery = {};
  Set<String> _expandedMonths = {};
  bool get _isPicFilterActive => widget.picFilterName?.isNotEmpty == true;

  @override
  void initState() {
    super.initState();
    _loadDelivery();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- LOGIKA EXCEL START ---
  bool get _canExport {
    final allowed = ['ADMIN DRR', 'KOORDINATOR', 'PLANNER'];
    return allowed.contains(widget.user.statusUser.toUpperCase());
  }

  Future<void> _exportToExcel() async {
    setState(() => _loading = true);
    try {
      var excelFile = excel.Excel.createExcel();
      excel.Sheet sheet = excelFile['DeliveryData'];

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
        'customer',
        'location',
        'serial_number',
        'unit_type',
        'year',
        'hour_meter',
        'job_type',
        'status_unit',
        'battery_type',
        'battery_sn',
        'charger_type',
        'charger_sn',
        'trolly',
        'note',
        'created_at',
        'updated_at',
      ];

      sheet.appendRow(headers.map((e) => excel.TextCellValue(e)).toList());

      for (var item in _filteredDelivery) {
        List<excel.CellValue> row = [
          excel.TextCellValue(item.id.toString()),
          excel.TextCellValue(item.branch),
          excel.TextCellValue(
            (item as dynamic).statusMekanik?.toString() ?? '-',
          ),
          excel.TextCellValue(item.pic?.toString() ?? '-'),
          excel.TextCellValue((item as dynamic).partner?.toString() ?? '-'),
          excel.TextCellValue((item as dynamic).inTime?.toString() ?? '-'),
          excel.TextCellValue((item as dynamic).outTime?.toString() ?? '-'),
          excel.TextCellValue((item as dynamic).vehicle?.toString() ?? '-'),
          excel.TextCellValue((item as dynamic).nopol?.toString() ?? '-'),
          excel.TextCellValue(item.date),
          excel.TextCellValue(item.customer?.toString() ?? '-'),
          excel.TextCellValue(item.location?.toString() ?? '-'),
          excel.TextCellValue(item.serialNumber?.toString() ?? '-'),
          excel.TextCellValue((item as dynamic).unitType?.toString() ?? '-'),
          excel.TextCellValue((item as dynamic).year?.toString() ?? '-'),
          excel.TextCellValue((item as dynamic).hourMeter?.toString() ?? '-'),
          excel.TextCellValue('DELIVERY UNIT'),
          excel.TextCellValue(item.statusUnit?.toString() ?? '-'),
          excel.TextCellValue((item as dynamic).batteryType?.toString() ?? '-'),
          excel.TextCellValue((item as dynamic).batterySn?.toString() ?? '-'),
          excel.TextCellValue((item as dynamic).chargerType?.toString() ?? '-'),
          excel.TextCellValue((item as dynamic).chargerSn?.toString() ?? '-'),
          excel.TextCellValue((item as dynamic).trolly?.toString() ?? '-'),
          excel.TextCellValue(item.note?.toString() ?? '-'),
          excel.TextCellValue(item.createdAt?.toString() ?? '-'),
          excel.TextCellValue((item as dynamic).updatedAt?.toString() ?? '-'),
        ];
        sheet.appendRow(row);
      }

      var fileBytes = excelFile.save();
      var directory = await getTemporaryDirectory();
      String fileName =
          'Delivery_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      File file = File('${directory.path}/$fileName');

      if (fileBytes != null) {
        await file.writeAsBytes(fileBytes);
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            subject: 'Export Data Delivery - ${widget.user.branch}',
          ),
        );
      }
    } catch (e) {
      _showSnackBar('Gagal export Excel: $e', AppColors.error);
    } finally {
      setState(() => _loading = false);
    }
  }
  // --- LOGIKA EXCEL END ---

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query == _searchQuery) return;
    setState(() => _searchQuery = query);
    _applyFilter();
  }

  void _applyFilter() {
    final q = _searchQuery.toLowerCase();

    List<Delivery> baseList = _allDelivery;
    if (_isPicFilterActive) {
      baseList = _allDelivery
          .where(
            (d) => d.pic?.toLowerCase() == widget.picFilterName!.toLowerCase(),
          )
          .toList();
    }

    if (q.isEmpty) {
      setState(() => _filteredDelivery = List.from(baseList));
    } else {
      setState(() {
        _filteredDelivery = baseList.where((p) {
          final serial = (p.serialNumber ?? '').toLowerCase();
          final customer = (p.customer ?? '').toLowerCase();
          final branch = (p.branch).toLowerCase();
          final status = (p.statusUnit ?? '').toLowerCase();
          final pic = (p.pic ?? '').toLowerCase();

          return serial.contains(q) ||
              customer.contains(q) ||
              branch.contains(q) ||
              status.contains(q) ||
              pic.contains(q);
        }).toList();
      });
    }
    _groupDelivery();
  }

  // 2. Logika Grouping (Mengadopsi dari UpdateJobScreen)
  void _groupDelivery() {
    // Jika User bisa lihat semua jobs (Admin DRR), kita group berdasarkan Branch -> Bulan
    final bool groupByBranch = widget.user.canViewAllJobs;

    if (groupByBranch) {
      // === LEVEL 1: GROUP BY BRANCH -> LEVEL 2: GROUP BY MONTH ===
      final Map<String, Map<String, List<Delivery>>> groupedByBranch = {};

      for (final delivery in _filteredDelivery) {
        final branchKey = delivery.branch.toUpperCase();
        if (!groupedByBranch.containsKey(branchKey)) {
          groupedByBranch[branchKey] = {};
        }

        final monthKey = _getMonthKey(delivery.date);
        if (!groupedByBranch[branchKey]!.containsKey(monthKey)) {
          groupedByBranch[branchKey]![monthKey] = [];
        }
        groupedByBranch[branchKey]![monthKey]!.add(delivery);
      }

      // Sorting Keys Branch & Month
      final sortedBranchKeys = groupedByBranch.keys.toList()..sort();
      final Map<String, dynamic> sortedMap = {};

      for (final branchKey in sortedBranchKeys) {
        final monthGroups = groupedByBranch[branchKey]!;

        final Map<String, DateTime> monthDates = {};
        for (final key in monthGroups.keys) {
          monthDates[key] = _parseMonthKeyToDate(key);
        }
        final sortedMonthKeys = monthGroups.keys.toList()
          ..sort((a, b) => monthDates[b]!.compareTo(monthDates[a]!));

        final Map<String, List<Delivery>> sortedMonthMap = {};
        for (final monthKey in sortedMonthKeys) {
          monthGroups[monthKey]!.sort((a, b) {
            final dateA = _parseDate(a.date);
            final dateB = _parseDate(b.date);
            return dateB.compareTo(dateA);
          });
          sortedMonthMap[monthKey] = monthGroups[monthKey]!;
        }
        sortedMap[branchKey] = sortedMonthMap;
      }

      setState(() {
        _groupedDelivery = sortedMap;
        if (_groupedDelivery.isNotEmpty && _expandedMonths.isEmpty) {
          // Expand branch pertama secara default
          _expandedMonths = {_groupedDelivery.keys.first};
        }
      });
    } else {
      // === SINGLE LEVEL: GROUP BY MONTH (User Cabang) ===
      final Map<String, List<Delivery>> grouped = {};

      for (final delivery in _filteredDelivery) {
        final monthKey = _getMonthKey(delivery.date);
        if (!grouped.containsKey(monthKey)) {
          grouped[monthKey] = [];
        }
        grouped[monthKey]!.add(delivery);
      }

      final Map<String, DateTime> monthDates = {};
      for (final key in grouped.keys) {
        monthDates[key] = _parseMonthKeyToDate(key);
      }

      final sortedKeys = grouped.keys.toList()
        ..sort((a, b) => monthDates[b]!.compareTo(monthDates[a]!));

      final Map<String, dynamic> sortedMap = {};
      for (final key in sortedKeys) {
        grouped[key]!.sort((a, b) {
          final dateA = _parseDate(a.date);
          final dateB = _parseDate(b.date);
          return dateB.compareTo(dateA);
        });
        sortedMap[key] = grouped[key]!;
      }

      setState(() {
        _groupedDelivery = sortedMap;
        if (_groupedDelivery.isNotEmpty && _expandedMonths.isEmpty) {
          _expandedMonths = {_groupedDelivery.keys.first};
        }
      });
    }
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
    return (month >= 1 && month <= 12) ? months[month - 1] : 'Unknown';
  }

  int _getMonthNumber(String monthName) {
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
    int index = months.indexOf(monthName);
    return index != -1 ? index + 1 : 1;
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

  void _toggleMonthExpansion(String key) {
    setState(() {
      if (_expandedMonths.contains(key)) {
        _expandedMonths.remove(key);
      } else {
        _expandedMonths.add(key);
      }
    });
  }

  // 3. Logic Fetch Data API
  Future<void> _loadDelivery() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      List<Delivery> fetchedDelivery;

      // Menggunakan fetchDelivery yang sudah ada di ApiService
      if (widget.user.canViewAllJobs) {
        // Admin: ambil semua (branch = null)
        fetchedDelivery = await api.fetchDelivery();
      } else {
        // User Cabang: ambil sesuai cabang user
        fetchedDelivery = await api.fetchDelivery(branch: widget.user.branch);
      }

      // Filter PIC (opsional)
      if (_isPicFilterActive) {
        final String finalPicName = widget.picFilterName!.trim().toLowerCase();
        fetchedDelivery = fetchedDelivery
            .where((d) => d.pic?.trim().toLowerCase() == finalPicName)
            .toList();
      }

      if (!mounted) return;

      setState(() {
        _allDelivery = fetchedDelivery;
        _filteredDelivery = fetchedDelivery;
        _loading = false;
      });

      _groupDelivery(); // Panggil grouping
    } catch (e) {
      log('Error loading delivery: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _allDelivery = [];
        _filteredDelivery = [];
        _groupedDelivery = {};
        _loading = false;
      });
      _showSnackBar('Gagal memuat delivery: $e', AppColors.error);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  PreferredSizeWidget _buildAppBar() {
    return CustomAppBar(
      title: AppText.deliveryTitle,
      subtitle: '${widget.user.name} • ${widget.user.branch}',
      actions: [UserRoleBadge(role: widget.user.statusUser)],
      bottom: SearchAppBarBottom(
        searchController: _searchController,
        hintText: 'Cari serial, customer, PIC...',
        itemCount: _filteredDelivery.length,
        groupCount: _groupedDelivery.length,
        onRefresh: _loadDelivery,
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
        return (
          label: status.toUpperCase(),
          color: AppColors.disabled,
          icon: Icons.help,
        );
    }
  }

  // 4. UI Section untuk Branch (Admin View)
  Widget _buildBranchSection(
    String branchKey,
    Map<String, List<Delivery>> monthGroups,
  ) {
    final isExpanded = _expandedMonths.contains(branchKey);
    final jobCount = monthGroups.values.fold<int>(
      0,
      (sum, list) => sum + list.length,
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 4,
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
                          '$jobCount total delivery',
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
            // Nested Month Groups
            ...monthGroups.keys.map((monthKey) {
              return _buildMonthSection(
                monthKey,
                monthGroups[monthKey]!,
                isNested: true, // Flag nested
              );
            }),
          ],
        ],
      ),
    );
  }

  // 5. UI Section untuk Bulan
  Widget _buildMonthSection(
    String monthKey,
    List<Delivery> deliveryList, {
    bool isNested = false,
  }) {
    final isExpanded = _expandedMonths.contains(monthKey);
    final count = deliveryList.length;

    // Adjust UI jika nested
    final double horizontalPadding = isNested ? 8.0 : 16.0;
    final double leftPadding = isNested ? 16.0 : 0.0;

    return Padding(
      padding: EdgeInsets.only(left: leftPadding),
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
                              fontWeight: isNested
                                  ? FontWeight.w600
                                  : FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            '$count delivery',
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
              ...deliveryList.map((p) => _buildDeliveryCard(p)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryCard(Delivery p) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: InkWell(
        onTap: () => _navigateToDetail(p),
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
                child: const Icon(
                  Icons.local_shipping,
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
                      p.serialNumber?.isNotEmpty == true
                          ? p.serialNumber!
                          : (p.customer?.isNotEmpty == true
                                ? p.customer!
                                : '-'),
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      p.customer ?? '-',
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
                            p.pic ?? '-',
                            style: AppTextStyles.caption,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildStatusBadge(p.statusUnit),
                        const Spacer(),
                        SelectableText(
                          _formatDate(p.date),
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

  void _navigateToDetail(Delivery delivery) async {
    final currentExpandedMonths = Set<String>.from(_expandedMonths);
    final index = _filteredDelivery.indexOf(delivery);

    final changed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeliveryDetailScreen(
          deliveryList: _filteredDelivery,
          initialIndex: index,
          user: widget.user,
        ),
      ),
    );

    if (mounted) {
      setState(() {
        _expandedMonths = currentExpandedMonths;
      });
    }

    if (changed == true) {
      _loadDelivery();
    }
  }

  void _navigateToCreate() async {
    final currentExpandedMonths = Set<String>.from(_expandedMonths);

    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DeliveryForm(user: widget.user)),
    );

    if (mounted) {
      setState(() {
        _expandedMonths = currentExpandedMonths;
      });
    }

    if (created == true) {
      _loadDelivery();
    }
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
              heroTag: "btnExcelDelivery",
              onPressed: _exportToExcel,
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              tooltip: 'Download Excel',
              child: const Icon(Icons.file_download),
            ),
            const SizedBox(height: 16),
          ],
          if (widget.user.canCreateJob)
            FloatingActionButton(
              heroTag: "btnCreateDelivery",
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
              'Memuat data delivery...',
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
              onPressed: _loadDelivery,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_filteredDelivery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.local_shipping,
              size: 64,
              color: AppColors.disabled,
            ),
            const SizedBox(height: 16),
            SelectableText(
              _searchQuery.isEmpty
                  ? 'Tidak ada data delivery'
                  : 'Tidak ada hasil pencarian',
              style: AppTextStyles.bodyLarge,
            ),
            if (_searchQuery.isEmpty && widget.user.canCreateJob) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _navigateToCreate,
                child: const Text(AppText.deliveryCreate),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadDelivery(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _groupedDelivery.length,
        itemBuilder: (context, index) {
          final groupKey = _groupedDelivery.keys.elementAt(index);
          final groupValue = _groupedDelivery[groupKey];

          // 6. Tentukan Tampilan: Apakah Nested (Branch) atau Datar (Month)
          final bool isBranchGrouping =
              widget.user.canViewAllJobs && groupValue is Map;

          if (isBranchGrouping) {
            // Level 1: Branch Section
            return _buildBranchSection(
              groupKey,
              groupValue as Map<String, List<Delivery>>,
            );
          } else {
            // Level 1: Month Section
            return _buildMonthSection(groupKey, groupValue as List<Delivery>);
          }
        },
      ),
    );
  }
}
