// lib/models/update_job.dart
import 'dart:convert';
import 'dart:developer';

/// Model kecil untuk satu entry part (dipakai untuk Recommendations & Install Parts)
class PartItem {
  String? partNumber;
  String? partName;
  int? qty;
  String? remarks;
  String? noJob; // only for install part
  String? noPr; // only for install part

  PartItem({
    this.partNumber,
    this.partName,
    this.qty,
    this.remarks,
    this.noJob,
    this.noPr,
  });

  factory PartItem.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    return PartItem(
      partNumber:
          json['part_number']?.toString() ?? json['partNumber']?.toString(),
      partName: json['part_name']?.toString() ?? json['partName']?.toString(),
      qty: parseInt(json['qty'] ?? json['Qty']),
      remarks: json['remarks']?.toString(),
      noJob: json['no_job']?.toString() ?? json['noJob']?.toString(),
      noPr: json['no_pr']?.toString() ?? json['noPr']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (partNumber != null) 'part_number': partNumber,
      if (partName != null) 'part_name': partName,
      if (qty != null) 'qty': qty,
      if (remarks != null) 'remarks': remarks,
      if (noJob != null) 'no_job': noJob,
      if (noPr != null) 'no_pr': noPr,
    };
  }

  PartItem copyWith({
    String? partNumber,
    String? partName,
    int? qty,
    String? remarks,
    String? noJob,
    String? noPr,
  }) {
    return PartItem(
      partNumber: partNumber ?? this.partNumber,
      partName: partName ?? this.partName,
      qty: qty ?? this.qty,
      remarks: remarks ?? this.remarks,
      noJob: noJob ?? this.noJob,
      noPr: noPr ?? this.noPr,
    );
  }

  @override
  String toString() {
    return 'PartItem(partNumber: $partNumber, partName: $partName, qty: $qty, remarks: $remarks, noJob: $noJob, noPr: $noPr)';
  }
}

/// Model utama UpdateJob
class UpdateJob {
  int? id;
  String? branch;
  String? statusMekanik; // Field Service / FMC
  String? pic;
  String? partner;
  String? inTime; // "HH:mm"
  String? outTime; // "HH:mm"
  String? vehicle;
  String? nopol;
  String? date; // "yyyy-MM-dd"
  String? serialNumber;
  String? unitType;
  int? year;
  String? hourMeter;
  String? nomorLambung;
  String? customer;
  String? location;
  String? jobType; // Preventive Maintenance, Install, ...
  String? statusUnit; // RFU, Breakdown, Monitoring, Waiting Part
  String? problemDate;
  String? rfuDate;
  String? leadTimeRfu;
  bool? pm;
  bool? rm;
  String? problem;
  String? action;

  // parts
  List<PartItem>? recommendations;
  List<PartItem>? installParts;

  // meta
  String? createdAt;
  String? updatedAt;

  UpdateJob({
    this.id,
    this.branch,
    this.statusMekanik,
    this.pic,
    this.partner,
    this.inTime,
    this.outTime,
    this.vehicle,
    this.nopol,
    this.date,
    this.serialNumber,
    this.unitType,
    this.year,
    this.hourMeter,
    this.nomorLambung,
    this.customer,
    this.location,
    this.jobType,
    this.statusUnit,
    this.problemDate,
    this.rfuDate,
    this.leadTimeRfu,
    this.pm,
    this.rm,
    this.problem,
    this.action,
    this.recommendations,
    this.installParts,
    this.createdAt,
    this.updatedAt,
  });

  static dynamic _tryJsonDecode(String s) {
    try {
      return json.decode(s);
    } catch (_) {
      return null;
    }
  }

