// lib/constants/constants.dart
import 'package:flutter/foundation.dart'; // Wajib diimpor untuk kDebugMode

class AppConstants {
  // ===================================
  // API Configuration - ADAPTIF
  // ===================================
  // URL untuk mode produksi (release) - Menggunakan HTTPS
  static const String _productionBaseUrl = 'https://drr.exprosa.com/api';

  // URL untuk mode development (debug) - Menggunakan HTTP
  static const String _developmentBaseUrl = 'https://drr.exprosa.com/api';

  // Getter yang mengembalikan Base URL yang tepat
  static String get baseUrl {
    if (kDebugMode) {
      return _developmentBaseUrl; // Menggunakan HTTP saat development
    }
    return _productionBaseUrl; // Menggunakan HTTPS saat production
  }
  // ===================================

  // Core Endpoints (Units & Update Jobs)
  static const String loginEndpoint = '/login.php';
  static const String unitsEndpoint = '/read_by_branch.php';
  static const String updateJobsEndpoint = '/read_update_jobs_by_branch.php';
  static const String createUpdateJobEndpoint = '/create_update_job.php';
  static const String updateUpdateJobEndpoint = '/update_update_job.php';
  static const String deleteUpdateJobEndpoint = '/delete_update_job.php';

  // Assets Management Endpoints
  static const String batteryEndpoint = '/battery/battery_api.php';
  static const String chargerEndpoint = '/charger/charger_api.php';

  // Logistics Endpoints (New Feature Group)
  static const String penarikanEndpoint = '/penarikan/penarikan_api.php';

  // Endpoint Baru untuk Delivery Units
  static const String deliveryEndpoint = '/delivery/delivery_units.php';

  // Dashboard & Analytics
  static const String dashboardStatsEndpoint = '/dashboard_stats.php';
  static const String mechanicStatsEndpoint = '/mechanic_stats.php';
  static const String unitStatsEndpoint = '/unit_stats.php';
  static const String jobPerformanceEndpoint =
      '/read_job_performance_by_branch.php';
  static const String partnersEndpoint = '/read_partners_by_branch.php';

  // Profile & Account Management Endpoints
  static const String changePasswordEndpoint = '/profile/change_password.php';

  // DeepSeek Chat Endpoint
  static const String deepseekChatEndpoint = '/deepseek/chat.php';

  // App Info
  static const String appName = 'DRR SAKTI';
  static const String appVersion = '2.1.0'; // Diperbarui dari v2.0.0 ke v2.1.0

  // Timeouts
  static const int apiTimeout = 30; // seconds
  static const int connectTimeout = 10; // seconds
  static const int receiveTimeout = 30; // seconds
}

class AppText {
  // App Strings
  static const String appTitle = 'DRR SAKTI';
  static const String appSubtitle = 'Unit Assets Management System';

  // Common Strings
  static const String loading = 'Memuat...';
  static const String error = 'Terjadi Kesalahan';
  static const String retry = 'Coba Lagi';
  static const String save = 'Simpan';
  static const String cancel = 'Batal';
  static const String delete = 'Hapus';
  static const String edit = 'Edit';
  static const String create = 'Buat Baru';
  static const String update = 'Perbarui';
  static const String search = 'Cari...';

  // Delivery Specific Strings
  static const String deliveryTitle = 'Delivery Units';
  static const String deliveryCreate = 'Tambah Delivery';
  static const String deliveryEdit = 'Edit Delivery';
  static const String deliverySuccess = 'Delivery berhasil disimpan';
  static const String deliveryError = 'Gagal menyimpan delivery';
  static const String deliveryConfirmDelete =
      'Apakah Anda yakin ingin menghapus data Delivery Unit ini?';

  // Penarikan Specific Strings (Sebagai contoh konsistensi)
  static const String penarikanTitle = 'Penarikan Units';
  static const String penarikanCreate = 'Tambah Penarikan';

  // Status Strings
  static const String statusRfu = 'RFU';
  static const String statusBreakdown = 'BREAKDOWN';
  static const String statusMonitoring = 'MONITORING';
  static const String statusWaitingPart = 'WAITING PART';
}

class AppDimensions {
  // ... (Tidak ada perubahan, dimensi tetap sama)
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;

  // Margin
  static const double marginXS = 4.0;
  static const double marginS = 8.0;
  static const double marginM = 16.0;
  static const double marginL = 24.0;
  static const double marginXL = 32.0;

  // Border Radius
  static const double borderRadiusS = 4.0;
  static const double borderRadiusM = 8.0;
  static const double borderRadiusL = 12.0;
  static const double borderRadiusXL = 16.0;

  // Icon Size
  static const double iconSizeXS = 16.0;
  static const double iconSizeS = 20.0;
  static const double iconSizeM = 24.0;
  static const double iconSizeL = 32.0;
  static const double iconSizeXL = 48.0;

  // Button Height
  static const double buttonHeightS = 36.0;
  static const double buttonHeightM = 44.0;
  static const double buttonHeightL = 52.0;
}

class AppAssets {
  // Image paths
  static const String logo = 'assets/images/logo.png';
  static const String placeholder = 'assets/images/placeholder.png';

  // Icon paths
  static const String iconDelivery = 'assets/icons/delivery.png';
  static const String iconPenarikan = 'assets/icons/penarikan.png';
  static const String iconBattery = 'assets/icons/battery.png';
  static const String iconCharger = 'assets/icons/charger.png';
}
