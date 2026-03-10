// lib/screens/unit_assets_screen.dart
import 'dart:io';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as excel;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/unit.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../services/ad_service.dart'; // Import AdService
import 'unit_detail_screen.dart';
import 'unit_form_screen.dart';
import '../../constants/colors.dart';
import '../../constants/typography.dart';
import '../../widgets/custom_app_bar.dart';

class UnitAssetsScreen extends StatefulWidget {
  final User user;
  const UnitAssetsScreen({super.key, required this.user});

  @override
  State<UnitAssetsScreen> createState() => _UnitAssetsScreenState();
}

class _UnitAssetsScreenState extends State<UnitAssetsScreen> {
  final ApiService api = ApiService();
  final AdService _adService = AdService(); // Init AdService
  final TextEditingController _searchController = TextEditingController();

  List<Unit> _allUnits = [];
  List<Unit> _filteredUnits = [];
  bool _loading = false;
  String _searchQuery = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUnits();
    _loadAds(); // Load iklan saat init
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

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query == _searchQuery) return;
    setState(() => _searchQuery = query);
    _applyFilter();
  }

  void _applyFilter() {
    final q = _searchQuery.toLowerCase();
    if (q.isEmpty) {
      setState(() => _filteredUnits = List.from(_allUnits));
      return;
    }
    setState(() {
      _filteredUnits = _allUnits.where((u) {
        final serial = (u.serialNumber ?? '').toLowerCase();
        final customer = (u.customer ?? '').toLowerCase();
        final branch = (u.branch ?? '').toLowerCase();
        final status = (u.status ?? '').toLowerCase();
        return serial.contains(q) ||
            customer.contains(q) ||
            branch.contains(q) ||
            status.contains(q);
      }).toList();
    });
  }

  Future<void> _loadUnits() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      List<Unit> list;
      if (widget.user.canViewAllUnits) {
        list = await api.fetchUnits();
      } else {
        list = await api.fetchUnitsByBranch(widget.user.branch);
      }
      setState(() {
        _allUnits = list;
        _filteredUnits = List.from(list);
      });
      _applyFilter();
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat data: $e';
        _allUnits = [];
        _filteredUnits = [];
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  // --- LOGIKA EXPORT EXCEL ---
  bool get _canExport {
    const allowedRoles = ['ADMIN DRR', 'KOORDINATOR', 'PLANNER'];
    return allowedRoles.contains(widget.user.statusUser.toUpperCase());
  }