  static List<PartItem>? _parseParts(dynamic raw) {
    if (raw == null) return null;

    // if already a List<PartItem>
    if (raw is List<PartItem>) return raw;

    // if list (of maps)
    if (raw is List) {
      try {
        return raw.map<PartItem>((e) {
          if (e is PartItem) return e;
          if (e is Map) return PartItem.fromJson(Map<String, dynamic>.from(e));
          return PartItem.fromJson(Map<String, dynamic>.from(e as Map));
        }).toList();
      } catch (_) {
        // fallthrough
      }
    }

    // if string: maybe JSON string
    if (raw is String && raw.isNotEmpty) {
      final dec = _tryJsonDecode(raw);
      if (dec is List) {
        try {
          return dec.map<PartItem>((e) {
            if (e is PartItem) return e;
            return PartItem.fromJson(Map<String, dynamic>.from(e as Map));
          }).toList();
        } catch (_) {
          return null;
        }
      }
    }

    return null;
  }

  factory UpdateJob.fromJson(Map<String, dynamic> jsonMap) {
    log('=== PARSING UPDATE JOB ===');
    log('Raw JSON keys: ${jsonMap.keys}');

    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      final parsed = int.tryParse(v.toString());
      log('Parsing $v to int: $parsed');
      return parsed;
    }

    bool? parseBool(dynamic v) {
      if (v == null) return null;
      if (v is bool) return v;
      if (v is int) return v == 1;
      if (v is String) return v == '1' || v.toLowerCase() == 'true';
      return false;
    }

    // combine variants: recommendations or recommendations_json
    final recRaw =
        jsonMap['recommendations'] ??
        jsonMap['recommendations_json'] ??
        jsonMap['recommendationsJson'];

    final instRaw =
        jsonMap['install_parts'] ??
        jsonMap['install_parts_json'] ??
        jsonMap['installParts'];

    log('Recommendations raw: $recRaw');
    log('Install parts raw: $instRaw');

    final job = UpdateJob(
      id: parseInt(jsonMap['id'] ?? jsonMap['ID']),
      branch: jsonMap['branch']?.toString(),
      statusMekanik:
          jsonMap['status_mekanik']?.toString() ??
          jsonMap['statusMekanik']?.toString(),
      pic: jsonMap['pic']?.toString(),
      partner: jsonMap['partner']?.toString(),
      inTime: jsonMap['in_time']?.toString() ?? jsonMap['inTime']?.toString(),
      outTime:
          jsonMap['out_time']?.toString() ?? jsonMap['outTime']?.toString(),
      vehicle: jsonMap['vehicle']?.toString(),
      nopol: jsonMap['nopol']?.toString(),
      date: jsonMap['date']?.toString(),
      serialNumber:
          jsonMap['serial_number']?.toString() ??
          jsonMap['serialNumber']?.toString(),
      unitType:
          jsonMap['unit_type']?.toString() ?? jsonMap['unitType']?.toString(),
      year: parseInt(jsonMap['year']),
      hourMeter:
          jsonMap['hour_meter']?.toString() ?? jsonMap['hourMeter']?.toString(),
      nomorLambung:
          jsonMap['nomor_lambung']?.toString() ??
          jsonMap['nomorLambung']?.toString(),
      customer: jsonMap['customer']?.toString(),
      location: jsonMap['location']?.toString(),
      jobType:
          jsonMap['job_type']?.toString() ?? jsonMap['jobType']?.toString(),
      statusUnit:
          jsonMap['status_unit']?.toString() ??
          jsonMap['statusUnit']?.toString(),
      problemDate:
          jsonMap['problem_date']?.toString() ??
          jsonMap['problemDate']?.toString(),
      rfuDate:
          jsonMap['rfu_date']?.toString() ?? jsonMap['rfuDate']?.toString(),
      leadTimeRfu:
          jsonMap['lead_time_rfu']?.toString() ??
          jsonMap['leadTimeRfu']?.toString(),
      pm: parseBool(jsonMap['pm']),
      rm: parseBool(jsonMap['rm']),
      problem: jsonMap['problem']?.toString(),
      action: jsonMap['action']?.toString(),
      recommendations: _parseParts(recRaw),
      installParts: _parseParts(instRaw),
      createdAt:
          jsonMap['created_at']?.toString() ?? jsonMap['createdAt']?.toString(),
      updatedAt:
          jsonMap['updated_at']?.toString() ?? jsonMap['updatedAt']?.toString(),
    );

