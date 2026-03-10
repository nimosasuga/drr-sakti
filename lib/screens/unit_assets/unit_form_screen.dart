// lib/screens/unit_form_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/unit.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../constants/colors.dart';
import '../../constants/typography.dart';

class UnitFormScreen extends StatefulWidget {
  final Unit? unit;
  final User user;
  const UnitFormScreen({super.key, this.unit, required this.user});

  @override
  State<UnitFormScreen> createState() => _UnitFormScreenState();
}

class _UnitFormScreenState extends State<UnitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService api = ApiService();

  late TextEditingController supportedByController;
  late TextEditingController customerController;
  late TextEditingController locationController;
  late TextEditingController branchController;
  late TextEditingController serialController;
  late TextEditingController unitTypeController;
  late TextEditingController yearController;
  late TextEditingController deliveryController;
  late TextEditingController jenisUnitController;
  late TextEditingController noteController;

  String? statusValue;
  final List<String> statusOptions = ['ACTIVE', 'BACKUP', 'RENTAL', 'INACTIVE'];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final u = widget.unit;

    supportedByController = TextEditingController(text: u?.supportedBy ?? '');
    customerController = TextEditingController(text: u?.customer ?? '');
    locationController = TextEditingController(text: u?.location ?? '');

    // Auto-set branch berdasarkan user (kecuali Super Admin)
    if (widget.user.isSuperAdmin) {
      branchController = TextEditingController(text: u?.branch ?? '');
    } else {
      branchController = TextEditingController(text: widget.user.branch);
    }

    serialController = TextEditingController(text: u?.serialNumber ?? '');
    unitTypeController = TextEditingController(text: u?.unitType ?? '');
    yearController = TextEditingController(text: u?.year?.toString() ?? '');
    deliveryController = TextEditingController(text: u?.delivery ?? '');
    jenisUnitController = TextEditingController(text: u?.jenisUnit ?? '');
    noteController = TextEditingController(text: u?.note ?? '');
    String? rawStatus = u?.status;
    if (rawStatus != null && rawStatus.isNotEmpty) {
      String normalizedStatus = rawStatus.toUpperCase();
      // Cek apakah normalized status ada di list options
      if (statusOptions.contains(normalizedStatus)) {
        statusValue = normalizedStatus;
      } else {
        // Fallback ke default jika tidak match
        statusValue = statusOptions.first;
      }
    } else {
      statusValue = statusOptions.first;
    }
  }

  @override
  void dispose() {
    supportedByController.dispose();
    customerController.dispose();
    locationController.dispose();
    branchController.dispose();
    serialController.dispose();
    unitTypeController.dispose();
    yearController.dispose();
    deliveryController.dispose();
    jenisUnitController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    DateTime initial = DateTime.now();
    if (deliveryController.text.isNotEmpty) {
      try {
        initial = DateTime.parse(deliveryController.text);
      } catch (_) {}
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        deliveryController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final int? year = int.tryParse(yearController.text.trim());
    final unit = Unit(
      id: widget.unit?.id,
      supportedBy: supportedByController.text.trim(),
      customer: customerController.text.trim(),
      location: locationController.text.trim(),
      branch: branchController.text.trim(),
      serialNumber: serialController.text.trim(),
      unitType: unitTypeController.text.trim(),
      year: year,
      status: statusValue,
      delivery: deliveryController.text.trim(),
      jenisUnit: jenisUnitController.text.trim(),
      note: noteController.text.trim(),
    );

    try {
      Map<String, dynamic> result;
      if (widget.unit == null) {
        result = await api.createUnit(unit);
      } else {
        result = await api.updateUnit(unit);
      }

      if (result['ok'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${result['message']}'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      } else {
        _showErrorDialog(result['message'] ?? 'Gagal menyimpan');
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('Konfirmasi', style: AppTextStyles.headlineSmall),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin membatalkan? Data yang belum disimpan akan hilang.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Lanjutkan',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              'Batalkan',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error, color: AppColors.error),
            const SizedBox(width: 8),
            Text('Error', style: AppTextStyles.headlineSmall),
          ],
        ),
        content: Text(message, style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    bool required = false,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: AppTextStyles.bodyMedium),
            if (required) ...[
              const SizedBox(width: 4),
              Text('*', style: TextStyle(color: AppColors.error)),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: readOnly,
            fillColor: readOnly ? AppColors.background : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.disabled),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          validator: (value) {
            if (required && (value == null || value.isEmpty)) {
              return '$label harus diisi';
            }
            if (keyboardType == TextInputType.number &&
                value != null &&
                value.isNotEmpty) {
              if (int.tryParse(value) == null) {
                return '$label harus berupa angka';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.unit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Unit' : 'Tambah Unit'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _showCancelConfirmation,
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // ID Display (if editing)
                    if (isEdit) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'ID: ${widget.unit!.id}',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Form Fields
                    _buildFormField(
                      label: 'Supported By',
                      controller: supportedByController,
                      required: true,
                    ),

                    _buildFormField(
                      label: 'Customer',
                      controller: customerController,
                      required: true,
                    ),

                    _buildFormField(
                      label: 'Location',
                      controller: locationController,
                    ),

                    _buildFormField(
                      label: 'Branch',
                      controller: branchController,
                      readOnly: !widget.user.isSuperAdmin,
                    ),

                    _buildFormField(
                      label: 'Serial Number',
                      controller: serialController,
                      required: true,
                    ),

                    _buildFormField(
                      label: 'Unit Type',
                      controller: unitTypeController,
                    ),

                    _buildFormField(
                      label: 'Year',
                      controller: yearController,
                      keyboardType: TextInputType.number,
                    ),

                    // Status Dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Status Unit', style: AppTextStyles.bodyMedium),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.disabled),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonFormField<String>(
                            initialValue: statusValue,
                            items: statusOptions
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(
                                      s,
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => statusValue = v),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

                    // Delivery Date
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Delivery Date', style: AppTextStyles.bodyMedium),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickDate,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.disabled),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    deliveryController.text.isEmpty
                                        ? 'Pilih tanggal'
                                        : deliveryController.text,
                                    style: deliveryController.text.isEmpty
                                        ? AppTextStyles.bodyMedium.copyWith(
                                            color: AppColors.disabled,
                                          )
                                        : AppTextStyles.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

                    _buildFormField(
                      label: 'Jenis Unit',
                      controller: jenisUnitController,
                    ),

                    _buildFormField(
                      label: 'Note',
                      controller: noteController,
                      maxLines: 3,
                    ),

                    // Save and Cancel Buttons
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: OutlinedButton(
                              onPressed: _showCancelConfirmation,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'BATAL',
                                style: AppTextStyles.button.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                isEdit ? 'UPDATE UNIT' : 'SIMPAN UNIT',
                                style: AppTextStyles.button,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}
