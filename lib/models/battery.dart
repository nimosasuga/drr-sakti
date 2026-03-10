// lib/models/battery.dart
import 'dart:convert';
import 'dart:developer' as developer;

class Battery {
  int? id;
  String? branch;
  String? statusMekanik;
  String? pic;
  String? partner;
  String? inTime;
  String? outTime;
  String? vehicle;
  String? nopol;
  String? date;

  // Unit Info
  String? customer;
  String? location;
  String? serialNumber;
  String? unitType;

  // Battery Info
  String? snBattery;
  String? batteryType;
  int? batteryYear;

  String? jobType;
  String? statusUnit;
  String? problemDate;
  String? rfuDate;
  String? problem;
  String? action;
  List<PartItem>? recommendations;
  List<PartItem>? installParts;
  String? createdAt;
  String? updatedAt;
  String? categoryJob;

  Battery({
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
    this.customer,
    this.location,
    this.serialNumber,
    this.unitType,
    this.snBattery,
    this.batteryType,
    this.batteryYear,
    this.jobType,
    this.statusUnit,
    this.problemDate,
    this.rfuDate,
    this.problem,
    this.action,
    this.recommendations,
    this.installParts,
    this.createdAt,
    this.updatedAt,
    this.categoryJob,
  });

  factory Battery.fromJson(Map<String, dynamic> json) {
    // Helper untuk menangani berbagai format angka
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String && value.isNotEmpty) return int.tryParse(value);
      return null;
    }

    // Helper untuk menangani string (termasuk konversi List ke String)
    String? parseString(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        return value.join(',');
      } // Jika API kirim Array, gabung jadi string
      return value.toString();
    }

    dynamic rawJobType = json['job_type'];

    // Debug logging untuk melacak masalah
    developer.log(
      '🔥 RAW JOB TYPE FROM API: $rawJobType',
      name: 'BatteryModel',
    );
    developer.log(
      '🔥 RAW JOB TYPE TYPE: ${rawJobType.runtimeType}',
      name: 'BatteryModel',
    );

    String? finalJobType;

    if (rawJobType == null) {
      finalJobType = null;
    } else if (rawJobType is String) {
      // Cek jika string mengandung karakter array JSON
      if (rawJobType.contains('[') && rawJobType.contains(']')) {
        try {
          final parsed = jsonDecode(rawJobType);
          if (parsed is List) {
            finalJobType = parsed.join(',');
          } else {
            finalJobType = rawJobType;
          }
        } catch (e) {
          developer.log(
            '⚠️ Gagal parse job_type sebagai JSON: $e',
            name: 'BatteryModel',
          );
          finalJobType = rawJobType;
        }
      } else {
        // String biasa, langsung pakai
        finalJobType = rawJobType;
      }
    } else if (rawJobType is List) {
      // Sudah dalam format List, join jadi string
      finalJobType = rawJobType.join(',');
    } else {
      // Fallback: convert to string
      finalJobType = rawJobType.toString();
    }

    developer.log('✅ FINAL JOB TYPE: $finalJobType', name: 'BatteryModel');

    List<PartItem> parsePartItems(dynamic data) {
      if (data == null) return [];
      try {
        final parsed = data is String ? jsonDecode(data) : data;
        if (parsed is List) {
          return parsed
              .map(
                (e) => PartItem.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList();
        }
      } catch (_) {
        return [];
      }
      return [];
    }

    return Battery(
      id: parseInt(json['id']),
      branch: parseString(json['branch']),
      statusMekanik: parseString(json['status_mekanik']),
      pic: parseString(json['pic']),
      partner: parseString(json['partner']),
      inTime: parseString(json['in_time']),
      outTime: parseString(json['out_time']),
      vehicle: parseString(json['vehicle']),
      nopol: parseString(json['nopol']),
      date: parseString(json['date']),
      customer: parseString(json['customer']),
      location: parseString(json['location']),
      serialNumber: parseString(json['serial_number']),
      unitType: parseString(json['unit_type']),
      snBattery: parseString(json['sn_battery']),
      batteryType: parseString(json['battery_type']),
      batteryYear: parseInt(json['battery_year']),

      // Menggunakan hasil pencarian multi-key
      jobType: finalJobType,

      statusUnit: parseString(json['status_unit']),
      problemDate: parseString(json['problem_date']),
      rfuDate: parseString(json['rfu_date']),
      problem: parseString(json['problem']),
      action: parseString(json['action']),
      recommendations: parsePartItems(json['recommendations_json']),
      installParts: parsePartItems(json['install_parts_json']),
      createdAt: parseString(json['created_at']),
      updatedAt: parseString(json['updated_at']),
      categoryJob: parseString(json['category_job']),
    );
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
      'customer': customer,
      'location': location,
      'serial_number': serialNumber,
      'unit_type': unitType,
      'sn_battery': snBattery,
      'battery_type': batteryType,
      'battery_year': batteryYear,
      'job_type': jobType,
      'status_unit': statusUnit,
      'problem_date': problemDate,
      'rfu_date': rfuDate,
      'problem': problem,
      'action': action,
      'recommendations_json': recommendations?.map((e) => e.toJson()).toList(),
      'install_parts_json': installParts?.map((e) => e.toJson()).toList(),
      'category_job': categoryJob,
    };
  }
}

class PartItem {
  String? partNumber;
  String? partName;
  int? qty;
  String? noJob;
  String? noPr;
  String? remarks;

  PartItem({
    this.partNumber,
    this.partName,
    this.qty,
    this.noJob,
    this.noPr,
    this.remarks,
  });

  factory PartItem.fromJson(Map<String, dynamic> json) {
    return PartItem(
      partNumber:
          json['part_number']?.toString() ?? json['partNumber']?.toString(),
      partName: json['part_name']?.toString() ?? json['partName']?.toString(),
      qty: int.tryParse(json['qty']?.toString() ?? '0'),
      noJob: json['no_job']?.toString() ?? json['noJob']?.toString(),
      noPr: json['no_pr']?.toString() ?? json['noPr']?.toString(),
      remarks: json['remarks']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'part_number': partNumber,
    'part_name': partName,
    'qty': qty,
    'no_job': noJob,
    'no_pr': noPr,
    'remarks': remarks,
  };
}
