import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:developer';
import 'dart:convert';
import '../../models/update_job.dart';
import '../../models/user.dart';
import '../../models/unit.dart';
import '../../services/api_service.dart';
import '../update_job/update_job_detail_screen.dart';

class UpdateJobForm extends StatefulWidget {
  final UpdateJob? job;
  final User user;
  const UpdateJobForm({super.key, this.job, required this.user});

  @override
  State<UpdateJobForm> createState() => _UpdateJobFormState();
}

class _UpdateJobFormState extends State<UpdateJobForm> {
  final _formKey = GlobalKey<FormState>();
  final ApiService api = ApiService();

  // Track form changes for back confirmation
  bool _hasUnsavedChanges = false;

  // controllers for main fields
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

  late TextEditingController serialCtrl;
  late TextEditingController unitTypeCtrl;
  late TextEditingController yearCtrl;
  late TextEditingController hourMeterCtrl;
  late TextEditingController nomorLambungCtrl;
  late TextEditingController customerCtrl;
  late TextEditingController locationCtrl;

  String statusMekanikVal = 'Field Service';
  String jobTypeVal = 'Preventive Maintenance';
  String statusUnitVal = 'RFU';

  DateTime? problemDate;
  late TextEditingController problemDateCtrl;
  DateTime? rfuDate;
  late TextEditingController rfuDateCtrl;

  late TextEditingController leadTimeRfuCtrl;
  bool pmVal = false;
  bool rmVal = false;
  late TextEditingController problemCtrl;
  late TextEditingController actionCtrl;

  // parts lists
  List<PartItem> recommendations = [];
  List<PartItem> installParts = [];

  // Data untuk dropdowns
  List<String> partnerList = [];
  List<Unit> unitList = [];
  List<String> serialNumberList = [];
  bool loadingPartners = false;
  bool loadingUnits = false;

  // Multi select job type
  List<String> selectedJobTypes = [];
  final List<String> availableJobTypes = [
    'Preventive Maintenance',
    'Install Part',
    'Troubleshooting',
    'Inspection',
    'Repair',
  ];

  // Professional color scheme
  final Color primaryColor = const Color(0xFF2C5AA0);
  final Color secondaryColor = const Color(0xFF4CAF50);
  final Color backgroundColor = const Color(0xFFF8F9FA);
  final Color cardColor = Colors.white;
  final Color borderColor = const Color(0xFFE0E0E0);
  final Color textColor = const Color(0xFF333333);
  final Color disabledColor = const Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    final j = widget.job;

    // Initialize controllers
    _initializeControllers(j);

    // Set initial state for unsaved changes
    _hasUnsavedChanges = widget.job == null;

