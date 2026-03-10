// lib/screens/delivery/delivery_form.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;
import '../../models/delivery.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../constants/colors.dart';
import 'dart:convert';

// Helper untuk mengubah input menjadi huruf kapital
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class DeliveryForm extends StatefulWidget {
  final Delivery? delivery;
  final User user;

  const DeliveryForm({super.key, this.delivery, required this.user});

  @override
  State<DeliveryForm> createState() => _DeliveryFormState();
}

class _DeliveryFormState extends State<DeliveryForm> {
  final _formKey = GlobalKey<FormState>();
  final ApiService api = ApiService();

  bool _hasUnsavedChanges = false;

  // Controllers
  late TextEditingController branchCtrl;
  late TextEditingController statusMekanikCtrl;
  late TextEditingController picCtrl;
  late TextEditingController partnerCtrl;
  TimeOfDay? inTime;
  TimeOfDay? outTime;
  late TextEditingController vehicleCtrl;
  late TextEditingController nopolCtrl;
  DateTime? date;
  late TextEditingController dateCtrl;

  late TextEditingController customerCtrl;
  late TextEditingController locationCtrl;
  late TextEditingController serialNumberCtrl;
  late TextEditingController unitTypeCtrl;
  late TextEditingController yearCtrl;
  late TextEditingController hourMeterCtrl;

  List<String> selectedJobTypes = [];
  String statusUnitVal = 'RFU';

  late TextEditingController batteryTypeCtrl;
  late TextEditingController batterySnCtrl;
  late TextEditingController chargerTypeCtrl;
  late TextEditingController chargerSnCtrl;
  late TextEditingController trollyCtrl;
  late TextEditingController noteCtrl;

  // Dropdown data
  List<String> partnerList = [];

  bool loadingPartners = false;

  final String jobType = 'DELIVERY UNIT';

  final Color primaryColor = const Color(0xFF2C5AA0);
  final Color backgroundColor = const Color(0xFFF8F9FA);
  final Color borderColor = const Color(0xFFE0E0E0);
  final Color textColor = const Color(0xFF333333);
  final Color disabledColor = const Color(0xFFF5F5F5);

  // ===== PERMISSION CHECKS =====

  /// Check if user can create delivery
  bool get _canCreate {
    // Bisa create: semua status_user KECUALI PLANNER
    final status = widget.user.statusUser.toUpperCase();
    return !status.contains('PLANNER');
  }

  /// Check if user can edit delivery
  bool get _canEdit {
    // Bisa edit: hanya jika name user login = PIC di record
    if (widget.delivery == null) return _canCreate;
    return widget.delivery!.pic == widget.user.name;
  }

