// lib/screens/penarikan/penarikan_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:developer' as developer;
import 'package:url_launcher/url_launcher.dart';

import '../../models/penarikan.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../constants/colors.dart';
import '../../constants/typography.dart';
import 'penarikan_form.dart';

class PenarikanDetailScreen extends StatefulWidget {
  // MODIFIKASI: Menerima List dan Index agar bisa di swipe
  final List<Penarikan> penarikanList;
  final int initialIndex;
  final User user;

  const PenarikanDetailScreen({
    super.key,
    required this.penarikanList,
    required this.initialIndex,
    required this.user,
  });

  @override
  State<PenarikanDetailScreen> createState() => _PenarikanDetailScreenState();
}

class _PenarikanDetailScreenState extends State<PenarikanDetailScreen> {
  final ApiService api = ApiService();
  late PageController _pageController;

  late int _currentIndex;
  late Penarikan _currentPenarikan;

  // Untuk menghandle perubahan data lokal (jika user edit)
  late List<Penarikan> _localList;

  @override
  void initState() {
    super.initState();
    _localList = List.from(widget.penarikanList);

    // Pastikan index awal valid
    if (_localList.isNotEmpty &&
        widget.initialIndex >= 0 &&
        widget.initialIndex < _localList.length) {
      _currentIndex = widget.initialIndex;
    } else if (_localList.isNotEmpty) {
      _currentIndex = 0;
    } else {
      // Data kosong
      _currentIndex = 0;
      _currentPenarikan = Penarikan(id: null, serialNumber: 'Data Kosong');
      return;
    }

    _currentPenarikan = _localList[_currentIndex];
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Handle Swipe Page
  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _currentPenarikan = _localList[index];
    });
  }

  // ===== PERMISSION CHECKS (Updated to use _currentPenarikan) =====

  // Cek apakah data valid sebelum dicek izin
  bool get _isDataValid => _currentPenarikan.id?.isNotEmpty == true;

  // Izin Edit: PIC pemilik data, KOORDINATOR (di branch yang sama), atau ADMIN DRR
  bool get _canEdit {
    if (!_isDataValid) return false;

    final status = widget.user.statusUser.toUpperCase();
    final isOwner = _currentPenarikan.pic == widget.user.name;
    final isKoordinatorInBranch =
        status.contains('KOORDINATOR') &&
        _currentPenarikan.branch == widget.user.branch;
    final isAdmin = status.contains('ADMIN'); // ADMIN DRR, dll

    // Bisa Edit jika: Owner OR Koordinator (di branch-nya) OR Admin (di mana saja)
    return isOwner || isKoordinatorInBranch || isAdmin;
  }

  // Izin Hapus: KOORDINATOR (di branch yang sama) atau ADMIN DRR
  bool get _canDelete {
    if (!_isDataValid) {
      return false;
    }

    // Hapus baris ini:
    // if (_localList.isNotEmpty) {
    //   _currentPenarikan = _localList[_currentIndex];
    // }
    // Note: _currentPenarikan seharusnya sudah terupdate saat _onPageChanged atau _loadDetailSingle.

    final status = widget.user.statusUser.toUpperCase();
    final isKoordinatorInBranch =
        status.contains('KOORDINATOR') &&
        _currentPenarikan.branch == widget.user.branch;
    final isAdmin = status.contains('ADMIN');

    // Bisa Hapus jika: Koordinator (di branch-nya) OR Admin (di mana saja)
    // Note: PIC (Owner) TIDAK BISA HAPUS (sesuai permintaan 1: bisa edit tidak bisa hapus)
    return isKoordinatorInBranch || isAdmin;
  }

  String get _editDisabledReason {
    if (_canEdit) return '';

    final status = widget.user.statusUser.toUpperCase();

    if (status.contains('ADMIN')) {
      return 'Admin memiliki izin penuh, namun ada masalah data/izin yang tidak terduga.';
    }
    if (status.contains('KOORDINATOR')) {
      return 'Koordinator hanya bisa mengedit data di branch ${widget.user.branch}.';
    }

    // Jika bukan Admin, Koordinator, dan bukan Owner
    if (_currentPenarikan.pic != widget.user.name) {
      return 'Anda harus login sebagai PIC data ini (${_currentPenarikan.pic}) untuk mengedit.';
    }

    return 'Anda tidak memiliki izin untuk mengedit data ini.';
  }

  String get _deleteDisabledReason {
    if (_canDelete) return '';

    final status = widget.user.statusUser.toUpperCase();
    final isOwner = _currentPenarikan.pic == widget.user.name;

    // Kasus 1: PIC dilarang menghapus (sesuai permintaan 1)
    if (isOwner) {
      return 'Anda adalah PIC data ini. Anda hanya diizinkan untuk mengedit, bukan menghapus.';
    }

    // Kasus 2: Koordinator di branch yang salah
    if (status.contains('KOORDINATOR') &&
        _currentPenarikan.branch != widget.user.branch) {
      return 'Koordinator hanya bisa menghapus data di branch ${widget.user.branch}.';
    }

    // Kasus 3: User Biasa
    return 'Anda tidak memiliki izin untuk menghapus data ini. Hanya Koordinator dan Admin yang diperbolehkan.';
  }

  // --- ACTIONS ---

  Future<void> _deletePenarikan() async {
    if (!_canDelete) {
      _showSnack(_deleteDisabledReason, isError: true);
      return;
    }

    if (_currentPenarikan.id == null || _currentPenarikan.id!.isEmpty) {
      // Tambahkan kurung kurawal
      _showSnack('ID Penarikan tidak valid.', isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Penarikan?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Aksi ini tidak bisa dibatalkan.'),
            const SizedBox(height: 8),
            Text(
              'ID: ${_currentPenarikan.id}',
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

    if (confirmed != true) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final res = await api.deletePenarikan(_currentPenarikan.id!);
      if (!mounted) return;
      Navigator.pop(context); // Tutup loading

      if (res['ok'] == true) {
        _showSnack('Berhasil dihapus', isError: false);

        // Hapus dari list lokal
        setState(() {
          _localList.removeAt(_currentIndex);

          if (_localList.isEmpty) {
            // Jika list kosong, keluar dari detail screen dan kirim sinyal refresh
            Navigator.pop(context, true);
            return;
          }

          // Jika item terakhir dihapus, pindah ke index sebelumnya
          if (_currentIndex >= _localList.length) {
            _currentIndex = _localList.length - 1;
          }

          // Set item dan pindahkan PageView ke index baru
          _currentPenarikan = _localList[_currentIndex];
          _pageController.jumpToPage(_currentIndex);
        });
      } else {
        _showSnack('Gagal: ${res['message']}', isError: true);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showSnack('Error: $e', isError: true);
      }
      developer.log('Delete error: $e');
    }
  }

  Future<void> _editPenarikan() async {
    if (!_canEdit) {
      _showSnack(_editDisabledReason, isError: true);
      return;
    }

    // Pindah ke form edit
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PenarikanForm(penarikan: _currentPenarikan, user: widget.user),
      ),
    );

    // Jika ada update (kembali true), kita perlu refresh data item ini
    if (updated == true) {
      _loadDetailSingle();
    }
  }

  Future<void> _loadDetailSingle() async {
    // Reload hanya item yang sedang aktif untuk memastikan data fresh
    try {
      final detail = await api.fetchOnePenarikan(_currentPenarikan.id ?? '');
      if (mounted && detail != null) {
        setState(() {
          // Update list lokal dan item yang sedang aktif
          _localList[_currentIndex] = detail;
          _currentPenarikan = detail;
        });
      }
    } catch (e) {
      developer.log('Error reloading detail: $e');
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

  // --- SHARE FUNCTIONALITY ---
  String _formatWhatsAppMessage(Penarikan p) {
    // Format date
    String formatDate(String? dateString) {
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

    // Format time
    String formatTime(String? timeString) {
      if (timeString == null || timeString.isEmpty) return '-';
      return timeString;
    }

    String formatOptional(String l, String? v) =>
        (v != null && v.isNotEmpty) ? '\n$l: $v' : '';

    final jobType = (p.jobType is List)
        ? (p.jobType as List).join(', ')
        : (p.jobType as String? ?? '-');

    return '''
📝 *UPDATE JOB RENTAL* _`${p.statusMekanik ?? '-'}`_
$jobType

${p.customer?.toUpperCase() ?? '-'}
*LOCATION :* ${p.location?.toUpperCase() ?? '-'}
*DATE :* ${formatDate(p.date)}
*IN :* ${formatTime(p.inTime)}
*OUT :* ${formatTime(p.outTime)}
*MAN POWER :* ${p.pic ?? '-'} - ${p.partner ?? '-'}
*KENDARAAN :* ${p.vehicle ?? '-'} - ${p.nopol ?? '-'}

> _*DETAIL UNIT*_
*TYPE UNIT :* ${p.unitType ?? '-'}
*SN UNIT :* ${p.serialNumber ?? '-'}
*YEAR :* ${p.year?.toString() ?? '-'}
*HM :* ${p.hourMeter ?? '-'}
*BATTERY TYPE :*${formatOptional('BATTERY TYPE', p.batteryType)}
*BATTERY SN :*${formatOptional('BATTERY SN', p.batterySn)}
*CHARGER TYPE :*${formatOptional('CHARGER TYPE', p.chargerType)}
*CHARGER SN :*${formatOptional('CHARGER SN', p.chargerSn)}
*TROLLY :*${formatOptional('TROLLY', p.trolly)}

> _*JOB DESCRIPTIONS*_
*JOB TYPE :* $jobType
*STATUS :* _*${p.statusUnit ?? '-'}*_
*REMARK :* ${p.note ?? '-'}
''';
  }

Future<void> _shareToWhatsApp() async {
    final msg = _formatWhatsAppMessage(_currentPenarikan);

    // Gunakan URL Scheme 'whatsapp://send?text=...'
    final whatsappUrl = Uri.parse(
      "whatsapp://send?text=${Uri.encodeComponent(msg)}",
    );

    try {
      // Membuka WA dan menempatkan teks di chat box. User harus mengirim manual.
      if (!await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch WhatsApp';
      }
    } catch (e) {
      developer.log('WhatsApp Launch error: $e');

      // FALLBACK: menggunakan Share Sheet biasa

      // 🚀 PERBAIKAN: Menggunakan SharePlus.instance.share() dengan ShareParams
      await SharePlus.instance.share(ShareParams(text: msg));

      if (mounted) {
        // Opsional: _showSnack('Membuka menu share standar...');
      }
    }
  }

  // --- UI WIDGETS (Helper) ---

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

  Widget _statusBadge(String s) {
    Color color = Colors.grey;
    if (s.contains('RFU')) {
      color = Colors.green;
    } else if (s.contains('BREAK')) {
      color = Colors.red;
    } else if (s.contains('MONITOR')) {
      color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        s,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // --- MAIN BUILDER ---

  Widget _buildContent(Penarikan p) {
    // Handle case if the list becomes empty after deletion
    if (p.id == null && p.serialNumber == 'Data Kosong') {
      return const Center(child: Text('Data penarikan tidak tersedia.'));
    }

    // Format Job Type
    String jobTypeText;
    if (p.jobType is List) {
      jobTypeText = (p.jobType as List).join(', ');
    } else {
      jobTypeText = p.jobType?.toString() ?? '-';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
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
                    p.serialNumber?.isNotEmpty == true
                        ? p.serialNumber!
                        : (p.customer ?? 'No Data'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.customer ?? '-',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (p.statusUnit?.isNotEmpty == true)
                        _statusBadge(p.statusUnit!),
                      const Spacer(),
                      // Tampilkan index item yang sedang dilihat
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

          // Info Sections
          _buildSection('Informasi Penarikan', [
            _infoRow('ID', p.id),
            _infoRow('Branch', p.branch),
            _infoRow('PIC', p.pic),
            _infoRow('Partner', p.partner),
            _infoRow('Date', p.date),
            _infoRow('Vehicle', '${p.vehicle} (${p.nopol})'),
          ]),
          const SizedBox(height: 16),

          _buildSection('Unit Detail', [
            _infoRow('Unit Type', p.unitType),
            _infoRow('Serial Number', p.serialNumber),
            _infoRow('Location', p.location),
            _infoRow('Year', p.year),
            _infoRow('Hour Meter', p.hourMeter),
          ]),
          const SizedBox(height: 16),

          if (p.batteryType != null || p.chargerType != null)
            _buildSection('Battery & Charger', [
              _infoRow('Batt Type', p.batteryType),
              _infoRow('Batt SN', p.batterySn),
              _infoRow('Charger Type', p.chargerType),
              _infoRow('Charger SN', p.chargerSn),
              _infoRow('Trolly', p.trolly),
            ]),

          const SizedBox(height: 16),
          _buildSection('Status & Notes', [
            _infoRow('Job Type', jobTypeText),
            _infoRow('Note', p.note, multiline: true),
          ]),
          const SizedBox(height: 40), // Spacing for FAB
        ],
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

  @override
  Widget build(BuildContext context) {
    if (_localList.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Penarikan')),
        body: const Center(child: Text('Tidak ada data yang ditampilkan.')),
      );
    }

    // Pastikan item saat ini valid
    if (_currentIndex < 0 || _currentIndex >= _localList.length) {
      _currentIndex = 0;
    }
    _currentPenarikan = _localList[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Penarikan', style: const TextStyle(fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _canEdit ? Icons.edit : Icons.edit_off,
              color: _canEdit ? Colors.white : Colors.white38,
            ),
            onPressed: _editPenarikan,
            tooltip: _canEdit ? 'Edit' : _editDisabledReason,
          ),
          IconButton(
            icon: Icon(
              _canDelete ? Icons.delete : Icons.delete_forever,
              color: _canDelete ? Colors.white : Colors.white38,
            ),
            onPressed: _canDelete ? _deletePenarikan : null,
            tooltip: _canDelete ? 'Hapus' : _deleteDisabledReason,
          ),
        ],
      ),
      // MODIFIKASI: Menggunakan PageView untuk swipe
      body: PageView.builder(
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
