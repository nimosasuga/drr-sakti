// lib/screens/charger/charger_form.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;
import '../../models/charger.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../constants/colors.dart';

class ChargerForm extends StatefulWidget {
  final Charger? charger;
  final User user;

  const ChargerForm({super.key, this.charger, required this.user});

  @override
  State<ChargerForm> createState() => _ChargerFormState();
}

class _ChargerFormState extends State<ChargerForm> {
  final _formKey = GlobalKey<FormState>();
  final ApiService api = ApiService();

  bool _hasUnsavedChanges = false;

  // ===== CONTROLLERS =====
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
  late TextEditingController unitTypeCtrl;
  late TextEditingController unitSerialCtrl;

  late TextEditingController snChargerCtrl;
  late TextEditingController chargerTypeCtrl;
  late TextEditingController chargerYearCtrl;

  // Job & Status
  List<String> selectedJobTypes = [];
  String categoryJobVal = '';
  String statusUnitVal = 'RFU';

  late TextEditingController problemDateCtrl;
  DateTime? problemDate;
  late TextEditingController rfuDateCtrl;
  DateTime? rfuDate;

  late TextEditingController problemCtrl;
  late TextEditingController actionCtrl;

  List<PartItem> recommendations = [];
  List<PartItem> installParts = [];

  // Data Sources
  List<String> customerList = [];
  List<String> locationList = [];
  List<String> partnerList = [];

  // Unit Selection Logic
  List<Map<String, dynamic>> _allUnitsAtLocation = [];
  List<String> _availableUnitTypes = [];
  List<String> _availableSerialNumbers = [];

  bool loadingCustomers = false;
  bool loadingLocations = false;
  bool loadingPartners = false;
  bool loadingUnits = false;

  final List<String> availableJobTypes = [
    'Troubleshooting',
    'Install Part',
    'Repair',
  ];

  final List<String> availableCategoryJobs = [
    'CEK CHARGER',
    'TARIK CHARGER',
    'KIRIM CHARGER',
  ];

  final Color primaryColor = const Color(0xFF2C5AA0);
  final Color backgroundColor = const Color(0xFFF8F9FA);
  final Color borderColor = const Color(0xFFE0E0E0);
  final Color textColor = const Color(0xFF333333);
  final Color disabledColor = const Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    final c = widget.charger;
    _initializeControllers(c);
    _hasUnsavedChanges = widget.charger == null;

    _loadPartners();
    _loadCustomers();

