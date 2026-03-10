// lib/models/charger.dart
import 'dart:convert';
import 'dart:developer';

class Charger {
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
  String? serialNumber; // Unit Serial Number
  String? unitType; // Unit Type

  // Charger Info
  String? snCharger; // Charger Serial Number
  String? chargerType;
  int? chargerYear;

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

  Charger({
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
    this.snCharger,
    this.chargerType,
    this.chargerYear,
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

  factory Charger.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String && value.isNotEmpty) return int.tryParse(value);
      return null;
    }

    String? parseString(dynamic value) => value?.toString();

    // Logic khusus untuk menangani Job Type agar selalu String bersih
    String? parseJobType(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is List) {
        // Jika API lama masih kirim Array, convert ke string
        return value.join(',');
      }
      return value.toString();
    }

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
      } catch (e) {
        log('Error parsing part items: $e');
        return [];
      }
      return [];
    }

    return Charger(
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
      snCharger: parseString(json['sn_charger']),
      chargerType: parseString(json['charger_type']),
      chargerYear: parseInt(json['charger_year']),
      jobType: parseJobType(json['job_type']), // Gunakan logic baru
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
      'sn_charger': snCharger,
      'charger_type': chargerType,
      'charger_year': chargerYear,
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
