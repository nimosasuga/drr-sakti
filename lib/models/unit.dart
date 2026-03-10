// lib/models/unit.dart
class Unit {
  int? id;
  String? supportedBy;
  String? customer;
  String? location;
  String? branch;
  String? serialNumber;
  String? unitType;
  int? year;
  String? status;
  String? delivery; // yyyy-MM-dd
  String? jenisUnit;
  String? note;
  String? createdAt;
  String? updatedAt;
  final String? hourMeter;
  final String? statusUnit;

  Unit({
    this.id,
    this.supportedBy,
    this.customer,
    this.location,
    this.branch,
    this.serialNumber,
    this.unitType,
    this.year,
    this.status,
    this.delivery,
    this.jenisUnit,
    this.note,
    this.createdAt,
    this.updatedAt,
    this.hourMeter = '',
    this.statusUnit,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      final s = v.toString();
      return int.tryParse(s);
    }

    return Unit(
      id: parseInt(json['id']),
      supportedBy: json['supported_by']?.toString(),
      customer: json['customer']?.toString(),
      location: json['location']?.toString(),
      branch: json['branch']?.toString(),
      serialNumber: json['serial_number']?.toString(),
      unitType: json['unit_type']?.toString(),
      year: parseInt(json['year']),
      status: json['status']?.toString(),
      delivery: json['delivery']?.toString(),
      jenisUnit: json['jenis_unit']?.toString(),
      note: json['note']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      hourMeter: json['hour_meter']?.toString() ?? '',
      statusUnit: json['status_unit']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'supported_by': supportedBy,
      'customer': customer,
      'location': location,
      'branch': branch,
      'serial_number': serialNumber,
      'unit_type': unitType,
      'year': year,
      'status': status,
      'delivery': delivery,
      'jenis_unit': jenisUnit,
      'note': note,
    };
  }
}
