// lib/screens/delivery/delivery_detail_screen.dart
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart'; // [TAMBAHKAN IMPORT INI]

import '../../constants/colors.dart';
import '../../constants/typography.dart';
import '../../models/delivery.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import 'delivery_form.dart';

class DeliveryDetailScreen extends StatefulWidget {
  final List<Delivery> deliveryList;
  final int initialIndex;
  final User user;

  const DeliveryDetailScreen({
    super.key,
    required this.deliveryList,
    required this.initialIndex,
    required this.user,
  });

  @override
  State<DeliveryDetailScreen> createState() => _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends State<DeliveryDetailScreen> {
  final ApiService api = ApiService();
  late PageController _pageController;

  late int _currentIndex;
  late Delivery _currentDelivery;
  late List<Delivery> _localList;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _localList = List.from(widget.deliveryList);

    if (_localList.isNotEmpty &&
        widget.initialIndex >= 0 &&
        widget.initialIndex < _localList.length) {
      _currentIndex = widget.initialIndex;
    } else if (_localList.isNotEmpty) {
      _currentIndex = 0;
    } else {
      _currentIndex = 0;

      return;
    }

    _currentDelivery = _localList[_currentIndex];
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _currentDelivery = _localList[index];
    });
  }

  // ===== PERMISSION CHECKS =====
  bool get _isDataValid => _currentDelivery.id.isNotEmpty;

  bool get _canEdit {
    if (!_isDataValid) return false;
    return widget.user.statusUser.toLowerCase().contains('admin') ||
        _currentDelivery.pic == widget.user.name;
  }

  bool get _canDelete {
    if (!_isDataValid) return false;
    return widget.user.statusUser.toLowerCase().contains('admin');
  }

  String get _editDisabledReason {
    if (_canEdit) return '';
    return 'Anda harus login sebagai PIC data ini (${_currentDelivery.pic}) atau Admin untuk mengedit.';
  }

  String get _deleteDisabledReason {
    if (_canDelete) return '';
    return 'Hanya Admin yang memiliki izin untuk menghapus data ini.';
  }

  // ===== UTILITY METHODS =====
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return dateString;
    }
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) return '-';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('dd MMM yyyy HH:mm').format(dateTime);
    } catch (_) {
      return dateTimeString;
    }
  }

  String _formatDateLong(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateString);
      final days = [
        'Senin',
        'Selasa',
        'Rabu',
        'Kamis',
        'Jumat',
        'Sabtu',
        'Minggu',
      ];
      final months = [
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
      final dayName = days[date.weekday - 1];
      return '$dayName, ${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  List<String> _parseJobType(String? jobTypeJson) {
    if (jobTypeJson == null || jobTypeJson.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(jobTypeJson) as List<dynamic>;
      return list.map((e) => e.toString()).toList();
    } catch (e) {
      return [jobTypeJson];
    }
  }

  // ===== ACTIONS =====
  Future<void> _deleteDelivery() async {
    if (!_canDelete) {
      _showSnack(_deleteDisabledReason, isError: true);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Delivery?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Aksi ini tidak bisa dibatalkan.'),
            const SizedBox(height: 8),
            Text(
              'SN: ${_currentDelivery.serialNumber}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);

    try {
      await api.deleteDelivery(_currentDelivery.id);

      if (!mounted) return;
      _showSnack('Berhasil dihapus', isError: false);

      setState(() {
        _loading = false;
        _localList.removeAt(_currentIndex);

        if (_localList.isEmpty) {
          Navigator.pop(context, true);
          return;
        }

        if (_currentIndex >= _localList.length) {
          _currentIndex = _localList.length - 1;
        }

        _currentDelivery = _localList[_currentIndex];
        _pageController.jumpToPage(_currentIndex);
      });
    } catch (e) {
      developer.log('Error deleting: $e');
      if (mounted) {
        setState(() => _loading = false);
        _showSnack('Gagal menghapus: $e', isError: true);
      }
    }
  }

  Future<void> _editDelivery() async {
    if (!_canEdit) {
      _showSnack(_editDisabledReason, isError: true);
      return;
    }

    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DeliveryForm(delivery: _currentDelivery, user: widget.user),
      ),
    );

    if (updated is Delivery && mounted) {
      setState(() {
        _localList[_currentIndex] = updated;
        _currentDelivery = updated;
      });
      _showSnack('Data berhasil diperbarui');
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : Colors.green,
      ),
    );
  }

  // ===== SHARE WHATSAPP =====
  String _formatWhatsAppMessage(Delivery d) {
    String formatOptional(String l, String? v) =>
        (v != null && v.isNotEmpty) ? '\n$l: $v' : '';

    final jobTypes = _parseJobType(d.jobType);
    final jobTypeText = jobTypes.join(', ');

    return '''
🏗️ *UPDATE JOB RENTAL* _`${d.statusMekanik ?? '-'}`_
$jobTypeText

${d.customer?.toUpperCase() ?? '-'}
*LOCATION :* ${d.location?.toUpperCase() ?? '-'}
*DATE :* ${_formatDateLong(d.date)}
*IN :* ${d.inTime ?? '-'}
*OUT :* ${d.outTime ?? '-'}
*MAN POWER :* ${d.pic ?? '-'} - ${d.partner ?? '-'}
*KENDARAAN :* ${d.vehicle ?? '-'} - ${d.nopol ?? '-'}

> _*DETAIL UNIT*_
*TYPE UNIT :* ${d.unitType ?? '-'}
*SN UNIT :* ${d.serialNumber ?? '-'}
*YEAR :* ${d.year?.toString() ?? '-'}
*HM :* ${d.hourMeter ?? '-'}
*BATTERY TYPE :*${formatOptional('BATTERY TYPE', d.batteryType)}
*BATTERY SN :*${formatOptional('BATTERY SN', d.batterySn)}
*CHARGER TYPE :*${formatOptional('CHARGER TYPE', d.chargerType)}
*CHARGER SN :*${formatOptional('CHARGER SN', d.chargerSn)}
*TROLLY :*${formatOptional('TROLLY', d.trolly)}

> _*JOB DESCRIPTIONS*_
*JOB TYPE :* $jobTypeText
*STATUS :* _*${d.statusUnit ?? '-'}*_
*REMARK :* ${d.note ?? '-'}
''';
  }

  // MODIFIKASI: Menggunakan URL Launcher untuk memaksa masuk chat box
