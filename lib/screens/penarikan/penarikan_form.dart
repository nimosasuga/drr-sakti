// lib/screens/penarikan/penarikan_form.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;

// Import Model & Service
import '../../models/penarikan.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../constants/colors.dart';

// Import Detail Screen untuk navigasi setelah create
import 'penarikan_detail_screen.dart';

class PenarikanForm extends StatefulWidget {
  final Penarikan? penarikan;
  final User user;

  const PenarikanForm({super.key, this.penarikan, required this.user});

  @override
  State<PenarikanForm> createState() => _PenarikanFormState();
}

class _PenarikanFormState extends State<PenarikanForm> {
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
  List<String> customerList = [];
  List<String> locationList = [];
  List<Map<String, dynamic>> unitList = [];
  List<String> partnerList = [];

  bool loadingCustomers = false;
  bool loadingLocations = false;
  bool loadingUnits = false;
  bool loadingPartners = false;

  final List<String> availableJobTypes = ['TARIK UNIT'];

  final Color primaryColor = const Color(0xFF2C5AA0);
  final Color backgroundColor = const Color(0xFFF8F9FA);
  final Color borderColor = const Color(0xFFE0E0E0);
  final Color textColor = const Color(0xFF333333);
  final Color disabledColor = const Color(0xFFF5F5F5);

  // ===== PERMISSION CHECKS =====
  bool get _canCreate {
    final status = widget.user.statusUser.toUpperCase();
    return !status.contains('PLANNER');
  }

  bool get _canEdit {
    if (widget.penarikan == null) {
      return _canCreate;
    }
    return widget.penarikan!.pic == widget.user.name;
  }

  @override
  void initState() {
    super.initState();

    // Permission Check
    if (!_canCreate) {
      _showPermissionErrorAndPop(
        'Anda tidak memiliki permission untuk create penarikan',
      );
      return;
    }

    if (widget.penarikan != null && !_canEdit) {
      _showPermissionErrorAndPop(
        'Anda hanya bisa edit record yang Anda buat (PIC)',
      );
      return;
    }

    final p = widget.penarikan;
    _initializeControllers(p);
    _hasUnsavedChanges = widget.penarikan == null;

    _loadPartners();
    _loadCustomers();
  }