    log('=== PARSED JOB ===');
    log('ID: ${job.id}');
    log('Branch: ${job.branch}');
    log('Serial: ${job.serialNumber}');
    log('Customer: ${job.customer}');
    log('PIC: ${job.pic}');
    log('Recommendations count: ${job.recommendations?.length ?? 0}');
    log('Install parts count: ${job.installParts?.length ?? 0}');

    return job;
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'branch': branch,
      'status_mekanik': statusMekanik,
      'pic': pic,
      'partner': partner,
      'in_time': inTime,
      'out_time': outTime,
      'vehicle': vehicle,
      'nopol': nopol,
      'date': date,
      'serial_number': serialNumber,
      'unit_type': unitType,
      'year': year,
      'hour_meter': hourMeter,
      'nomor_lambung': nomorLambung,
      'customer': customer,
      'location': location,
      'job_type': jobType,
      'status_unit': statusUnit,
      'problem_date': problemDate,
      'rfu_date': rfuDate,
      'lead_time_rfu': leadTimeRfu,
      'pm': pm == true ? 1 : 0,
      'rm': rm == true ? 1 : 0,
      'problem': problem,
      'action': action,
      // recommendations & install parts as arrays (server will accept arrays; server code can json_encode again)
      'recommendations': recommendations?.map((e) => e.toJson()).toList(),
      'install_parts': installParts?.map((e) => e.toJson()).toList(),
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  UpdateJob copyWith({
    int? id,
    String? branch,
    String? statusMekanik,
    String? pic,
    String? partner,
    String? inTime,
    String? outTime,
    String? vehicle,
    String? nopol,
    String? date,
    String? serialNumber,
    String? unitType,
    int? year,
    String? hourMeter,
    String? nomorLambung,
    String? customer,
    String? location,
    String? jobType,
    String? statusUnit,
    String? problemDate,
    String? rfuDate,
    String? leadTimeRfu,
    bool? pm,
    bool? rm,
    String? problem,
    String? action,
    List<PartItem>? recommendations,
    List<PartItem>? installParts,
    String? createdAt,
    String? updatedAt,
  }) {
    return UpdateJob(
      id: id ?? this.id,
      branch: branch ?? this.branch,
      statusMekanik: statusMekanik ?? this.statusMekanik,
      pic: pic ?? this.pic,
      partner: partner ?? this.partner,
      inTime: inTime ?? this.inTime,
      outTime: outTime ?? this.outTime,
      vehicle: vehicle ?? this.vehicle,
      nopol: nopol ?? this.nopol,
      date: date ?? this.date,
      serialNumber: serialNumber ?? this.serialNumber,
      unitType: unitType ?? this.unitType,
      year: year ?? this.year,
      hourMeter: hourMeter ?? this.hourMeter,
      nomorLambung: nomorLambung ?? this.nomorLambung,
      customer: customer ?? this.customer,
      location: location ?? this.location,
      jobType: jobType ?? this.jobType,
      statusUnit: statusUnit ?? this.statusUnit,
      problemDate: problemDate ?? this.problemDate,
      rfuDate: rfuDate ?? this.rfuDate,
      leadTimeRfu: leadTimeRfu ?? this.leadTimeRfu,
      pm: pm ?? this.pm,
      rm: rm ?? this.rm,
      problem: problem ?? this.problem,
      action: action ?? this.action,
      recommendations: recommendations ?? this.recommendations,
      installParts: installParts ?? this.installParts,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UpdateJob(id: $id, branch: $branch, serialNumber: $serialNumber, customer: $customer, pic: $pic, statusUnit: $statusUnit)';
  }
}