  @override
  void initState() {
    super.initState();

    // Check permission di startup
    if (!_canCreate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Anda tidak memiliki permission untuk create delivery',
              ),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context, false);
        }
      });
      return;
    }

    if (widget.delivery != null && !_canEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Anda hanya bisa edit record yang Anda buat (PIC)'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context, false);
        }
      });
      return;
    }

    final d = widget.delivery;
    _initializeControllers(d);
    _hasUnsavedChanges = widget.delivery == null;

    _loadPartners();
  }

  void _initializeControllers(Delivery? d) {
    branchCtrl = TextEditingController(text: widget.user.branch);
    statusMekanikCtrl = TextEditingController(
      text: _getStatusMekanikFromUserStatus(widget.user.statusUser),
    );
    picCtrl = TextEditingController(text: widget.user.name);
    partnerCtrl = TextEditingController(text: d?.partner ?? '');
    inTime = _parseTime(d?.inTime);
    outTime = _parseTime(d?.outTime);
    vehicleCtrl = TextEditingController(text: d?.vehicle ?? '');
    nopolCtrl = TextEditingController(text: d?.nopol ?? '');
    date = _parseDate(d?.date);
    dateCtrl = TextEditingController(text: _fmtDate(date));

    customerCtrl = TextEditingController(text: d?.customer ?? '');
    locationCtrl = TextEditingController(text: d?.location ?? '');
    serialNumberCtrl = TextEditingController(text: d?.serialNumber ?? '');
    unitTypeCtrl = TextEditingController(text: d?.unitType ?? '');
    yearCtrl = TextEditingController(text: d?.year?.toString() ?? '');
    hourMeterCtrl = TextEditingController(
      text: (d?.hourMeter)?.toString() ?? '',
    );

    selectedJobTypes = (d?.jobType is List<String>)
        ? d!.jobType as List<String>
        : ['DELIVERY UNIT'];
    statusUnitVal = d?.statusUnit ?? 'RFU';

    batteryTypeCtrl = TextEditingController(text: d?.batteryType ?? '');
    batterySnCtrl = TextEditingController(text: d?.batterySn ?? '');
    chargerTypeCtrl = TextEditingController(text: d?.chargerType ?? '');
    chargerSnCtrl = TextEditingController(text: d?.chargerSn ?? '');
    trollyCtrl = TextEditingController(text: d?.trolly ?? '');
    noteCtrl = TextEditingController(text: d?.note ?? '');

    _addChangeListeners();
  }

  void _addChangeListeners() {
    final controllers = [
      partnerCtrl,
      vehicleCtrl,
      nopolCtrl,
      dateCtrl,
      customerCtrl,
      locationCtrl,
      serialNumberCtrl,
      unitTypeCtrl,
      yearCtrl,
      hourMeterCtrl,
      batteryTypeCtrl,
      batterySnCtrl,
      chargerTypeCtrl,
      chargerSnCtrl,
      trollyCtrl,
      noteCtrl,
    ];

    for (final controller in controllers) {
      controller.addListener(_onFormChanged);
    }
  }

  void _onFormChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  String _getStatusMekanikFromUserStatus(String statusUser) {
    final upper = statusUser.toUpperCase();
    if (upper.contains('FIELD SERVICE')) return 'Field Service';
    if (upper.contains('FMC')) return 'FMC';
    return 'Field Service';
  }

  TimeOfDay? _parseTime(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      final p = s.split(':');
      return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
    } catch (_) {
      return null;
    }
  }

  DateTime? _parseDate(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  String _fmtDate(DateTime? d) =>
      d == null ? '' : DateFormat('yyyy-MM-dd').format(d);

  String _fmtTime(TimeOfDay? t) => t == null ? '' : t.format(context);

  Future<void> _loadPartners() async {
    setState(() => loadingPartners = true);
    try {
      final partners = await api.fetchPartnersByBranch(
        widget.user.branch,
        currentUserName: widget.user.name,
      );
      if (mounted) {
        setState(() => partnerList = partners);
      }
    } catch (e) {
      developer.log('Error loading partners: $e');
    } finally {
      if (mounted) {
        setState(() => loadingPartners = false);
      }
    }
  }

  InputDecoration _buildInputDecoration(
    String label, {
    bool isReadOnly = false,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: textColor.withValues(alpha: 0.7)),
      filled: true,
      fillColor: isReadOnly ? disabledColor : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to leave?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  Future<void> _pickDate(
    BuildContext c,
    DateTime? init,
    Function(DateTime) onPicked,
  ) async {
    final picked = await showDatePicker(
      context: c,
      initialDate: init ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onPicked(picked);
      _onFormChanged();
    }
  }

  Future<void> _pickTime(
    BuildContext c,
    TimeOfDay? init,
    Function(TimeOfDay) onPicked,
  ) async {
    final picked = await showTimePicker(
      context: c,
      initialTime: init ?? TimeOfDay.now(),
    );
    if (picked != null) {
      onPicked(picked);
      _onFormChanged();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (customerCtrl.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Customer harus diisi')));
      }
      return;
    }

    if (serialNumberCtrl.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Serial Number harus diisi')),
        );
      }
      return;
    }

    // GENERATE UUID JIKA CREATE BARU
    String deliveryId = widget.delivery?.id ?? '';
    if (deliveryId.isEmpty) {
      try {
        // API sudah return dengan prefix DL
        deliveryId = await api.generateDeliveryId();
        developer.log('✅ Generated Delivery ID: $deliveryId');
      } catch (e) {
        developer.log('❌ Error generate ID: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error generate ID: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
    }

    final delivery = Delivery(
      id: deliveryId,
      branch: branchCtrl.text.trim(),
      statusMekanik: statusMekanikCtrl.text.trim(),
      pic: picCtrl.text.trim(),
      partner: partnerCtrl.text.trim(),
      inTime: inTime == null
          ? null
          : '${inTime!.hour.toString().padLeft(2, '0')}:${inTime!.minute.toString().padLeft(2, '0')}',
      outTime: outTime == null
          ? null
          : '${outTime!.hour.toString().padLeft(2, '0')}:${outTime!.minute.toString().padLeft(2, '0')}',
      vehicle: vehicleCtrl.text.trim(),
      nopol: nopolCtrl.text.trim(),
      date: date == null ? '' : DateFormat('yyyy-MM-dd').format(date!),
      customer: customerCtrl.text.trim(),
      location: locationCtrl.text.trim(),
      serialNumber: serialNumberCtrl.text.trim(),
      unitType: unitTypeCtrl.text.trim(),
      year: int.tryParse(yearCtrl.text.trim()),
      hourMeter: int.tryParse(hourMeterCtrl.text.trim()),
      jobType: jsonEncode(selectedJobTypes),
      statusUnit: statusUnitVal,
      batteryType: batteryTypeCtrl.text.trim(),
      batterySn: batterySnCtrl.text.trim(),
      chargerType: chargerTypeCtrl.text.trim(),
      chargerSn: chargerSnCtrl.text.trim(),
      trolly: trollyCtrl.text.trim(),
      note: noteCtrl.text.trim(),
    );

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      Map<String, dynamic> res;
      if (widget.delivery == null) {
        res = await api.createDelivery(delivery);
      } else {
        res = await api.updateDelivery(delivery);
      }

      if (!mounted) return;
      Navigator.pop(context); // Tutup loading dialog

      // LOG UNTUK DEBUG
      developer.log('API Response: ${res.toString()}');
      developer.log('Response keys: ${res.keys.toList()}');
      developer.log('ok value: ${res['ok']}');
      developer.log('message value: ${res['message']}');

      // PERBAIKAN: Cek berbagai kemungkinan response format
      bool isSuccess = false;
      String message = '';

      // Cek format response yang mungkin
      if (res['ok'] == true || res['ok'] == 1 || res['ok'] == '1') {
        isSuccess = true;
        message = res['message']?.toString() ?? 'Delivery berhasil disimpan';
      } else if (res['success'] == true || res['success'] == 1) {
        isSuccess = true;
        message = res['message']?.toString() ?? 'Delivery berhasil disimpan';
      } else if (res['status'] == 'success' || res['status'] == 'ok') {
        isSuccess = true;
        message = res['message']?.toString() ?? 'Delivery berhasil disimpan';
      } else if (res.containsKey('id') && res['id'] != null) {
        // Jika ada ID di response, kemungkinan sukses
        isSuccess = true;
        message = 'Delivery berhasil disimpan';
      } else if (res['error'] != null || res['ok'] == false) {
        isSuccess = false;
        message =
            res['message']?.toString() ??
            res['error']?.toString() ??
            'Gagal menyimpan delivery';
      }

      if (mounted) {
        if (isSuccess) {
          setState(() => _hasUnsavedChanges = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ $message'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // Tunggu sebentar agar snackbar terlihat, lalu kembali
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.pop(context, true);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✗ $message'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Tutup loading dialog
        developer.log('Submit error: $e');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _onCancel() {
    if (_hasUnsavedChanges) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard Changes?'),
          content: const Text('Are you sure you want to discard changes?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                Navigator.of(context).pop(false);
              },
              child: const Text('Discard'),
            ),
          ],
        ),
      );
    } else {
      Navigator.of(context).pop(false);
    }
  }

  @override
  void dispose() {
    branchCtrl.dispose();
    statusMekanikCtrl.dispose();
    picCtrl.dispose();
    partnerCtrl.dispose();
    vehicleCtrl.dispose();
    nopolCtrl.dispose();
    dateCtrl.dispose();
    customerCtrl.dispose();
    locationCtrl.dispose();
    serialNumberCtrl.dispose();
    unitTypeCtrl.dispose();
    yearCtrl.dispose();
    hourMeterCtrl.dispose();
    batteryTypeCtrl.dispose();
    batterySnCtrl.dispose();
    chargerTypeCtrl.dispose();
    chargerSnCtrl.dispose();
    trollyCtrl.dispose();
    noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> statusUnits = ['RFU', 'BREAKDOWN'];

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldPop = await _onWillPop();

        if (shouldPop && mounted) {
          // Gunakan postFrameCallback untuk memastikan context valid
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pop(context);
            }
          });
        }
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Text(
            widget.delivery == null ? 'Tambah Delivery' : 'Edit Delivery',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: primaryColor,
          elevation: 2,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // PERMISSION NOTICE
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Permission Info:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'PIC: ${widget.user.name}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.withValues(alpha: 0.8),
                          ),
                        ),
                        Text(
                          'Role: ${widget.user.statusUser}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // INFO TEKNISI
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Informasi Teknisi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: branchCtrl,
                            decoration: _buildInputDecoration(
                              'BRANCH',
                              isReadOnly: true,
                            ),
                            readOnly: true,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: statusMekanikCtrl,
                            decoration: _buildInputDecoration(
                              'STATUS MEKANIK',
                              isReadOnly: true,
                            ),
                            readOnly: true,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: picCtrl,
                            decoration: _buildInputDecoration(
                              'PIC',
                              isReadOnly: true,
                            ),
                            readOnly: true,
                          ),
                          const SizedBox(height: 12),
                          loadingPartners
                              ? const LinearProgressIndicator()
                              : InputDecorator(
                                  decoration: _buildInputDecoration('PARTNER'),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: partnerCtrl.text.isEmpty
                                          ? null
                                          : partnerCtrl.text,
                                      isExpanded: true,
                                      hint: const Text('Pilih Partner'),
                                      items: partnerList.map((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        if (newValue != null) {
                                          setState(
                                            () => partnerCtrl.text = newValue,
                                          );
                                          _onFormChanged();
                                        }
                                      },
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // KENDARAAN & WAKTU
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Kendaraan & Waktu',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => _pickTime(
                                    context,
                                    inTime,
                                    (t) => setState(() => inTime = t),
                                  ),
                                  child: InputDecorator(
                                    decoration: _buildInputDecoration(
                                      'IN (HH:MM)',
                                    ),
                                    child: Text(
                                      _fmtTime(inTime),
                                      style: TextStyle(
                                        color: inTime == null
                                            ? Colors.grey
                                            : textColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _pickTime(
                                    context,
                                    outTime,
                                    (t) => setState(() => outTime = t),
                                  ),
                                  child: InputDecorator(
                                    decoration: _buildInputDecoration(
                                      'OUT (HH:MM)',
                                    ),
                                    child: Text(
                                      _fmtTime(outTime),
                                      style: TextStyle(
                                        color: outTime == null
                                            ? Colors.grey
                                            : textColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: vehicleCtrl,
                            decoration: _buildInputDecoration('VEHICLE'),
                            inputFormatters: [UpperCaseTextFormatter()],
                            validator: (v) =>
                                v?.isEmpty ?? true ? 'Harus diisi' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: nopolCtrl,
                            decoration: _buildInputDecoration('NOPOL'),
                            inputFormatters: [UpperCaseTextFormatter()],
                            validator: (v) =>
                                v?.isEmpty ?? true ? 'Harus diisi' : null,
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () => _pickDate(
                              context,
                              date,
                              (d) => setState(() {
                                date = d;
                                dateCtrl.text = _fmtDate(date);
                              }),
                            ),
                            child: InputDecorator(
                              decoration: _buildInputDecoration('DATE'),
                              child: Text(
                                dateCtrl.text.isEmpty
                                    ? 'Pilih Tanggal'
                                    : dateCtrl.text,
                                style: TextStyle(
                                  color: dateCtrl.text.isEmpty
                                      ? Colors.grey
                                      : textColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // CUSTOMER & LOCATION - INPUT MANUAL
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Customer & Location',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: customerCtrl,
                            decoration: _buildInputDecoration('CUSTOMER'),
                            inputFormatters: [UpperCaseTextFormatter()],
                            validator: (v) =>
                                v?.isEmpty ?? true ? 'Harus diisi' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: locationCtrl,
                            decoration: _buildInputDecoration('LOCATION'),
                            inputFormatters: [UpperCaseTextFormatter()],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // UNIT INFO - INPUT MANUAL
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Unit Info',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: serialNumberCtrl,
                            decoration: _buildInputDecoration('SERIAL NUMBER'),
                            inputFormatters: [UpperCaseTextFormatter()],
                            validator: (v) =>
                                v?.isEmpty ?? true ? 'Harus diisi' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: unitTypeCtrl,
                            decoration: _buildInputDecoration('UNIT TYPE'),
                            inputFormatters: [UpperCaseTextFormatter()],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: yearCtrl,
                                  decoration: _buildInputDecoration('YEAR'),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: hourMeterCtrl,
                                  decoration: _buildInputDecoration(
                                    'HOUR METER',
                                  ),
                                ),
                              ),
                            ],
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
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Job Type & Status',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // JOB TYPE (Read-only karena hanya satu pilihan)
                          TextFormField(
                            readOnly: true,
                            initialValue: jobType, // 'DELIVERY UNIT'
                            decoration: _buildInputDecoration('JOB TYPE'),
                          ),

                          const SizedBox(height: 12),

                          // STATUS UNIT (Tetap bisa dipilih)
                          DropdownButtonFormField<String>(
                            initialValue: statusUnitVal,
                            items: statusUnits
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => statusUnitVal = v);
                                _onFormChanged();
                              }
                            },
                            decoration: _buildInputDecoration('STATUS UNIT'),
                            validator: (v) =>
                                v?.isEmpty ?? true ? 'Harus diisi' : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // BATTERY & CHARGER
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Battery & Charger Info',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: batteryTypeCtrl,
                            decoration: _buildInputDecoration('BATTERY TYPE'),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: batterySnCtrl,
                            decoration: _buildInputDecoration('BATTERY SN'),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: chargerTypeCtrl,
                            decoration: _buildInputDecoration('CHARGER TYPE'),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: chargerSnCtrl,
                            decoration: _buildInputDecoration('CHARGER SN'),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: trollyCtrl,
                            decoration: _buildInputDecoration('TROLLY'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // NOTE
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Catatan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: noteCtrl,
                            decoration: _buildInputDecoration('NOTE'),
                            maxLines: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ACTION BUTTONS
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _onCancel,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textColor,
                            side: BorderSide(color: borderColor),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            widget.delivery == null ? 'Simpan' : 'Update',
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
        ),
      ),
    );
  }
}