    // Load data untuk dropdowns
    _loadPartners();
    _loadUnits();
  }

  void _initializeControllers(UpdateJob? j) {
    branchCtrl = TextEditingController(text: widget.user.branch);

    statusMekanikVal = _getStatusMekanikFromUserStatus(widget.user.statusUser);
    statusMekanikCtrl = TextEditingController(text: statusMekanikVal);

    picCtrl = TextEditingController(text: widget.user.name);

    partnerCtrl = TextEditingController(text: j?.partner ?? '');

    inTime = _parseTime(j?.inTime);
    outTime = _parseTime(j?.outTime);
    vehicleCtrl = TextEditingController(text: j?.vehicle ?? '');
    nopolCtrl = TextEditingController(text: j?.nopol ?? '');

    date = _parseDate(j?.date);
    dateCtrl = TextEditingController(text: _fmtDate(date));

    serialCtrl = TextEditingController(text: j?.serialNumber ?? '');
    unitTypeCtrl = TextEditingController(text: j?.unitType ?? '');
    yearCtrl = TextEditingController(text: j?.year?.toString() ?? '');
    hourMeterCtrl = TextEditingController(text: j?.hourMeter ?? '');
    nomorLambungCtrl = TextEditingController(text: j?.nomorLambung ?? '');
    customerCtrl = TextEditingController(text: j?.customer ?? '');
    locationCtrl = TextEditingController(text: j?.location ?? '');

    jobTypeVal = j?.jobType ?? 'Preventive Maintenance';
    if (j?.jobType != null && j!.jobType!.isNotEmpty) {
      selectedJobTypes = j.jobType!.split(',').map((e) => e.trim()).toList();
    } else {
      selectedJobTypes = ['Preventive Maintenance'];
    }

    statusUnitVal = j?.statusUnit ?? 'RFU';

    problemDate = _parseDate(j?.problemDate);
    problemDateCtrl = TextEditingController(text: _fmtDate(problemDate));
    rfuDate = _parseDate(j?.rfuDate);
    rfuDateCtrl = TextEditingController(text: _fmtDate(rfuDate));

    leadTimeRfuCtrl = TextEditingController(text: j?.leadTimeRfu ?? '');

    pmVal = j?.pm ?? (statusUnitVal == 'RFU');
    rmVal = j?.rm ?? (statusUnitVal == 'BREAKDOWN');

    problemCtrl = TextEditingController(text: j?.problem ?? '');
    actionCtrl = TextEditingController(text: j?.action ?? '');

    recommendations = List<PartItem>.from(j?.recommendations ?? []);
    installParts = List<PartItem>.from(j?.installParts ?? []);

    _addChangeListeners();
  }

  void _addChangeListeners() {
    final controllers = [
      partnerCtrl,
      vehicleCtrl,
      nopolCtrl,
      dateCtrl,
      serialCtrl,
      unitTypeCtrl,
      yearCtrl,
      hourMeterCtrl,
      nomorLambungCtrl,
      customerCtrl,
      locationCtrl,
      problemDateCtrl,
      rfuDateCtrl,
      leadTimeRfuCtrl,
      problemCtrl,
      actionCtrl,
    ];

    for (final controller in controllers) {
      controller.addListener(_onFormChanged);
    }
  }

  void _onFormChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  // Back confirmation dialog
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

  String _getStatusMekanikFromUserStatus(String statusUser) {
    if (statusUser.toUpperCase().contains('FIELD SERVICE')) {
      return 'Field Service';
    } else if (statusUser.toUpperCase().contains('FMC')) {
      return 'FMC';
    } else if (statusUser.toUpperCase().contains('KOORDINATOR')) {
      return 'Field Service';
    } else if (statusUser.toUpperCase().contains('ADMIN')) {
      return 'Field Service';
    } else {
      return 'Field Service';
    }
  }

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
      log('Error loading partners: $e');
    } finally {
      if (mounted) {
        setState(() => loadingPartners = false);
      }
    }
  }

  Future<void> _loadUnits() async {
    setState(() => loadingUnits = true);
    try {
      List<Unit> units;
      if (widget.user.canViewAllUnits) {
        units = await api.fetchUnits();
      } else {
        units = await api.fetchUnitsByBranch(widget.user.branch);
      }

      setState(() {
        unitList = units;
        serialNumberList = units
            .where(
              (unit) =>
                  unit.serialNumber != null && unit.serialNumber!.isNotEmpty,
            )
            .map((unit) => unit.serialNumber!)
            .toList();
      });
    } catch (e) {
      log('Error loading units: $e');
    } finally {
      setState(() => loadingUnits = false);
    }
  }

  void _onSerialNumberChanged(String value) {
    if (value.isNotEmpty) {
      final unit = unitList.firstWhere(
        (u) => u.serialNumber == value,
        orElse: () => Unit(),
      );

      if (unit.serialNumber != null) {
        setState(() {
          unitTypeCtrl.text = unit.unitType ?? '';
          customerCtrl.text = unit.customer ?? '';
          locationCtrl.text = unit.location ?? '';
          yearCtrl.text = unit.year?.toString() ?? '';
        });
        _onFormChanged();
      }
    } else {
      setState(() {
        unitTypeCtrl.text = '';
        customerCtrl.text = '';
        locationCtrl.text = '';
        yearCtrl.text = '';
      });
      _onFormChanged();
    }
  }

  void _onStatusUnitChanged(String value) {
    setState(() {
      statusUnitVal = value;

      // Auto set PM dan RM values (tersembunyi dari UI)
      if (value == 'RFU') {
        pmVal = true;
        rmVal = false;
      } else if (value == 'BREAKDOWN') {
        pmVal = false;
        rmVal = true;
      }
    });
    _onFormChanged();
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
    serialCtrl.dispose();
    unitTypeCtrl.dispose();
    yearCtrl.dispose();
    hourMeterCtrl.dispose();
    nomorLambungCtrl.dispose();
    customerCtrl.dispose();
    locationCtrl.dispose();
    problemDateCtrl.dispose();
    rfuDateCtrl.dispose();
    leadTimeRfuCtrl.dispose();
    problemCtrl.dispose();
    actionCtrl.dispose();
    super.dispose();
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

  String _fmtTime(TimeOfDay? t) => t == null ? '' : t.format(context);

  Future<PartItem?> _openPartModal({
    required bool isInstall,
    PartItem? initial,
  }) async {
    final res = await showDialog<PartItem>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PartDialog(isInstall: isInstall, initial: initial),
    );
    if (res != null) {
      _onFormChanged();
    }
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
    if (_hasUnsavedChanges) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard Changes?'),
          content: const Text(
            'You have unsaved changes. Are you sure you want to discard them?',
          ),
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

  Future<void> _submit() async {
    log('=== BEFORE SUBMIT DEBUG ===');
    log('IN Time: $inTime');
    log('OUT Time: $outTime');
    log('Date: $date');
    log('Hour Meter: ${hourMeterCtrl.text}');

    // Validasi form dasar
    if (!_formKey.currentState!.validate()) {
      log('❌ Form validation failed');
      return;
    }

    // Validasi manual untuk field yang wajib
    if (inTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('IN (HH:MM) harus diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (outTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OUT (HH:MM) harus diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('DATE harus diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (hourMeterCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('HOUR METER harus diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validasi serial number atau customer
    if (serialCtrl.text.trim().isEmpty && customerCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Serial Number atau Customer harus diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Pastikan PIC tidak kosong
    if (picCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIC harus diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final job = UpdateJob(
      id: widget.job?.id,
      branch: branchCtrl.text.trim(),
      statusMekanik: statusMekanikVal,
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
      serialNumber: serialCtrl.text.trim(),
      unitType: unitTypeCtrl.text.trim(),
      year: int.tryParse(yearCtrl.text.trim()),
      hourMeter: hourMeterCtrl.text.trim(),
      nomorLambung: nomorLambungCtrl.text.trim(),
      customer: customerCtrl.text.trim(),
      location: locationCtrl.text.trim(),
      jobType: jobTypeVal,
      statusUnit: statusUnitVal,
      problemDate: problemDate == null
          ? null
          : DateFormat('yyyy-MM-dd').format(problemDate!),
      rfuDate: rfuDate == null
          ? null
          : DateFormat('yyyy-MM-dd').format(rfuDate!),
      leadTimeRfu: leadTimeRfuCtrl.text.trim(),
      pm: pmVal,
      rm: rmVal,
      problem: problemCtrl.text.trim(),
      action: actionCtrl.text.trim(),
      recommendations: recommendations,
      installParts: installParts,
    );

    log('=== JOB TO SEND ===');
    log('JSON: ${json.encode(job.toJson())}');

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      Map<String, dynamic> res;
      if (widget.job == null) {
        res = await api.createUpdateJob(job);
      } else {
        res = await api.updateUpdateJob(job);
      }

      if (!mounted) return;
      Navigator.pop(context);

      log('=== API RESPONSE ===');
      log('Success: ${res['ok']}');
      log('Message: ${res['message']}');

      if (res['ok'] == true || res['success'] == true) {
        setState(() {
          _hasUnsavedChanges = false;
        });

        if (!mounted) return;

        final jobId = res['id'] ?? job.id;

        if (jobId != null) {
          try {
            final updatedJob = await api.fetchUpdateJob(jobId);

            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Sukses: ${res['message'] ?? 'OK'}'),
                backgroundColor: Colors.green,
              ),
            );

            if (updatedJob != null) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      UpdateJobDetailScreen(job: updatedJob, user: widget.user),
                ),
              );
            } else {
              Navigator.pop(context, true);
            }
          } catch (fetchError) {
            log('Error fetching updated job: $fetchError');
            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Berhasil disimpan, kembali ke list...'),
                backgroundColor: Colors.green,
              ),
            );

            Navigator.pop(context, true);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Sukses: ${res['message'] ?? 'OK'}'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal: ${res['message'] ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exception: $e'), backgroundColor: Colors.red),
        );
      }
      log('❌ EXCEPTION: $e');
    }
  }

  Widget _buildHeader() {
    return AppBar(
      title: Text(
        widget.job == null ? 'Tambah Update Job' : 'Edit Update Job',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: primaryColor,
      elevation: 2,
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  InputDecoration _buildInputDecoration(
    String label, {
    bool isReadOnly = false,
    bool isRequired = false,
  }) {
    return InputDecoration(
      labelText: isRequired ? '$label *' : label,
      labelStyle: TextStyle(
        color: textColor.withAlpha(179),
        fontWeight: isRequired ? FontWeight.w600 : FontWeight.normal,
      ),
      filled: true,
      fillColor: isReadOnly ? disabledColor : cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isRequired ? Colors.red.withAlpha(128) : borderColor,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> statusUnits = [
      'RFU',
      'Breakdown',
      'Monitoring',
      'Waiting Part',
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: _buildHeader(),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ID (read-only)
                  if (widget.job?.id != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: primaryColor.withAlpha(76)),
                      ),
                      child: Text(
                        'ID: ${widget.job!.id}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  if (widget.job?.id != null) const SizedBox(height: 16),

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
                              : partnerList.isEmpty
                              ? Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.orange),
                                  ),
                                  child: Text(
                                    'Tidak ada partner tersedia untuk branch ini',
                                    style: TextStyle(color: Colors.orange[800]),
                                  ),
                                )
                              : InputDecorator(
                                  decoration: _buildInputDecoration('PARTNER'),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: partnerCtrl.text.isEmpty
                                          ? null
                                          : partnerCtrl.text,
                                      isExpanded: true,
                                      hint: Text(
                                        'Pilih Partner',
                                        style: TextStyle(
                                          color: textColor.withAlpha(128),
                                        ),
                                      ),
                                      items: partnerList.map((String value) {
                                        final isDisabled =
                                            value == 'No partners available';
                                        return DropdownMenuItem<String>(
                                          value: isDisabled ? null : value,
                                          child: Text(
                                            value,
                                            style: TextStyle(
                                              color: isDisabled
                                                  ? Colors.grey
                                                  : textColor,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        if (newValue != null) {
                                          setState(() {
                                            partnerCtrl.text = newValue;
                                          });
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
                            'Informasi Kendaraan & Waktu',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // IN/OUT times - WAJIB DIISI
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => _pickTime(
                                    context,
                                    inTime,
                                    (t) => setState(() {
                                      inTime = t;
                                    }),
                                  ),
                                  child: InputDecorator(
                                    decoration: _buildInputDecoration(
                                      'IN (HH:MM)',
                                      isRequired: true,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          inTime == null
                                              ? 'Pilih Waktu'
                                              : _fmtTime(inTime),
                                          style: TextStyle(
                                            color: inTime == null
                                                ? Colors.grey
                                                : textColor,
                                          ),
                                        ),
                                        const Icon(Icons.access_time, size: 20),
                                      ],
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
                                    (t) => setState(() {
                                      outTime = t;
                                    }),
                                  ),
                                  child: InputDecorator(
                                    decoration: _buildInputDecoration(
                                      'OUT (HH:MM)',
                                      isRequired: true,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          outTime == null
                                              ? 'Pilih Waktu'
                                              : _fmtTime(outTime),
                                          style: TextStyle(
                                            color: outTime == null
                                                ? Colors.grey
                                                : textColor,
                                          ),
                                        ),
                                        const Icon(Icons.access_time, size: 20),
                                      ],
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
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: nopolCtrl,
                            decoration: _buildInputDecoration('NOPOL'),
                          ),
                          const SizedBox(height: 12),

                          // DATE - WAJIB DIISI
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
                              decoration: _buildInputDecoration(
                                'DATE',
                                isRequired: true,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    dateCtrl.text.isEmpty
                                        ? 'Pilih Tanggal'
                                        : dateCtrl.text,
                                    style: TextStyle(
                                      color: dateCtrl.text.isEmpty
                                          ? Colors.grey
                                          : textColor,
                                    ),
                                  ),
                                  const Icon(Icons.calendar_today, size: 20),
                                ],
                              ),
                            ),
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
                            'Informasi Unit',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),

                          loadingUnits
                              ? const LinearProgressIndicator()
                              : Autocomplete<String>(
                                  optionsBuilder:
                                      (TextEditingValue textEditingValue) {
                                        if (textEditingValue.text.isEmpty) {
                                          return const Iterable<String>.empty();
                                        }
                                        return serialNumberList.where((
                                          String option,
                                        ) {
                                          return option.toLowerCase().contains(
                                            textEditingValue.text.toLowerCase(),
                                          );
                                        });
                                      },
                                  onSelected: (String selection) {
                                    setState(() {
                                      serialCtrl.text = selection;
                                      _onSerialNumberChanged(selection);
                                    });
                                  },
                                  fieldViewBuilder:
                                      (
                                        BuildContext context,
                                        TextEditingController
                                        textEditingController,
                                        FocusNode focusNode,
                                        VoidCallback onFieldSubmitted,
                                      ) {
                                        if (textEditingController.text !=
                                            serialCtrl.text) {
                                          textEditingController.text =
                                              serialCtrl.text;
                                        }
                                        return TextFormField(
                                          controller: textEditingController,
                                          focusNode: focusNode,
                                          decoration:
                                              _buildInputDecoration(
                                                'SERIAL NUMBER',
                                              ).copyWith(
                                                suffixIcon: const Icon(
                                                  Icons.search,
                                                ),
                                              ),
                                          onChanged: (value) {
                                            setState(() {
                                              serialCtrl.text = value;
                                              _onSerialNumberChanged(value);
                                            });
                                          },
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Serial Number harus diisi';
                                            }
                                            return null;
                                          },
                                        );
                                      },
                                ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: unitTypeCtrl,
                            decoration: _buildInputDecoration(
                              'UNIT TYPE',
                              isReadOnly: true,
                            ),
                            readOnly: true,
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
                                    isRequired: true,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Wajib diisi';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: nomorLambungCtrl,
                            decoration: _buildInputDecoration('NOMOR LAMBUNG'),
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: customerCtrl,
                            decoration: _buildInputDecoration(
                              'CUSTOMER',
                              isReadOnly: true,
                            ),
                            readOnly: true,
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: locationCtrl,
                            decoration: _buildInputDecoration(
                              'LOCATION',
                              isReadOnly: true,
                            ),
                            readOnly: true,
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
                            'Status & Maintenance',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),

                          const Text(
                            'JOB TYPE',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 4.0,
                            children: availableJobTypes.map((type) {
                              final isSelected = selectedJobTypes.contains(
                                type,
                              );
                              return FilterChip(
                                label: Text(type),
                                selected: isSelected,
                                selectedColor: primaryColor.withAlpha(25),
                                checkmarkColor: primaryColor,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? primaryColor
                                      : Colors.black87,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                onSelected: (bool selected) {
                                  setState(() {
                                    if (selected) {
                                      selectedJobTypes.add(type);
                                    } else {
                                      selectedJobTypes.remove(type);
                                    }
                                    jobTypeVal = selectedJobTypes.join(', ');
                                  });
                                  _onFormChanged();
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),

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
                                _onStatusUnitChanged(v);
                              }
                            },
                            decoration: _buildInputDecoration('STATUS UNIT'),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => _pickDate(
                                    context,
                                    problemDate,
                                    (d) => setState(() {
                                      problemDate = d;
                                      problemDateCtrl.text = _fmtDate(
                                        problemDate,
                                      );
                                    }),
                                  ),
                                  child: InputDecorator(
                                    decoration: _buildInputDecoration(
                                      'PROBLEM DATE',
                                    ),
                                    child: Text(
                                      problemDateCtrl.text.isEmpty
                                          ? 'Pilih Tanggal'
                                          : problemDateCtrl.text,
                                      style: TextStyle(
                                        color: problemDateCtrl.text.isEmpty
                                            ? Colors.grey
                                            : textColor,
                                      ),
                                    ),
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
                                      rfuDateCtrl.text = _fmtDate(rfuDate);
                                    }),
                                  ),
                                  child: InputDecorator(
                                    decoration: _buildInputDecoration(
                                      'RFU DATE',
                                    ),
                                    child: Text(
                                      rfuDateCtrl.text.isEmpty
                                          ? 'Pilih Tanggal'
                                          : rfuDateCtrl.text,
                                      style: TextStyle(
                                        color: rfuDateCtrl.text.isEmpty
                                            ? Colors.grey
                                            : textColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // LEAD TIME RFU, PM, dan RM - DISEMBUNYIKAN
                          // Field ini tetap ada tapi tidak ditampilkan di UI
                          // Nilai PM dan RM akan otomatis diset berdasarkan STATUS UNIT
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
                            'Detail Masalah & Tindakan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: problemCtrl,
                            decoration: _buildInputDecoration('PROBLEM'),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: actionCtrl,
                            decoration: _buildInputDecoration('ACTION'),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Recommendations container
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
                                'Recommendations',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _onAddRecommendation,
                                icon: const Icon(Icons.add, size: 20),
                                label: const Text('Add'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (recommendations.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'No recommendations added',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: textColor.withAlpha(128),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          for (int i = 0; i < recommendations.length; i++)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: borderColor),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                title: Text(
                                  '${recommendations[i].partNumber ?? '-'} — ${recommendations[i].partName ?? '-'}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                ),
                                subtitle: Text(
                                  'Qty: ${recommendations[i].qty ?? 0}${(recommendations[i].remarks != null && recommendations[i].remarks!.isNotEmpty) ? ' • ${recommendations[i].remarks}' : ''}',
                                ),
                                onTap: () async {
                                  final edited = await _openPartModal(
                                    isInstall: false,
                                    initial: recommendations[i],
                                  );
                                  if (edited != null) {
                                    setState(() => recommendations[i] = edited);
                                  }
                                },
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        size: 20,
                                        color: primaryColor,
                                      ),
                                      onPressed: () async {
                                        final edited = await _openPartModal(
                                          isInstall: false,
                                          initial: recommendations[i],
                                        );
                                        if (edited != null) {
                                          setState(
                                            () => recommendations[i] = edited,
                                          );
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        size: 20,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => setState(
                                        () => recommendations.removeAt(i),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Install Part container
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
                                'Install Part',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _onAddInstallPart,
                                icon: const Icon(Icons.add, size: 20),
                                label: const Text('Add'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (installParts.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'No install parts added',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: textColor.withAlpha(128),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          for (int i = 0; i < installParts.length; i++)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: borderColor),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                title: Text(
                                  '${installParts[i].partNumber ?? '-'} — ${installParts[i].partName ?? '-'}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                ),
                                subtitle: Text(
                                  'Qty: ${installParts[i].qty ?? 0} • NoJob:${installParts[i].noJob ?? '-'} • NoPR:${installParts[i].noPr ?? '-'}${(installParts[i].remarks != null && installParts[i].remarks!.isNotEmpty) ? ' • ${installParts[i].remarks}' : ''}',
                                ),
                                onTap: () async {
                                  final edited = await _openPartModal(
                                    isInstall: true,
                                    initial: installParts[i],
                                  );
                                  if (edited != null) {
                                    setState(() => installParts[i] = edited);
                                  }
                                },
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        size: 20,
                                        color: primaryColor,
                                      ),
                                      onPressed: () async {
                                        final edited = await _openPartModal(
                                          isInstall: true,
                                          initial: installParts[i],
                                        );
                                        if (edited != null) {
                                          setState(
                                            () => installParts[i] = edited,
                                          );
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        size: 20,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => setState(
                                        () => installParts.removeAt(i),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action buttons
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
                          child: Text(widget.job == null ? 'Simpan' : 'Update'),
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

// PartDialog class tetap sama seperti sebelumnya
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

  final FocusNode _pnFocus = FocusNode();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _qtyFocus = FocusNode();
  final FocusNode _noJobFocus = FocusNode();
  final FocusNode _noPrFocus = FocusNode();
  final FocusNode _remarksFocus = FocusNode();

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
    _pnFocus.dispose();
    _nameFocus.dispose();
    _qtyFocus.dispose();
    _noJobFocus.dispose();
    _noPrFocus.dispose();
    _remarksFocus.dispose();
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
      _nameFocus.requestFocus();
      return;
    }
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Qty harus lebih besar dari 0')),
      );
      _qtyFocus.requestFocus();
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

  InputDecoration _buildDialogInputDecoration(String label) {
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
      elevation: 4,
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: pnCtrl,
                      focusNode: _pnFocus,
                      textInputAction: TextInputAction.next,
                      decoration: _buildDialogInputDecoration('PART NUMBER'),
                      onFieldSubmitted: (_) => _nameFocus.requestFocus(),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameCtrl,
                      focusNode: _nameFocus,
                      textInputAction: TextInputAction.next,
                      decoration: _buildDialogInputDecoration('PART NAME'),
                      onFieldSubmitted: (_) => _qtyFocus.requestFocus(),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: qtyCtrl,
                      focusNode: _qtyFocus,
                      keyboardType: TextInputType.number,
                      textInputAction: widget.isInstall
                          ? TextInputAction.next
                          : TextInputAction.done,
                      decoration: _buildDialogInputDecoration('QTY'),
                      onFieldSubmitted: (_) {
                        if (widget.isInstall) {
                          _noJobFocus.requestFocus();
                        } else {
                          _remarksFocus.requestFocus();
                        }
                      },
                    ),
                    if (widget.isInstall) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: noJobCtrl,
                        focusNode: _noJobFocus,
                        textInputAction: TextInputAction.next,
                        decoration: _buildDialogInputDecoration('NO JOB'),
                        onFieldSubmitted: (_) => _noPrFocus.requestFocus(),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: noPrCtrl,
                        focusNode: _noPrFocus,
                        textInputAction: TextInputAction.next,
                        decoration: _buildDialogInputDecoration('NO PR'),
                        onFieldSubmitted: (_) => _remarksFocus.requestFocus(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: remarksCtrl,
                      focusNode: _remarksFocus,
                      textInputAction: TextInputAction.newline,
                      decoration: _buildDialogInputDecoration('REMARKS'),
                      maxLines: 3,
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
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(widget.initial != null ? 'Simpan' : 'Tambah'),
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
