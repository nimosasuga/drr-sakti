// lib/models/penarikan.dart
import 'dart:convert';
class Penarikan {
  String? id; // UUID format
  String? branch;
  String? statusMekanik;
  String? pic;
  String? partner;
  String? inTime; // HH:mm format
  String? outTime; // HH:mm format
  String? vehicle;
  String? nopol;
  String? date; // yyyy-MM-dd format
  String? customer;
  String? location;
  String? serialNumber;
  String? unitType;
  int? year;
  String? hourMeter;
  List<String>?
  jobType; // Multi-select: ["TARIK UNIT", "TARIK BATTERY", "TARIK CHARGER"]
  String? statusUnit; // Single select: "RFU" or "BREAKDOWN"
  String? batteryType;
  String? batterySn;
  String? chargerType;
  String? chargerSn;
  String? trolly;
  String? note;
  String? createdAt;
  String? updatedAt;

  Penarikan({
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
    this.year,
    this.hourMeter,
    this.jobType,
    this.statusUnit,
    this.batteryType,
    this.batterySn,
    this.chargerType,
    this.chargerSn,
    this.trolly,
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  factory Penarikan.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    // Parse job_type - bisa berupa string JSON array atau list
    List<String>? parseJobType(dynamic raw) {
      if (raw == null) return null;

      if (raw is List) {
        return raw.map((e) => e.toString()).toList();
      }

      if (raw is String && raw.isNotEmpty) {
        try {
if (raw.startsWith('[') && raw.endsWith(']')) {
            final decoded = jsonDecode(raw);
            if (decoded is List) {
              return decoded.map((e) => e.toString()).toList();
            }
          }
          // Jika tidak bisa di-parse sebagai array JSON, perlakukan sebagai satu item string
          return [raw];
        } catch (_) {
          return [raw];
        }
      }

      return null;
    }

    return Penarikan(
      id: json['id']?.toString(),
      branch: json['branch']?.toString(),
      statusMekanik: json['status_mekanik']?.toString(),
      pic: json['pic']?.toString(),
      partner: json['partner']?.toString(),
      inTime: json['in_time']?.toString(),
      outTime: json['out_time']?.toString(),
      vehicle: json['vehicle']?.toString(),
      nopol: json['nopol']?.toString(),
      date: json['date']?.toString(),
      customer: json['customer']?.toString(),
      location: json['location']?.toString(),
      serialNumber: json['serial_number']?.toString(),
      unitType: json['unit_type']?.toString(),
      year: parseInt(json['year']),
      hourMeter: json['hour_meter']?.toString(),
      jobType: parseJobType(json['job_type']),
      statusUnit: json['status_unit']?.toString(),
      batteryType: json['battery_type']?.toString(),
      batterySn: json['battery_sn']?.toString(),
      chargerType: json['charger_type']?.toString(),
      chargerSn: json['charger_sn']?.toString(),
      trolly: json['trolly']?.toString(),
      note: json['note']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
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
      'year': year,
      'hour_meter': hourMeter,
      'job_type': jobType, // Will be sent as array
      'status_unit': statusUnit,
      'battery_type': batteryType,
      'battery_sn': batterySn,
      'charger_type': chargerType,
      'charger_sn': chargerSn,
      'trolly': trolly,
      'note': note,
    };
  }

  Penarikan copyWith({
    String? id,
    String? branch,
    String? statusMekanik,
    String? pic,
    String? partner,
    String? inTime,
    String? outTime,
    String? vehicle,
    String? nopol,
    String? date,
    String? customer,
    String? location,
    String? serialNumber,
    String? unitType,
    int? year,
    String? hourMeter,
    List<String>? jobType,
    String? statusUnit,
    String? batteryType,
    String? batterySn,
    String? chargerType,
    String? chargerSn,
    String? trolly,
    String? note,
    String? createdAt,
    String? updatedAt,
  }) {
    return Penarikan(
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
      customer: customer ?? this.customer,
      location: location ?? this.location,
      serialNumber: serialNumber ?? this.serialNumber,
      unitType: unitType ?? this.unitType,
      year: year ?? this.year,
      hourMeter: hourMeter ?? this.hourMeter,
      jobType: jobType ?? this.jobType,
      statusUnit: statusUnit ?? this.statusUnit,
      batteryType: batteryType ?? this.batteryType,
      batterySn: batterySn ?? this.batterySn,
      chargerType: chargerType ?? this.chargerType,
      chargerSn: chargerSn ?? this.chargerSn,
      trolly: trolly ?? this.trolly,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Penarikan(id: $id, branch: $branch, customer: $customer, serialNumber: $serialNumber, statusUnit: $statusUnit)';
  }
}
