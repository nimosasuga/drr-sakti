import 'update_job.dart'; // ✅ TAMBAH IMPORT INI

class User {
  final int id;
  final String name;
  final String nrpp;
  final String statusUser;
  final String branch;
  final String token;
  final String role; // 🆕 tambahkan ini

  User({
    required this.id,
    required this.name,
    required this.nrpp,
    required this.statusUser,
    required this.branch,
    required this.token,
    required this.role, // 🆕
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      nrpp: json['nrpp'] ?? '',
      statusUser: json['status_user'] ?? json['statusUser'] ?? '',
      branch: json['branch'] ?? '',
      token: json['token'] ?? '',
      role: json['role'] ?? json['status_user'] ?? '', // 🆕 fallback
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nrpp': nrpp,
      'status_user': statusUser,
      'branch': branch,
      'token': token,
    };
  }

  // Helper methods to check user roles
  bool get isSuperAdmin => statusUser.toUpperCase().contains('ADMIN DRR');
  bool get isFieldService => statusUser.toUpperCase().contains('FIELD SERVICE');
  bool get isFMC => statusUser.toUpperCase().contains('FMC');
  bool get isCoordinator => statusUser.toUpperCase().contains('KOORDINATOR');

  // ===== UNIT ASSETS PERMISSIONS =====
  bool get canViewAllUnits => isSuperAdmin;
  bool get canCreateUnit => isSuperAdmin || isCoordinator ;
  bool get canEditUnit => isSuperAdmin || isCoordinator;
  bool get canDeleteUnit => isSuperAdmin || isCoordinator;

  // Check if user can access specific unit data
  bool canAccessUnit(String unitBranch) {
    if (isSuperAdmin) return true;
    return branch.toUpperCase() == unitBranch.toUpperCase();
  }

  // ===== UPDATE JOBS PERMISSIONS =====
  bool get canViewAllJobs => isSuperAdmin;
  bool get canCreateJob =>
      isSuperAdmin || isFieldService || isFMC || isCoordinator;

  // Field Service/FMC can only edit/delete their own jobs
  bool canEditJob(UpdateJob job) {
    if (isSuperAdmin) return true;
    if (isCoordinator) return canAccessJob(job);
    if (isFieldService || isFMC) {
      return canAccessJob(job) && (job.pic == name || job.pic == nrpp);
    }
    return false;
  }

  bool canDeleteJob(UpdateJob job) {
    if (isSuperAdmin) return true;
    if (isCoordinator) return canAccessJob(job);
    if (isFieldService || isFMC) {
      return canAccessJob(job) && (job.pic == name || job.pic == nrpp);
    }
    return false;
  }

  bool canAccessJob(UpdateJob job) {
    if (isSuperAdmin) return true;
    return branch.toUpperCase() == (job.branch ?? '').toUpperCase();
  }

  // Check if user can access data from specific branch
  bool canAccessBranch(String dataBranch) {
    if (isSuperAdmin) return true;
    return branch.toUpperCase() == dataBranch.toUpperCase();
  }
}