Future<void> _shareToWhatsApp() async {
    final msg = _formatWhatsAppMessage(_currentDelivery);

    // Gunakan URL Scheme 'whatsapp://send?text=...'
    // Ini memaksa membuka aplikasi WA dan menaruh teks di input field
    final whatsappUrl = Uri.parse(
      "whatsapp://send?text=${Uri.encodeComponent(msg)}",
    );

    try {
      // Cek apakah bisa membuka URL (WhatsApp terinstall)
      // Gunakan LaunchMode.externalApplication agar keluar dari aplikasi kita ke WA
      if (!await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch WhatsApp';
      }
    } catch (e) {
      developer.log('WhatsApp Launch error: $e');

      // FALLBACK: Jika WhatsApp tidak terinstall atau error,
      // gunakan Share Sheet biasa sebagai cadangan

      // 🚀 PERBAIKAN: Menggunakan SharePlus.instance.share() dengan ShareParams
      await SharePlus.instance.share(ShareParams(text: msg));

      if (mounted) {
        // Opsional: Beritahu user jika fallback terjadi
        // _showSnack('Membuka menu share standar...');
      }
    }
  }

  // ===== UI WIDGETS =====

  Widget _infoRow(String label, dynamic value, {bool multiline = false}) {
    final val = (value == null || value.toString().isEmpty)
        ? '-'
        : value.toString();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: multiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: SelectableText(
              val,
              maxLines: multiline ? 10 : 1,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String? s) {
    if (s == null) return const SizedBox.shrink();

    final status = s.toUpperCase();
    Color color = Colors.grey;

    if (status.contains('RFU')) {
      color = Colors.green;
    } else if (status.contains('BREAK')) {
      color = Colors.red;
    } else if (status.contains('MONITOR')) {
      color = Colors.orange;
    } else if (status.contains('WAITING')) {
      color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Delivery d) {
    if (d.id.isEmpty && d.serialNumber == 'Data Kosong') {
      return const Center(child: Text('Data delivery tidak tersedia.'));
    }

    final jobTypes = _parseJobType(d.jobType);
    final jobTypeText = jobTypes.isEmpty ? '-' : jobTypes.join(', ');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    d.serialNumber?.isNotEmpty == true
                        ? d.serialNumber!
                        : (d.customer ?? 'No Data'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    d.customer ?? '-',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (d.statusUnit?.isNotEmpty == true)
                        _statusBadge(d.statusUnit),
                      const Spacer(),
                      Text(
                        'Index: ${_currentIndex + 1}/${_localList.length}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          _buildSection('Informasi Delivery', [
            _infoRow('ID', d.id),
            _infoRow('Status Mekanik', d.statusMekanik),
            _infoRow('Branch', d.branch),
            _infoRow('PIC', d.pic),
            _infoRow('Partner', d.partner),
            _infoRow('Date', _formatDate(d.date)),
            _infoRow('Vehicle', '${d.vehicle} (${d.nopol})'),
          ]),
          const SizedBox(height: 16),

          _buildSection('Detail Unit', [
            _infoRow('Unit Type', d.unitType),
            _infoRow('Serial Number', d.serialNumber),
            _infoRow('Location', d.location),
            _infoRow('Year', d.year),
            _infoRow('Hour Meter', d.hourMeter),
          ]),
          const SizedBox(height: 16),

          if ((d.batteryType != null && d.batteryType!.isNotEmpty) ||
              (d.chargerType != null && d.chargerType!.isNotEmpty))
            _buildSection('Battery & Charger', [
              _infoRow('Batt Type', d.batteryType),
              _infoRow('Batt SN', d.batterySn),
              _infoRow('Charger Type', d.chargerType),
              _infoRow('Charger SN', d.chargerSn),
              _infoRow('Trolly', d.trolly),
            ]),

          if ((d.batteryType != null || d.chargerType != null))
            const SizedBox(height: 16),

          _buildSection('Logistik & Waktu', [
            _infoRow('In Time', d.inTime),
            _infoRow('Out Time', d.outTime),
          ]),
          const SizedBox(height: 16),

          _buildSection('Status & Notes', [
            _infoRow('Job Type', jobTypeText, multiline: true),
            _infoRow('Note', d.note, multiline: true),
            _infoRow('Dibuat', _formatDateTime(d.createdAt)),
            _infoRow('Diperbarui', _formatDateTime(d.updatedAt)),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_localList.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Delivery')),
        body: const Center(child: Text('Tidak ada data yang ditampilkan.')),
      );
    }

    if (_currentIndex < 0 || _currentIndex >= _localList.length) {
      _currentIndex = 0;
    }
    _currentDelivery = _localList[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Delivery', style: TextStyle(fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _canEdit ? Icons.edit : Icons.edit_off,
              color: _canEdit ? Colors.white : Colors.white38,
            ),
            onPressed: _editDelivery,
            tooltip: _canEdit ? 'Edit' : _editDisabledReason,
          ),
          IconButton(
            icon: Icon(
              _canDelete ? Icons.delete : Icons.delete_forever,
              color: _canDelete ? Colors.white : Colors.white38,
            ),
            onPressed: _canDelete ? _deleteDelivery : null,
            tooltip: _canDelete ? 'Hapus' : _deleteDisabledReason,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : PageView.builder(
              controller: _pageController,
              itemCount: _localList.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                return _buildContent(_localList[index]);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _shareToWhatsApp,
        backgroundColor: Colors.green,
        child: const Icon(Icons.share, color: Colors.white),
      ),
    );
  }
}