Future<void> _exportToExcel() async {
    setState(() => _loading = true);
    try {
      var excelFile = excel.Excel.createExcel();
      excel.Sheet sheet = excelFile['Unit Assets'];
      // Hapus default Sheet1 jika ada
      if (excelFile.sheets.containsKey('Sheet1')) {
        excelFile.delete('Sheet1');
      }

      // 2. Header Sesuai Request
      List<String> headers = [
        'id',
        'supported_by',
        'customer',
        'location',
        'branch',
        'serial_number',
        'unit_type',
        'year',
        'status',
        'delivery',
        'jenis_unit',
        'note',
        'created_at',
        'updated_at',
      ];
      sheet.appendRow(headers.map((e) => excel.TextCellValue(e)).toList());

      // 3. Isi Data
      for (var u in _filteredUnits) {
        List<excel.CellValue> row = [
          excel.TextCellValue(u.id?.toString() ?? '-'),
          excel.TextCellValue(u.supportedBy ?? '-'),
          excel.TextCellValue(u.customer ?? '-'),
          excel.TextCellValue(u.location ?? '-'),
          excel.TextCellValue(u.branch ?? '-'),
          excel.TextCellValue(u.serialNumber ?? '-'),
          excel.TextCellValue(u.unitType ?? '-'),
          excel.TextCellValue(u.year?.toString() ?? '-'),
          excel.TextCellValue(u.status ?? '-'),
          excel.TextCellValue(u.delivery ?? '-'),
          excel.TextCellValue(u.jenisUnit ?? '-'),
          excel.TextCellValue(u.note ?? '-'),
          excel.TextCellValue(u.createdAt ?? '-'),
          excel.TextCellValue(u.updatedAt ?? '-'),
        ];
        sheet.appendRow(row);
      }

      // 4. Simpan dan Share
      final directory = await getTemporaryDirectory();
      final path =
          "${directory.path}/unit_assets_${DateTime.now().millisecondsSinceEpoch}.xlsx";
      final file = File(path);
      final fileBytes = excelFile.save();

      if (fileBytes != null) {
        await file.writeAsBytes(fileBytes);
        if (!mounted) return;

        // 🚀 PERBAIKAN: Menggunakan SharePlus.instance.share() dengan ShareParams
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(path)],
            subject:
                'Export Unit Assets Data', // Mengganti parameter `text` lama
          ),
        );
      }
    } catch (e) {
      log('Error exporting excel: ${e.toString()}');
      // Baris 342
      _showSnackBar('Gagal export excel: ${e.toString()}', AppColors.error);
    } finally {
      setState(() => _loading = false);
    }
  }

  // --- BUILD UI ---

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  PreferredSizeWidget _buildAppBar() {
    return CustomAppBar(
      title: 'Unit Assets',
      bottom: SearchAppBarBottom(
        searchController: _searchController,
        hintText: 'Cari serial, customer, branch...',
        itemCount: _filteredUnits.length,
        groupCount: 0,
        onRefresh: _loadUnits,
        showGroupCount: false,
      ),
    );
  }

  Widget _buildUnitCard(Unit unit) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToDetail(unit),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getUnitIcon(unit.unitType),
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unit.serialNumber ?? '-',
                      style: AppTextStyles.headlineSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      unit.customer ?? '-',
                      style: AppTextStyles.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.business,
                          size: 12,
                          color: AppColors.disabled,
                        ),
                        const SizedBox(width: 4),
                        Text(unit.branch ?? '-', style: AppTextStyles.caption),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildStatusBadge(unit.status),
                  const SizedBox(height: 8),
                  IconButton(
                    onPressed: () => _navigateToDetail(unit),
                    icon: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    final statusData = _getStatusData(status ?? '');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusData.color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        statusData.label,
        style: TextStyle(
          color: statusData.color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  ({String label, Color color}) _getStatusData(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return (label: 'ACTIVE', color: AppColors.active);
      case 'BACKUP':
        return (label: 'BACKUP', color: AppColors.backup);
      case 'RENTAL':
        return (label: 'RENTAL', color: AppColors.rental);
      case 'INACTIVE':
        return (label: 'INACTIVE', color: AppColors.inactive);
      default:
        return (label: 'UNKNOWN', color: AppColors.disabled);
    }
  }

  IconData _getUnitIcon(String? unitType) {
    if (unitType?.toLowerCase().contains('excavator') ?? false) {
      return Icons.construction;
    } else if (unitType?.toLowerCase().contains('bulldozer') ?? false) {
      return Icons.agriculture;
    } else if (unitType?.toLowerCase().contains('crane') ?? false) {
      return Icons.cable;
    }
    return Icons.build;
  }

  void _navigateToDetail(Unit unit) async {
    if (!widget.user.canAccessUnit(unit.branch ?? '')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak memiliki akses ke data ini'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final changed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UnitDetailScreen(unit: unit, user: widget.user),
      ),
    );

    if (changed == true) _loadUnits();
  }

  void _navigateToCreate() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UnitFormScreen(user: widget.user)),
    );
    _loadUnits();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      // Modified Floating Action Button untuk support multi-button (Export & Create)
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Tombol Export Excel (Hanya Role Tertentu)
          if (_canExport) ...[
            FloatingActionButton(
              heroTag: 'export_unit_assets',
              onPressed: _exportToExcel,
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              tooltip: 'Export Excel',
              child: const Icon(Icons.file_download),
            ),
            const SizedBox(height: 16),
          ],
          // Tombol Create (Hanya Jika Punya Akses)
          if (widget.user.canCreateUnit)
            FloatingActionButton(
              heroTag: 'create_unit_assets',
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Error: $_error', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUnits,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_filteredUnits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2, size: 64, color: AppColors.disabled),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'Tidak ada data unit'
                  : 'Tidak ada hasil pencarian',
              style: AppTextStyles.bodyLarge,
            ),
            if (_searchQuery.isEmpty && widget.user.canCreateUnit) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _navigateToCreate,
                child: const Text('Tambah Unit Pertama'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadUnits(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredUnits.length,
        itemBuilder: (context, index) => _buildUnitCard(_filteredUnits[index]),
      ),
    );
  }
}
