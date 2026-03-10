// lib/models/delivery.dart

class Delivery {
  // Field data sesuai dengan kolom di tabel delivery_units
  final String id;
  final String branch;
  final String? statusMekanik;
  final String? pic;
  final String? partner;
  final String? inTime; // Tipe Time di DB
  final String? outTime; // Tipe Time di DB
  final String? vehicle;
  final String? nopol;
  final String date; // Tipe Date di DB
  final String? customer;
  final String? location;
  final String? serialNumber;
  final String? unitType;
  final int? year;
  final int? hourMeter;
  final String? jobType; // Disimpan sebagai JSON string di DB
  final String? statusUnit;
  final String? batteryType;
  final String? batterySn;
  final String? chargerType;
  final String? chargerSn;
  final String? trolly;
  final String? note;
  final String? createdAt; // Tipe Timestamp di DB
  final String? updatedAt; // Tipe Timestamp di DB

  // Constructor
  Delivery({
    required this.id,
    required this.branch,
    required this.date,
    this.statusMekanik,
    this.pic,
    this.partner,
    this.inTime,
    this.outTime,
    this.vehicle,
    this.nopol,
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

  // Factory Constructor untuk konversi dari JSON (Map<String, dynamic>)
  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      id: json['id'] as String,
      branch: json['branch'] as String,
      statusMekanik: json['status_mekanik'] as String?,
      pic: json['pic'] as String?,
      partner: json['partner'] as String?,
      inTime: json['in_time'] as String?,
      outTime: json['out_time'] as String?,
      vehicle: json['vehicle'] as String?,
      nopol: json['nopol'] as String?,
      date: json['date'] as String,
      customer: json['customer'] as String?,
      location: json['location'] as String?,
      serialNumber: json['serial_number'] as String?,
      unitType: json['unit_type'] as String?,
      // Pastikan konversi tipe data Int
      year: json['year'] != null ? int.tryParse(json['year'].toString()) : null,
      hourMeter: json['hour_meter'] != null
          ? int.tryParse(json['hour_meter'].toString())
          : null,
      jobType: json['job_type'] as String?,
      statusUnit: json['status_unit'] as String?,
      batteryType: json['battery_type'] as String?,
      batterySn: json['battery_sn'] as String?,
      chargerType: json['charger_type'] as String?,
      chargerSn: json['charger_sn'] as String?,
      trolly: json['trolly'] as String?,
      note: json['note'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  // Method untuk konversi ke JSON (Map<String, dynamic>) untuk dikirim ke API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
      'job_type': jobType,
      'status_unit': statusUnit,
      'battery_type': batteryType,
      'battery_sn': batterySn,
      'charger_type': chargerType,
      'charger_sn': chargerSn,
      'trolly': trolly,
      'note': note,
      // created_at dan updated_at biasanya tidak dikirim saat membuat/mengubah
    };
  }
}