    if (c != null && c.customer != null && c.location != null) {
      _preloadDataForEdit(c.customer!, c.location!, c.unitType, c.serialNumber);
    }
  }

  void _initializeControllers(Charger? c) {
    branchCtrl = TextEditingController(text: widget.user.branch);
    statusMekanikCtrl = TextEditingController(
      text: _getStatusMekanikFromUserStatus(widget.user.statusUser),
    );
    picCtrl = TextEditingController(text: widget.user.name);
    partnerCtrl = TextEditingController(text: c?.partner ?? '');
    inTime = _parseTime(c?.inTime);
    outTime = _parseTime(c?.outTime);
    vehicleCtrl = TextEditingController(text: c?.vehicle ?? '');
    nopolCtrl = TextEditingController(text: c?.nopol ?? '');
    date = _parseDate(c?.date);
    dateCtrl = TextEditingController(text: _fmtDate(date));

    // Mapping Unit Info
    customerCtrl = TextEditingController(text: c?.customer ?? '');
    locationCtrl = TextEditingController(text: c?.location ?? '');
    unitTypeCtrl = TextEditingController(text: c?.unitType ?? '');
    unitSerialCtrl = TextEditingController(text: c?.serialNumber ?? '');

    // Mapping Charger Info
    snChargerCtrl = TextEditingController(text: c?.snCharger ?? '');
    chargerTypeCtrl = TextEditingController(text: c?.chargerType ?? '');
    chargerYearCtrl = TextEditingController(
      text: c?.chargerYear?.toString() ?? '',
    );

    // Job Type Parsing
    selectedJobTypes = [];
    if (c?.jobType != null && c!.jobType!.isNotEmpty) {
      String raw = c.jobType!;
      String clean = raw
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll('"', '');
      if (clean.contains(',')) {
        selectedJobTypes = clean
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      } else if (clean.trim().isNotEmpty) {
        selectedJobTypes = [clean.trim()];
      }
    }

    final String? initialCategoryJob = c?.categoryJob;
    categoryJobVal =
        initialCategoryJob != null &&
            availableCategoryJobs.contains(initialCategoryJob)
        ? initialCategoryJob
        : availableCategoryJobs.first;

    statusUnitVal = c?.statusUnit ?? 'RFU';

    problemDate = _parseDate(c?.problemDate);
    problemDateCtrl = TextEditingController(text: _fmtDate(problemDate));
    rfuDate = _parseDate(c?.rfuDate);
    rfuDateCtrl = TextEditingController(text: _fmtDate(rfuDate));

    problemCtrl = TextEditingController(text: c?.problem ?? '');
    actionCtrl = TextEditingController(text: c?.action ?? '');

    recommendations = List<PartItem>.from(c?.recommendations ?? []);
    installParts = List<PartItem>.from(c?.installParts ?? []);

    _addChangeListeners();
  }

  // 🔥 FIX UTAMA EDIT MODE: Logic Preload Data yang lebih kuat
  Future<void> _preloadDataForEdit(
    String cust,
    String loc,
    String? currentUnitType,
    String? currentSerial,
  ) async {
    setState(() {
      loadingLocations = true;
      loadingUnits = true;
    });

    try {
      // 1. Load Locations
      final locs = await api.getLocationsByCustomer(cust, widget.user.branch);

      // 2. Load Units
      final units = await api.getUnitsByCustomerLocation(
        cust,
        loc,
        widget.user.branch,
      );

      if (mounted) {
        setState(() {
          locationList = locs;
          _allUnitsAtLocation = units;

          // Populate Unit Types
          _availableUnitTypes = units
              .map((u) => u['unit_type']?.toString() ?? '')
              .where((t) => t.isNotEmpty)
              .toSet()
              .toList();
          _availableUnitTypes.sort();

          // Populate Serial Numbers jika Unit Type ada
          if (currentUnitType != null && currentUnitType.isNotEmpty) {
            _availableSerialNumbers = _allUnitsAtLocation
                .where((u) => u['unit_type'] == currentUnitType)
                .map((u) => u['serial_number']?.toString() ?? '')
                .where((s) => s.isNotEmpty)
                .toList();
            _availableSerialNumbers.sort();

            // 🔥 CRITICAL FIX: Jika Serial Number yang disimpan tidak ada di list (unit pindah/dll)
            // Tetap tambahkan ke list agar dropdown tidak error/kosong
            if (currentSerial != null && currentSerial.isNotEmpty) {
              if (!_availableSerialNumbers.contains(currentSerial)) {
                _availableSerialNumbers.add(currentSerial);
              }
            }
          }
        });
      }
    } catch (e) {
      developer.log('Error preloading edit data: $e');
    } finally {
      if (mounted) {
        setState(() {
          loadingLocations = false;
          loadingUnits = false;
        });
      }
    }
  }

  void _addChangeListeners() {
    final controllers = [
      partnerCtrl,
      vehicleCtrl,
      nopolCtrl,
      dateCtrl,
      unitSerialCtrl,
      unitTypeCtrl,
      snChargerCtrl,
      chargerTypeCtrl,
      chargerYearCtrl,
      problemDateCtrl,
      rfuDateCtrl,
      problemCtrl,
      actionCtrl,
    ];
    for (final c in controllers) {
      c.addListener(_onFormChanged);
    }
  }

  void _onFormChanged() {
    if (!_hasUnsavedChanges) setState(() => _hasUnsavedChanges = true);
  }

  String _getStatusMekanikFromUserStatus(String statusUser) {
    final upper = statusUser.toUpperCase();
    if (upper.contains('FIELD SERVICE')) return 'Field Service';
    if (upper.contains('FMC')) return 'FMC';
    return 'Field Service';
  }

  // ===== API CALLS =====

  Future<void> _loadPartners() async {
    setState(() => loadingPartners = true);
    try {
      final partners = await api.fetchPartnersByBranch(
        widget.user.branch,
        currentUserName: widget.user.name,
      );
      if (mounted) setState(() => partnerList = partners);
    } catch (e) {
      developer.log('Error loading partners: $e');
    } finally {
      if (mounted) setState(() => loadingPartners = false);
    }
  }

  Future<void> _loadCustomers() async {
    setState(() => loadingCustomers = true);
    try {
      final customers = await api.getCustomersByBranch(widget.user.branch);
      if (mounted) setState(() => customerList = customers);
    } catch (e) {
      developer.log('Error loading customers: $e');
    } finally {
      if (mounted) setState(() => loadingCustomers = false);
    }
  }

  Future<void> _onCustomerChanged(String customer) async {
    setState(() {
      customerCtrl.text = customer;
      locationCtrl.clear();
      unitTypeCtrl.clear();
      unitSerialCtrl.clear();
      locationList = [];
      _allUnitsAtLocation = [];
      _availableUnitTypes = [];
      _availableSerialNumbers = [];
      loadingLocations = true;
    });
    _onFormChanged();

    try {
      final locations = await api.getLocationsByCustomer(
        customer,
        widget.user.branch,
      );
      if (mounted) setState(() => locationList = locations);
    } catch (e) {
      developer.log('Error loading locations: $e');
    } finally {
      if (mounted) setState(() => loadingLocations = false);
    }
  }

  Future<void> _onLocationChanged(String location) async {
    setState(() {
      locationCtrl.text = location;
      unitTypeCtrl.clear();
      unitSerialCtrl.clear();
      _allUnitsAtLocation = [];
      _availableUnitTypes = [];
      _availableSerialNumbers = [];
    });
    _onFormChanged();

    await _loadUnitsForLocation(customerCtrl.text, location);
  }

  Future<void> _loadUnitsForLocation(String customer, String location) async {
    if (customer.isEmpty || location.isEmpty) return;
    setState(() => loadingUnits = true);

    try {
      final units = await api.getUnitsByCustomerLocation(
        customer,
        location,
        widget.user.branch,
      );

      if (mounted) {
        setState(() {
          _allUnitsAtLocation = units;
          _availableUnitTypes = units
              .map((u) => u['unit_type']?.toString() ?? '')
              .where((t) => t.isNotEmpty)
              .toSet()
              .toList();
          _availableUnitTypes.sort();
        });
      }
    } catch (e) {
      developer.log('Error loading units: $e');
    } finally {
      if (mounted) setState(() => loadingUnits = false);
    }
  }

  void _onUnitTypeChanged(String type) {
    setState(() {
      unitTypeCtrl.text = type;
      unitSerialCtrl.clear();

      _availableSerialNumbers = _allUnitsAtLocation
          .where((u) => u['unit_type'] == type)
          .map((u) => u['serial_number']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
      _availableSerialNumbers.sort();
    });
    _onFormChanged();
  }

  void _onUnitSerialChanged(String serial) {
    setState(() {
      unitSerialCtrl.text = serial;
    });
    _onFormChanged();
  }

  // ===== TOGGLE JOB TYPE (CHIPS) =====
  void _onJobTypeToggled(String type, bool selected) {
    setState(() {
      if (selected) {
        selectedJobTypes.add(type);
      } else {
        selectedJobTypes.remove(type);
      }
      _onFormChanged();
    });
  }

  // ===== UTILS =====
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

  // ===== SUBMIT =====

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (customerCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Customer harus diisi')));
      return;
    }
    if (unitSerialCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Serial Number Unit harus dipilih')),
      );
      return;
    }
    if (selectedJobTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu Job Type')),
      );
      return;
    }

    // Join List menjadi String Komma
    final jobTypeString = selectedJobTypes.join(',');

    developer.log('📝 SENDING JOB TYPE: $jobTypeString', name: 'ChargerForm');

    final charger = Charger(
      id: widget.charger?.id,
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
      serialNumber: unitSerialCtrl.text.trim(),
      unitType: unitTypeCtrl.text.trim(),
      snCharger: snChargerCtrl.text.trim(),
      chargerType: chargerTypeCtrl.text.trim(),
      chargerYear: int.tryParse(chargerYearCtrl.text.trim()),
      jobType: jobTypeString,
      categoryJob: categoryJobVal,
      statusUnit: statusUnitVal,
      problemDate: problemDate == null
          ? null
          : DateFormat('yyyy-MM-dd').format(problemDate!),
      rfuDate: rfuDate == null
          ? null
          : DateFormat('yyyy-MM-dd').format(rfuDate!),
      problem: problemCtrl.text.trim(),
      action: actionCtrl.text.trim(),
      recommendations: recommendations,
      installParts: installParts,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      Map<String, dynamic> res;
      if (widget.charger == null) {
        res = await api.createCharger(charger);
      } else {
        res = await api.updateCharger(charger);
      }

      if (!mounted) return;
      Navigator.pop(context);

      if (res['ok'] == true) {
        setState(() => _hasUnsavedChanges = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sukses: ${res['message'] ?? 'OK'}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: ${res['message']}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<PartItem?> _openPartModal({
    required bool isInstall,
    PartItem? initial,
  }) async {
    final res = await showDialog<PartItem>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PartDialog(isInstall: isInstall, initial: initial),
    );
    if (res != null) _onFormChanged();
    return res;
  }

  Future<void> _onAddRecommendation() async {
    final item = await _openPartModal(isInstall: false, initial: null);
    if (item != null) setState(() => recommendations.add(item));
  }

  Future<void> _onAddInstallPart() async {
    final item = await _openPartModal(isInstall: true, initial: null);
    if (item != null) setState(() => installParts.add(item));
  }

  void _onCancel() {
    Navigator.of(context).pop(false);
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
    unitTypeCtrl.dispose();
    unitSerialCtrl.dispose();
    snChargerCtrl.dispose();
    chargerTypeCtrl.dispose();
    chargerYearCtrl.dispose();
    problemDateCtrl.dispose();
    rfuDateCtrl.dispose();
    problemCtrl.dispose();
    actionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(widget.charger == null ? 'Tambah Charger' : 'Edit Charger'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. INFO TEKNISI
                _buildCard('Informasi Teknisi', [
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
                    decoration: _buildInputDecoration('PIC', isReadOnly: true),
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
                              items: partnerList
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => partnerCtrl.text = v);
                                  _onFormChanged();
                                }
                              },
                            ),
                          ),
                        ),
                ]),
                const SizedBox(height: 16),

                // 2. KENDARAAN & WAKTU
                _buildCard('Kendaraan & Waktu', [
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
                            decoration: _buildInputDecoration('IN (HH:MM)'),
                            child: Text(_fmtTime(inTime)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickTime(
                            context,
                            outTime,
                            (t) => setState(() => outTime = t),
                          ),
                          child: InputDecorator(
                            decoration: _buildInputDecoration('OUT (HH:MM)'),
                            child: Text(_fmtTime(outTime)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: vehicleCtrl,
                    decoration: _buildInputDecoration('VEHICLE'),
                    validator: (v) => v?.isEmpty ?? true ? 'Isi!' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nopolCtrl,
                    decoration: _buildInputDecoration('NOPOL'),
                    validator: (v) => v?.isEmpty ?? true ? 'Isi!' : null,
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => _pickDate(
                      context,
                      date,
                      (d) => setState(() {
                        date = d;
                        dateCtrl.text = _fmtDate(d);
                      }),
                    ),
                    child: InputDecorator(
                      decoration: _buildInputDecoration('DATE'),
                      child: Text(
                        dateCtrl.text.isEmpty ? 'Pilih Tanggal' : dateCtrl.text,
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),

                // 3. UNIT INFO
                _buildCard('Unit Info (Pilih Unit)', [
                  loadingCustomers
                      ? const LinearProgressIndicator()
                      : InputDecorator(
                          decoration: _buildInputDecoration('CUSTOMER'),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: customerCtrl.text.isEmpty
                                  ? null
                                  : customerCtrl.text,
                              isExpanded: true,
                              hint: const Text('Pilih Customer'),
                              items: customerList
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) _onCustomerChanged(v);
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
                              value: locationCtrl.text.isEmpty
                                  ? null
                                  : locationCtrl.text,
                              isExpanded: true,
                              hint: const Text('Pilih Location'),
                              items: locationList
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) _onLocationChanged(v);
                              },
                            ),
                          ),
                        ),
                  const SizedBox(height: 12),
                  loadingUnits
                      ? const LinearProgressIndicator()
                      : InputDecorator(
                          decoration: _buildInputDecoration('UNIT TYPE'),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: unitTypeCtrl.text.isEmpty
                                  ? null
                                  : unitTypeCtrl.text,
                              isExpanded: true,
                              hint: _allUnitsAtLocation.isEmpty
                                  ? const Text('Pilih Location Dulu')
                                  : const Text('Pilih Unit Type'),
                              items: _availableUnitTypes
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _allUnitsAtLocation.isEmpty
                                  ? null
                                  : (v) {
                                      if (v != null) _onUnitTypeChanged(v);
                                    },
                            ),
                          ),
                        ),
                  const SizedBox(height: 12),
                  InputDecorator(
                    decoration: _buildInputDecoration('UNIT SERIAL NUMBER'),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value:
                            _availableSerialNumbers.contains(
                              unitSerialCtrl.text,
                            )
                            ? unitSerialCtrl.text
                            : null,
                        isExpanded: true,
                        hint: _availableSerialNumbers.isEmpty
                            ? const Text('Pilih Unit Type Dulu')
                            : const Text('Pilih SN'),
                        items: _availableSerialNumbers
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: _availableSerialNumbers.isEmpty
                            ? null
                            : (v) {
                                if (v != null) _onUnitSerialChanged(v);
                              },
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),

                // 4. CHARGER INFO
                _buildCard('Informasi Charger', [
                  TextFormField(
                    controller: snChargerCtrl,
                    decoration: _buildInputDecoration('CHARGER SN'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: chargerTypeCtrl,
                    decoration: _buildInputDecoration('CHARGER TYPE'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: chargerYearCtrl,
                    decoration: _buildInputDecoration('CHARGER YEAR'),
                    keyboardType: TextInputType.number,
                  ),
                ]),
                const SizedBox(height: 16),

                // 5. JOB TYPE & STATUS
                _buildCard('Job Type & Status', [
                  InputDecorator(
                    decoration: _buildInputDecoration('CATEGORY JOB'),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: categoryJobVal.isEmpty
                            ? availableCategoryJobs.first
                            : categoryJobVal,
                        isExpanded: true,
                        items: availableCategoryJobs
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => categoryJobVal = v);
                            _onFormChanged();
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 🔥🔥 MODIFIKASI: Tombol Chips untuk Job Type 🔥🔥
                  const Text(
                    'JOB TYPE',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: availableJobTypes.map((type) {
                      final isSelected = selectedJobTypes.contains(type);
                      return FilterChip(
                        label: Text(type),
                        selected: isSelected,
                        selectedColor: primaryColor.withValues(alpha: 0.2),
                        checkmarkColor: primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected ? primaryColor : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        onSelected: (bool selected) {
                          _onJobTypeToggled(type, selected);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  InputDecorator(
                    decoration: _buildInputDecoration('STATUS UNIT'),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: statusUnitVal,
                        isExpanded: true,
                        items: ['RFU', 'BREAKDOWN', 'MONITORING']
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => statusUnitVal = v);
                            _onFormChanged();
                          }
                        },
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),

                // 6. PROBLEM & ACTION
                _buildCard('Problem & Action', [
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDate(
                            context,
                            problemDate,
                            (d) => setState(() {
                              problemDate = d;
                              problemDateCtrl.text = _fmtDate(d);
                            }),
                          ),
                          child: InputDecorator(
                            decoration: _buildInputDecoration('PROBLEM DATE'),
                            child: Text(problemDateCtrl.text),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDate(
                            context,
                            rfuDate,
                            (d) => setState(() {
                              rfuDate = d;
                              rfuDateCtrl.text = _fmtDate(d);
                            }),
                          ),
                          child: InputDecorator(
                            decoration: _buildInputDecoration('RFU DATE'),
                            child: Text(rfuDateCtrl.text),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: problemCtrl,
                    decoration: _buildInputDecoration('PROBLEM'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: actionCtrl,
                    decoration: _buildInputDecoration('ACTION'),
                    maxLines: 10,
                  ),
                ]),
                const SizedBox(height: 16),

                // 7. PARTS
                _buildPartSection('Recommendations', recommendations, false),
                const SizedBox(height: 16),
                _buildPartSection('Install Parts', installParts, true),
                const SizedBox(height: 24),

                // BUTTONS
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _onCancel,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
                        ),
                        child: Text(
                          widget.charger == null ? 'Simpan' : 'Update',
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
    );
  }

  Widget _buildCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildPartSection(String title, List<PartItem> items, bool isInstall) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: isInstall
                      ? _onAddInstallPart
                      : _onAddRecommendation,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No items added',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            for (int i = 0; i < items.length; i++)
              ListTile(
                title: Text(
                  '${items[i].partNumber ?? '-'} — ${items[i].partName ?? '-'}',
                ),
                subtitle: Text('Qty: ${items[i].qty ?? 0}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () async {
                        final edited = await _openPartModal(
                          isInstall: isInstall,
                          initial: items[i],
                        );
                        if (edited != null) setState(() => items[i] = edited);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => setState(() => items.removeAt(i)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PartDialog extends StatefulWidget {
  final bool isInstall;
  final PartItem? initial;
  const PartDialog({super.key, required this.isInstall, this.initial});

  @override
  State<PartDialog> createState() => _PartDialogState();
}

class _PartDialogState extends State<PartDialog> {
  late final TextEditingController pnCtrl;
  late final TextEditingController nameCtrl;
  late final TextEditingController qtyCtrl;
  late final TextEditingController remarksCtrl;
  late final TextEditingController noJobCtrl;
  late final TextEditingController noPrCtrl;
  final Color primaryColor = const Color(0xFF2C5AA0);

  @override
  void initState() {
    super.initState();
    pnCtrl = TextEditingController(text: widget.initial?.partNumber ?? '');
    nameCtrl = TextEditingController(text: widget.initial?.partName ?? '');
    qtyCtrl = TextEditingController(
      text: widget.initial?.qty?.toString() ?? '1',
    );
    remarksCtrl = TextEditingController(text: widget.initial?.remarks ?? '');
    noJobCtrl = TextEditingController(text: widget.initial?.noJob ?? '');
    noPrCtrl = TextEditingController(text: widget.initial?.noPr ?? '');
  }

  @override
  void dispose() {
    pnCtrl.dispose();
    nameCtrl.dispose();
    qtyCtrl.dispose();
    remarksCtrl.dispose();
    noJobCtrl.dispose();
    noPrCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final pn = pnCtrl.text.trim();
    final name = nameCtrl.text.trim();
    final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;

    if (pn.isEmpty && name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi Part Number atau Part Name')),
      );
      return;
    }
    if (qty <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Qty harus > 0')));
      return;
    }

    final item = PartItem(
      partNumber: pn.isEmpty ? null : pn,
      partName: name.isEmpty ? null : name,
      qty: qty,
      remarks: remarksCtrl.text.trim().isEmpty ? null : remarksCtrl.text.trim(),
      noJob: widget.isInstall
          ? (noJobCtrl.text.trim().isEmpty ? null : noJobCtrl.text.trim())
          : null,
      noPr: widget.isInstall
          ? (noPrCtrl.text.trim().isEmpty ? null : noPrCtrl.text.trim())
          : null,
    );
    Navigator.of(context).pop(item);
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.isInstall
                  ? (widget.initial != null
                        ? 'Edit Install Part'
                        : 'Add Install Part')
                  : (widget.initial != null
                        ? 'Edit Recommendation'
                        : 'Add Recommendation'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextFormField(
                      controller: pnCtrl,
                      decoration: _buildInputDecoration('PART NUMBER'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: _buildInputDecoration('PART NAME'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _buildInputDecoration('QTY'),
                    ),
                    if (widget.isInstall) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: noJobCtrl,
                        decoration: _buildInputDecoration('NO JOB'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: noPrCtrl,
                        decoration: _buildInputDecoration('NO PR'),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: remarksCtrl,
                      decoration: _buildInputDecoration('REMARKS'),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(null),
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
                    ),
                    child: Text(widget.initial != null ? 'Update' : 'Tambah'),
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
