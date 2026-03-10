import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/unit.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import 'unit_form_screen.dart';

class UnitDetailScreen extends StatefulWidget {
  final Unit unit;
  final User user;
  const UnitDetailScreen({super.key, required this.unit, required this.user});

  @override
  State<UnitDetailScreen> createState() => _UnitDetailScreenState();
}

class _UnitDetailScreenState extends State<UnitDetailScreen> {
  final ApiService api = ApiService();
  late Unit current;
  bool loading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    current = widget.unit;
    _refreshDetail();
  }

  Future<void> _refreshDetail() async {
    if (current.id == null) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final upToDate = await api.fetchUnit(current.id!);
      if (upToDate != null) {
        setState(() => current = upToDate);
      }
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _onEdit() async {
    // Cek permissions sebelum edit
    if (!widget.user.canEditUnit ||
        !widget.user.canAccessUnit(current.branch ?? '')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak memiliki izin untuk mengedit data ini'),
        ),
      );
      return;
    }

    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UnitFormScreen(unit: current, user: widget.user),
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
    // Cek permissions sebelum delete
    if (!widget.user.canDeleteUnit ||
        !widget.user.canAccessUnit(current.branch ?? '')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak memiliki izin untuk menghapus data ini'),
        ),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text(
          'Hapus unit ${current.serialNumber ?? '-'}? Tindakan ini tidak dapat dibatalkan.',
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
    if (ok != true) return;
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final resp = await api.deleteUnit(current.id ?? 0);
      if (!mounted) return; // <<< Tambahkan pemeriksaan ini
      Navigator.pop(context);
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

  Widget _statusBadge(String? s) {
    final st = (s ?? 'UNKNOWN').toUpperCase();
    Color color = Colors.grey;
    if (st.contains('ACTIVE')) {
      color = Colors.green;
    } else if (st.contains('BACKUP')) {
      color = Colors.blue;
    } else if (st.contains('RENTAL')) {
      color = Colors.orange;
    } else if (st.contains('INACTIVE')) {
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(38),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        st,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _infoRow(String title, String? value, {bool multiline = false}) {
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
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              val,
              maxLines: multiline ? 5 : 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      final d = DateTime.parse(iso);
      return DateFormat('dd MMM yyyy HH:mm').format(d);
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 25, 32, 109),
        // Tambahkan ini untuk mengubah warna ikon dan teks di AppBar menjadi putih
        foregroundColor: Colors.white,
        title: const Text('Detail Unit'),
        actions: [
          // EDIT: Hanya SUPER ADMIN & KOORDINATOR yang bisa akses
          if (widget.user.canEditUnit &&
              widget.user.canAccessUnit(current.branch ?? ''))
            IconButton(
              onPressed: _onEdit,
              icon: const Icon(Icons.edit),
              tooltip: 'Edit',
            ),
          IconButton(
            onPressed: _refreshDetail,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          // DELETE: Hanya SUPER ADMIN & KOORDINATOR yang bisa akses
          if (widget.user.canDeleteUnit &&
              widget.user.canAccessUnit(current.branch ?? ''))
            IconButton(
              onPressed: _onDelete,
              icon: const Icon(Icons.delete),
              tooltip: 'Delete',
            ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text('Error: $error'))
          : SingleChildScrollView(
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
                            current.serialNumber ?? '-',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SelectableText(
                            current.customer ?? '-',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: _statusBadge(current.status),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informasi Unit',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Divider(),
                          _infoRow('Supported By', current.supportedBy),
                          _infoRow('Customer', current.customer),
                          _infoRow('Location', current.location),
                          _infoRow('Branch', current.branch),
                          _infoRow('Unit Type', current.unitType),
                          _infoRow('Year', current.year?.toString()),
                          _infoRow('Jenis Unit', current.jenisUnit),
                          _infoRow('Delivery', current.delivery),
                          _infoRow('Note', current.note, multiline: true),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                          const Text(
                            'Meta',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Divider(),
                          _infoRow('Created', _formatDate(current.createdAt)),
                          _infoRow('Updated', _formatDate(current.updatedAt)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      if (widget.user.canEditUnit &&
                          widget.user.canAccessUnit(current.branch ?? ''))
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _onEdit,
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit'),
                          ),
                        ),
                      if (widget.user.canEditUnit &&
                          widget.user.canAccessUnit(current.branch ?? ''))
                        const SizedBox(width: 12),
                      if (widget.user.canDeleteUnit &&
                          widget.user.canAccessUnit(current.branch ?? ''))
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _onDelete,
                            icon: const Icon(Icons.delete, color: Colors.red),
                            label: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
