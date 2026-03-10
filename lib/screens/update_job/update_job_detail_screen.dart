// lib/screens/update_job_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:developer';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/update_job.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import 'update_job_form.dart';

class UpdateJobDetailScreen extends StatefulWidget {
  final UpdateJob job;
  final User user;
  const UpdateJobDetailScreen({
    super.key,
    required this.job,
    required this.user,
  });

  @override
  State<UpdateJobDetailScreen> createState() => _UpdateJobDetailScreenState();
}

class _UpdateJobDetailScreenState extends State<UpdateJobDetailScreen> {
  final ApiService api = ApiService();
  late UpdateJob current;
  bool loading = false;
  String? error;
  bool dataLoaded = false;

  // Menggunakan warna primary yang konsisten
  final Color primaryColor = const Color(0xFF2C5AA0);

  @override
  void initState() {
    super.initState();
    current = widget.job;

    // Refresh jika data awal tidak lengkap
    if (_isJobDataEmpty(widget.job)) {
      _refreshDetail();
    } else {
      dataLoaded = true;
    }
  }

  bool _isJobDataEmpty(UpdateJob job) {
    return job.id == null && job.serialNumber == null && job.customer == null;
  }

  Future<void> _refreshDetail() async {
    if (widget.job.id == null) {
      setState(() {
        error = 'Data job tidak valid (ID null)';
        dataLoaded = true;
      });
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final up = await api.fetchUpdateJob(widget.job.id!);

      if (up != null && !_isJobDataEmpty(up)) {
        setState(() {
          current = up;
          dataLoaded = true;
        });
      } else {
        setState(() {
          error = 'Data tidak ditemukan atau kosong';
          dataLoaded = true;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Gagal memuat data: $e';
        dataLoaded = true;
      });
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  // --- LOGIKA WARNA BERDASARKAN STATUS UNIT ---
  Color _getStatusUnitColor(String text) {
    final t = text.toUpperCase();
    if (t.contains('RFU')) {
      return Colors.green;
    } else if (t.contains('BREAKDOWN') || t.contains('BROKEN')) {
      return Colors.red;
    } else if (t.contains('MONITORING') || t.contains('MONITOR')) {
      return Colors.amber.shade700;
    } else if (t.contains('WAITING') || t.contains('WAITING PART')) {
      return Colors.orange;
    }
    return Colors.blue;
  }

  // --- LOGIKA WARNA UNTUK JOB TYPE ---
  Color _getJobTypeColor(String text) {
    final t = text.toUpperCase().trim();
    if (t.contains('RFU')) {
      return Colors.green;
    } else if (t.contains('BREAKDOWN') || t.contains('BROKEN')) {
      return Colors.red;
    } else if (t.contains('MONITORING') || t.contains('MONITOR')) {
      return Colors.amber.shade700;
    } else if (t.contains('WAITING') || t.contains('WAITING PART')) {
      return Colors.orange;
    }
    return primaryColor;
  }

  // --- HELPER WIDGETS ---

  Widget _statusBadge(String s) {
    final color = _getStatusUnitColor(s);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        s.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // Helper untuk Job Type Chips dengan warna khusus
  Widget _buildJobTypeChips(String? jobTypeString) {
    if (jobTypeString == null ||
        jobTypeString.isEmpty ||
        jobTypeString == '-') {
      return const Text('-');
    }

    final jobTypes = jobTypeString.split(',').map((e) => e.trim()).toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: jobTypes.map((jobType) {
        final color = _getJobTypeColor(jobType);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            jobType,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _infoRow(String label, String? value, {bool multiline = false}) {
    final val = (value == null || value.isEmpty) ? '-' : value;
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
              style: const TextStyle(color: Colors.black87),
              maxLines: multiline ? 10 : 1,
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      final d = DateTime.parse(iso);
      return DateFormat('dd MMM yyyy').format(d);
    } catch (_) {
      return iso;
    }
  }

  // --- ACTIONS ---

  Future<void> _onEdit() async {
    if (!widget.user.canEditJob(current)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak memiliki izin untuk mengedit data ini'),
        ),
      );
      return;
    }

    final res = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => UpdateJobForm(job: current, user: widget.user),
      ),
    );
    if (res == true) {
      await _refreshDetail();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Updated')));
      }
    }
  }

  Future<void> _onDelete() async {
    if (!widget.user.canDeleteJob(current)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak memiliki izin untuk menghapus data ini'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Hapus update job ID: ${current.id}?'),
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
      final resp = await api.deleteUpdateJob(current.id!);
      if (!mounted) return;
      Navigator.pop(context); // tutup loading
      if (resp['ok'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Berhasil dihapus')));
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal hapus: ${resp['message']}')),
          );
        }
      }
    } catch (e) {
      Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Exception: $e')));
      }
    }
  }

  // --- UI BUILDING BLOCKS ---

  Widget _buildHeaderCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              current.serialNumber?.isNotEmpty == true
                  ? current.serialNumber!
                  : (current.unitType ?? 'Update Job'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              current.customer ?? '-',
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 10),

            // Status Badge dengan warna custom
            if (current.statusUnit != null && current.statusUnit!.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: _statusBadge(current.statusUnit!),
              ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SelectableText(
                      'PIC: ${current.pic ?? '-'}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  if (widget.user.canEditJob(current))
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const SelectableText(
                        'Dapat Edit',
                        style: TextStyle(fontSize: 10, color: Colors.green),
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

  Widget _buildUnitInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informasi Unit',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            _infoRow('Branch', current.branch),
            _infoRow('Customer', current.customer),
            _infoRow('Location', current.location),
            _infoRow('Unit Type', current.unitType),
            _infoRow('Serial Number', current.serialNumber),
            _infoRow('Nomor Lambung', current.nomorLambung),
            _infoRow('Vehicle', current.vehicle),
            _infoRow('NOPOL', current.nopol),
            _infoRow('Year', current.year?.toString()),
            _infoRow('Hour Meter', current.hourMeter),
          ],
        ),
      ),
    );
  }

  Widget _buildJobStatusCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status & Job Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Divider(),

            // Job Type Chips dengan warna sesuai tipe
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 140,
                    child: Text(
                      'Job Type',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(child: _buildJobTypeChips(current.jobType)),
                ],
              ),
            ),

            // Partner saja (tanpa Status Mekanik)
            _infoRow('Partner', current.partner),

            _infoRow('Date', _fmtDate(current.date)),
            _infoRow('In', current.inTime),
            _infoRow('Out', current.outTime),

            // Status Unit dengan warna
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                children: [
                  const SizedBox(
                    width: 140,
                    child: Text(
                      'Status Unit',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      current.statusUnit ?? '-',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getStatusUnitColor(current.statusUnit ?? ''),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(),

            _infoRow('Problem Date', _fmtDate(current.problemDate)),
            _infoRow('RFU Date', _fmtDate(current.rfuDate)),
            _infoRow('Lead Time RFU', current.leadTimeRfu),

            const SizedBox(height: 8),
            // PM & RM Flags
            Row(
              children: [
                Icon(
                  current.pm == true
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  size: 16,
                  color: current.pm == true ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 4),
                const Text('PM'),
                const SizedBox(width: 16),
                Icon(
                  current.rm == true
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  size: 16,
                  color: current.rm == true ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 4),
                const Text('RM'),
              ],
            ),

            const Divider(height: 24),

            _infoRow('Problem', current.problem, multiline: true),
            _infoRow('Action', current.action, multiline: true),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    if (current.recommendations == null || current.recommendations!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recommendations',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Divider(),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: current.recommendations!.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                final item = current.recommendations![index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${item.partNumber ?? '-'} - ${item.partName ?? '-'}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Qty: ${item.qty ?? 0}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (item.remarks?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Remarks: ${item.remarks}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstallPartsCard() {
    if (current.installParts == null || current.installParts!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Install Parts',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Divider(),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: current.installParts!.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                final item = current.installParts![index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.build, color: Colors.blue, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${item.partNumber ?? '-'} - ${item.partName ?? '-'}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Qty: ${item.qty ?? 0}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (item.noJob?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        'No Job: ${item.noJob}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                    if (item.noPr?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        'No PR: ${item.noPr}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                    if (item.remarks?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Remarks: ${item.remarks}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Metadata',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Divider(),
            _infoRow('Created', current.createdAt),
            _infoRow('Updated', current.updatedAt),
          ],
        ),
      ),
    );
  }

  // --- WHATSAPP SHARE LOGIC ---

  String _formatWhatsAppMessage() {
    final job = current;

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
        return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
      } catch (e) {
        return dateString;
      }
    }

    String formatRecommendations() {
      if (job.recommendations == null || job.recommendations!.isEmpty) {
        return '*PART NUMBER :* -\n*PART NAME :* -\n*QTY :* -\n*REMARKS :* -';
      }
      final buffer = StringBuffer();
      for (int i = 0; i < job.recommendations!.length; i++) {
        final part = job.recommendations![i];
        if (i > 0) buffer.write('\n');
        buffer.write('*PART NUMBER :* ${part.partNumber ?? "-"}\n');
        buffer.write('*PART NAME :* ${part.partName ?? "-"}\n');
        buffer.write('*QTY :* ${part.qty ?? "-"}\n');
        buffer.write('*REMARKS :* ${part.remarks ?? "-"}');
      }
      return buffer.toString();
    }

    String formatInstallParts() {
      if (job.installParts == null || job.installParts!.isEmpty) {
        return '*PART NUMBER :* -\n*PART NAME :* -\n*QTY :* -\n*NO JOB :* -\n*NO PR :* -\n*REMARKS :* -';
      }
      final buffer = StringBuffer();
      for (int i = 0; i < job.installParts!.length; i++) {
        final part = job.installParts![i];
        if (i > 0) buffer.write('\n');
        buffer.write('*PART NUMBER :* ${part.partNumber ?? "-"}\n');
        buffer.write('*PART NAME :* ${part.partName ?? "-"}\n');
        buffer.write('*QTY :* ${part.qty ?? "-"}\n');
        buffer.write('*NO JOB :* ${part.noJob ?? "-"}\n');
        buffer.write('*NO PR :* ${part.noPr ?? "-"}\n');
        buffer.write('*REMARKS :* ${part.remarks ?? "-"}');
      }
      return buffer.toString();
    }

    final message =
        '''
📝 *UPDATE JOB RENTAL* _${job.statusMekanik ?? '-'}_
${job.jobType ?? '-'}

*${job.customer?.toUpperCase() ?? '-'}*
*LOCATION :* ${job.location?.toUpperCase() ?? '-'}
*DATE :* ${formatDate(job.date)}
*IN :* ${job.inTime ?? '-'}
*OUT :* ${job.outTime ?? '-'}
*MAN POWER :* ${job.pic ?? ''} - ${job.partner ?? ''}
*KENDARAAN :* ${job.vehicle ?? ''} - ${job.nopol ?? ''}

> _*DETAIL UNIT*_
*NOMOR LAMBUNG :* ${job.nomorLambung ?? ''}
*UNIT TYPE :* ${job.unitType ?? ''}
*SERIAL NUMBER :* ${job.serialNumber ?? '-'}
*HOUR METER :* ${job.hourMeter ?? '-'}
*YEAR :* ${job.year ?? '-'}

> _*JOB DESCRIPTIONS*_
*JOB TYPE :* ${job.jobType ?? '-'}
*PROBLEM DATE :* ${formatDate(job.problemDate)}
*PROBLEM :* ${job.problem ?? '-'}
*STATUS :* ${job.statusUnit ?? '-'}
*RFU DATE :* ${formatDate(job.rfuDate)}
*ACTION :* ${job.action ?? '-'}

> _*RECOMMENDATIONS*_
${formatRecommendations()}

> _*INSTALL PART*_
${formatInstallParts()}
''';

    return message;
  }

  Future<void> _shareToWhatsApp() async {
    final msg = _formatWhatsAppMessage();
    final whatsappUrl = Uri.parse(
      "whatsapp://send?text=${Uri.encodeComponent(msg)}",
    );

    try {
      if (!await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch WhatsApp';
      }
    } catch (e) {
      log('WhatsApp Launch error: $e');

      // 🚀 PERBAIKAN: Menggunakan SharePlus.instance.share() dengan ShareParams
      await SharePlus.instance.share(ShareParams(text: msg));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detail Update Job'),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          actions: [
            if (dataLoaded &&
                !_isJobDataEmpty(current) &&
                widget.user.canEditJob(current))
              Tooltip(
                message: 'Edit',
                child: IconButton(
                  onPressed: _onEdit,
                  icon: const Icon(Icons.edit),
                ),
              ),
            IconButton(
              onPressed: _refreshDetail,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
            if (dataLoaded &&
                !_isJobDataEmpty(current) &&
                widget.user.canDeleteJob(current))
              Tooltip(
                message: 'Delete',
                child: IconButton(
                  onPressed: _onDelete,
                  icon: const Icon(Icons.delete),
                ),
              ),
          ],
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : (error != null)
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 64, color: Colors.red.shade300),
                    const SizedBox(height: 16),
                    Text(error!, style: TextStyle(color: Colors.red.shade700)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _refreshDetail,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeaderCard(),
                    const SizedBox(height: 16),
                    _buildUnitInfoCard(),
                    const SizedBox(height: 16),
                    _buildJobStatusCard(),
                    const SizedBox(height: 16),
                    if (current.recommendations?.isNotEmpty == true) ...[
                      _buildRecommendationsCard(),
                      const SizedBox(height: 16),
                    ],
                    if (current.installParts?.isNotEmpty == true) ...[
                      _buildInstallPartsCard(),
                      const SizedBox(height: 16),
                    ],
                    _buildMetaCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
        floatingActionButton: dataLoaded && !_isJobDataEmpty(current)
            ? FloatingActionButton(
                onPressed: _shareToWhatsApp,
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                child: const Icon(Icons.share),
              )
            : null,
      ),
    );
  }
}