  void _showPermissionErrorAndPop(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
        Navigator.pop(context, false);
      }
    });
  }

  void _initializeControllers(Penarikan? p) {
    branchCtrl = TextEditingController(text: widget.user.branch);
    statusMekanikCtrl = TextEditingController(
      text: _getStatusMekanikFromUserStatus(widget.user.statusUser),
    );
    picCtrl = TextEditingController(text: widget.user.name);
    partnerCtrl = TextEditingController(text: p?.partner ?? '');

    inTime = _parseTime(p?.inTime);
    outTime = _parseTime(p?.outTime);

    vehicleCtrl = TextEditingController(text: p?.vehicle ?? '');
    nopolCtrl = TextEditingController(text: p?.nopol ?? '');

    date = _parseDate(p?.date);
    dateCtrl = TextEditingController(text: _fmtDate(date));

    customerCtrl = TextEditingController(text: p?.customer ?? '');
    locationCtrl = TextEditingController(text: p?.location ?? '');
    serialNumberCtrl = TextEditingController(text: p?.serialNumber ?? '');
    unitTypeCtrl = TextEditingController(text: p?.unitType ?? '');
    yearCtrl = TextEditingController(text: p?.year?.toString() ?? '');
    hourMeterCtrl = TextEditingController(text: p?.hourMeter ?? '');

    selectedJobTypes = p?.jobType ?? ['TARIK UNIT'];
    statusUnitVal = p?.statusUnit ?? 'RFU';

    batteryTypeCtrl = TextEditingController(text: p?.batteryType ?? '');
    batterySnCtrl = TextEditingController(text: p?.batterySn ?? '');
    chargerTypeCtrl = TextEditingController(text: p?.chargerType ?? '');
    chargerSnCtrl = TextEditingController(text: p?.chargerSn ?? '');
    trollyCtrl = TextEditingController(text: p?.trolly ?? '');
    noteCtrl = TextEditingController(text: p?.note ?? '');

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
    if (upper.contains('FIELD SERVICE')) {
      return 'Field Service';
    }
    if (upper.contains('FMC')) {
      return 'FMC';
    }
    return 'Field Service';
  }

  TimeOfDay? _parseTime(String? s) {
    if (s == null || s.isEmpty) {
      return null;
    }
    try {
      final p = s.split(':');
      return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
    } catch (_) {
      return null;
    }
  }

  DateTime? _parseDate(String? s) {
    if (s == null || s.isEmpty) {
      return null;
    }
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  String _fmtDate(DateTime? d) =>
      d == null ? '' : DateFormat('yyyy-MM-dd').format(d);
  String _fmtTime(TimeOfDay? t) => t == null ? '' : t.format(context);

  // --- API LOADERS ---

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

  Future<void> _loadCustomers() async {
    setState(() => loadingCustomers = true);
    try {
      final customers = await api.getCustomersByBranch(widget.user.branch);
      if (mounted) {
        setState(() => customerList = customers);
      }
    } catch (e) {
      developer.log('Error loading customers: $e');
    } finally {
      if (mounted) {
        setState(() => loadingCustomers = false);
      }
    }
  }

  Future<void> _onCustomerChanged(String customer) async {
    setState(() {
      customerCtrl.text = customer;
      locationCtrl.text = '';
      serialNumberCtrl.text = '';
      unitTypeCtrl.text = '';
      yearCtrl.text = '';
      hourMeterCtrl.text = '';

      locationList = [];
      unitList = [];
    });
    _onFormChanged();

    setState(() => loadingLocations = true);
    try {
      final locations = await api.getLocationsByCustomer(
        customer,
        widget.user.branch,
      );
      if (mounted) {
        setState(() => locationList = locations);
      }
    } catch (e) {
      developer.log('Error loading locations: $e');
    } finally {
      if (mounted) {
        setState(() => loadingLocations = false);
      }
    }
  }

  Future<void> _onLocationChanged(String location) async {
    final customer = customerCtrl.text.trim();
    if (customer.isEmpty) {
      return;
    }

    setState(() {
      locationCtrl.text = location;
      serialNumberCtrl.text = '';
      unitTypeCtrl.text = '';
      yearCtrl.text = '';
      hourMeterCtrl.text = '';
      unitList = [];
    });
    _onFormChanged();

    setState(() => loadingUnits = true);
    try {
      final units = await api.getUnitsByCustomerLocation(
        customer,
        location,
        widget.user.branch,
      );
      if (mounted) {
        setState(() => unitList = units);
      }
    } catch (e) {
      developer.log('Error loading units: $e');
    } finally {
      if (mounted) {
        setState(() => loadingUnits = false);
      }
    }
  }

  Future<void> _onUnitSelected(Map<String, dynamic> unit) {
    setState(() {
      serialNumberCtrl.text = unit['serial_number']?.toString() ?? '';
      unitTypeCtrl.text = unit['unit_type']?.toString() ?? '';
      yearCtrl.text = unit['year']?.toString() ?? '';
      hourMeterCtrl.text = unit['hour_meter']?.toString() ?? '';
    });
    _onFormChanged();

    if (mounted) {
      Navigator.pop(context);
    }
    return Future.value();
  }

  // --- UI HELPERS ---

  InputDecoration _buildInputDecoration(
    String label, {
    bool isReadOnly = false,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: textColor.withAlpha(180)),
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
    if (!_hasUnsavedChanges) {
      return true;
    }

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Perubahan belum disimpan'),
        content: const Text(
          'Apakah Anda yakin ingin meninggalkan halaman ini? Perubahan akan hilang.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  void _showJobTypeSelection() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Pilih Job Type'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: availableJobTypes.length,
                itemBuilder: (context, index) {
                  final jobType = availableJobTypes[index];
                  return CheckboxListTile(
                    title: Text(jobType),
                    value: selectedJobTypes.contains(jobType),
                    onChanged: (bool? value) {
                      setDialogState(() {
                        if (value == true) {
                          selectedJobTypes.add(jobType);
                        } else {
                          selectedJobTypes.remove(jobType);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {});
                  _onFormChanged();
                  Navigator.pop(context);
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showUnitSelection() {
    if (unitList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada unit tersedia atau lokasi belum dipilih.'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Unit'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: unitList.length,
            itemBuilder: (context, index) {
              final unit = unitList[index];
              final serial = unit['serial_number'] ?? '-';
              final type = unit['unit_type'] ?? '-';
              return ListTile(
                title: Text(serial),
                subtitle: Text('Type: $type'),
                onTap: () => _onUnitSelected(unit),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
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

  // ===== SUBMIT LOGIC =====

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validasi Manual
    if (customerCtrl.text.trim().isEmpty) {
      _showSnack('Customer harus diisi');
      return;
    }
    if (serialNumberCtrl.text.trim().isEmpty) {
      _showSnack('Serial Number harus diisi');
      return;
    }

    // Generate ID jika Create
    String? penarikanId = widget.penarikan?.id;
    if (penarikanId == null) {
      try {
        penarikanId = await api.generatePenarikanUUID();
        if (!penarikanId.startsWith('TK')) {
          penarikanId = 'TK$penarikanId';
        }
      } catch (e) {
        _showSnack('Error generate ID: $e', isError: true);
        return;
      }
    }

    // Buat Object Penarikan
    final penarikanData = Penarikan(
      id: penarikanId,
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
      date: date == null ? null : DateFormat('yyyy-MM-dd').format(date!),
      customer: customerCtrl.text.trim(),
      location: locationCtrl.text.trim(),
      serialNumber: serialNumberCtrl.text.trim(),
      unitType: unitTypeCtrl.text.trim(),
      // Modifikasi: Ambil nilai manual dari controller
      year: int.tryParse(yearCtrl.text.trim()),
      hourMeter: hourMeterCtrl.text.trim(),
      jobType: selectedJobTypes,
      statusUnit: statusUnitVal,
      batteryType: batteryTypeCtrl.text.trim(),
      batterySn: batterySnCtrl.text.trim(),
      chargerType: chargerTypeCtrl.text.trim(),
      chargerSn: chargerSnCtrl.text.trim(),
      trolly: trollyCtrl.text.trim(),
      note: noteCtrl.text.trim(),
      createdAt:
          widget.penarikan?.createdAt, // Pertahankan tanggal buat jika edit
    );

    // Show Loading
    if (!mounted) {
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      Map<String, dynamic> res;
      bool isCreate = widget.penarikan == null;

      if (isCreate) {
        res = await api.createPenarikan(penarikanData);
      } else {
        res = await api.updatePenarikan(penarikanData);
      }

      if (!mounted) {
        return;
      }
      Navigator.pop(context); // Tutup Loading

      if (res['ok'] == true) {
        setState(() => _hasUnsavedChanges = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data berhasil disimpan'),
            backgroundColor: Colors.green,
          ),
        );

        if (isCreate) {
          // MODIFIKASI: Jika Create Baru, pindah ke Detail Screen
          // Menggunakan list tunggal dan initialIndex = 0
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PenarikanDetailScreen(
                // Parameter 'penarikan' sudah diganti menjadi 'penarikanList'
                penarikanList: [penarikanData], // Bungkus data baru dalam List
                // Parameter wajib untuk PageView
                initialIndex: 0,
                user: widget.user,
              ),
            ),
          );
        } else {
          // Jika Edit, kembali ke Detail Screen sebelumnya (pop true triggers refresh)
          Navigator.pop(context, true);
        }
      } else {
        _showSnack('Gagal: ${res['message']}', isError: true);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Tutup Loading
        _showSnack('Error: $e', isError: true);
      }
      developer.log('Submit error: $e');
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : Colors.black87,
      ),
    );
  }

  void _onCancel() {
    if (_hasUnsavedChanges) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Batalkan Perubahan?'),
          content: const Text(
            'Semua perubahan yang belum disimpan akan hilang.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Lanjut Edit'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                Navigator.of(context).pop(false);
              },
              child: const Text(
                'Batalkan',
                style: TextStyle(color: Colors.red),
              ),
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
      // Fixed: Menambahkan curly braces {} untuk logic if di dalam callback
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
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
            widget.penarikan == null ? 'Tambah Penarikan' : 'Edit Penarikan',
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
                  // --- INFO TEKNISI ---
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
                                      value:
                                          partnerList.contains(partnerCtrl.text)
                                          ? partnerCtrl.text
                                          : null,
                                      isExpanded: true,
                                      hint: Text(
                                        partnerCtrl.text.isEmpty
                                            ? 'Pilih Partner'
                                            : partnerCtrl.text,
                                      ),
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

                  // --- KENDARAAN & WAKTU ---
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
                            validator: (v) =>
                                v?.isEmpty ?? true ? 'Harus diisi' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: nopolCtrl,
                            decoration: _buildInputDecoration('NOPOL'),
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

                  // --- CUSTOMER & LOCATION ---
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
                          loadingCustomers
                              ? const LinearProgressIndicator()
                              : InputDecorator(
                                  decoration: _buildInputDecoration('CUSTOMER'),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      // Cek apakah value ada di list
                                      value:
                                          customerList.contains(
                                            customerCtrl.text,
                                          )
                                          ? customerCtrl.text
                                          : null,
                                      isExpanded: true,
                                      hint: Text(
                                        customerCtrl.text.isEmpty
                                            ? 'Pilih Customer'
                                            : customerCtrl.text,
                                      ),
                                      items: customerList.map((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        if (newValue != null) {
                                          _onCustomerChanged(newValue);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                          const SizedBox(height: 12),
                          loadingLocations
                              ? const LinearProgressIndicator()
                              : InputDecorator(
                                  decoration: _buildInputDecoration('LOCATION'),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value:
                                          locationList.contains(
                                            locationCtrl.text,
                                          )
                                          ? locationCtrl.text
                                          : null,
                                      isExpanded: true,
                                      hint: Text(
                                        locationCtrl.text.isEmpty
                                            ? 'Pilih Location'
                                            : locationCtrl.text,
                                      ),
                                      items: locationList.map((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        if (newValue != null) {
                                          _onLocationChanged(newValue);
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

                  // --- UNIT INFO ---
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Unit Info',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                              // Tombol Pilih Unit
                              if (unitList.isNotEmpty ||
                                  customerCtrl.text.isNotEmpty)
                                ElevatedButton.icon(
                                  onPressed: _showUnitSelection,
                                  icon: const Icon(Icons.list, size: 16),
                                  label: const Text('Pilih dari List'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (loadingUnits) const LinearProgressIndicator(),

                          TextFormField(
                            controller: serialNumberCtrl,
                            decoration: _buildInputDecoration('SERIAL NUMBER'),
                            readOnly: false,
                            validator: (v) =>
                                v?.isEmpty ?? true ? 'Harus diisi' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: unitTypeCtrl,
                            decoration: _buildInputDecoration('UNIT TYPE'),
                            readOnly: false,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: yearCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: _buildInputDecoration('YEAR'),
                                  readOnly: false,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: hourMeterCtrl,
                                  keyboardType: TextInputType.text,
                                  decoration: _buildInputDecoration(
                                    'HOUR METER',
                                  ),
                                  readOnly: false,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- JOB TYPE & STATUS ---
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
                          InkWell(
                            onTap: _showJobTypeSelection,
                            child: InputDecorator(
                              decoration: _buildInputDecoration(
                                'JOB TYPE (Multi-Select)',
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      selectedJobTypes.isEmpty
                                          ? 'Pilih Job Type'
                                          : selectedJobTypes.join(', '),
                                      style: TextStyle(
                                        color: selectedJobTypes.isEmpty
                                            ? Colors.grey
                                            : textColor,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    color: primaryColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: statusUnits.contains(statusUnitVal)
                                ? statusUnitVal
                                : null,
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

                  // --- BATTERY & CHARGER ---
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

                  // --- NOTE ---
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

                  // --- BUTTONS ---
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
                            widget.penarikan == null ? 'Simpan' : 'Update',
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
