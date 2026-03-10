# Admin Dashboard - DRR SAKTI

## 📋 Fitur Admin Dashboard

Admin Dashboard adalah fitur khusus untuk **Super Admin** dan **Koordinator** yang menyediakan:

### 1. **Tab Statistik** 📊
- **Total Preventive Maintenance**
  - **Logic Baru**: Membandingkan total unit dari `unit_assets` dengan unit yang sudah ada job PM di `update_jobs`
  - Sudah PM: Unit yang serial_number-nya ada di update_jobs dengan jobType \"Preventive Maintenance\"
  - Belum PM: Total unit dikurangi yang sudah PM
  - Persentase completion
  - Progress bar visual

- **Doughnut Chart**
  - Visualisasi proporsi Sudah PM vs Belum PM
  - Warna hijau (success) untuk Sudah PM
  - Warna merah (error) untuk Belum PM

- **Bar Chart per Bulan**
  - Statistik PM per bulan (6 bulan terakhir)
  - Bar hijau untuk Sudah PM
  - Bar merah untuk Belum PM
  - Tooltip untuk detail data

### 2. **Tab Unit List** 📝
- **Filter Status PM**
  - Semua unit
  - Sudah PM
  - Belum PM

- **Informasi Unit**
  - Serial Number
  - Unit Type
  - Customer
  - Branch
  - Status PM (badge berwarna)

- **Visual Indicator**
  - Checkmark hijau: Sudah PM
  - X merah: Belum PM

### 3. **Tab Download** 📥
- **Download Excel/CSV**
  - Data update_jobs berdasarkan branch user
  - Format: CSV (comma-separated values)
  - Nama file: `update_jobs_[branch]_[timestamp].csv`
  - Otomatis tersimpan di folder Downloads

- **Kolom Data yang Diunduh:**
  - ID, Branch, Status Mekanik
  - PIC, Partner
  - In Time, Out Time
  - Vehicle, Nopol, Date
  - Serial Number, Unit Type, Year
  - Hour Meter, Nomor Lambung
  - Customer, Location
  - Job Type, Status Unit
  - Problem Date, RFU Date, Lead Time RFU
  - PM (Yes/No), RM (Yes/No)
  - Problem, Action

## 🚀 Cara Akses

1. **Login sebagai Super Admin atau Koordinator**
   - Super Admin: User dengan `statusUser` yang mengandung \"ADMIN DRR\"
   - Koordinator: User dengan `statusUser` yang mengandung \"KOORDINATOR\"

2. **Dari Home Screen**
   - **Buka Sidebar/Drawer** dengan:
     - Swipe dari kiri ke kanan
     - Atau tap icon hamburger menu (☰) di kiri atas AppBar
   - Pilih menu **\"Admin Dashboard\"** (dengan badge \"Admin\" berwarna orange)

3. **Navigation**
   - Gunakan tab bar untuk berpindah antar fitur
   - Pull-to-refresh untuk memperbarui data
   - Back button untuk kembali ke Home

## 📊 Logic Perhitungan PM (Updated)

### Total Preventive Maintenance
**Sumber Data:**
- `unit_assets` table: Total semua unit
- `update_jobs` table: Job dengan jobType \"Preventive Maintenance\"

**Perhitungan:**
```
Total Unit = Jumlah unique serial_number di unit_assets
Sudah PM = Jumlah unique serial_number yang ADA di update_jobs 
           dengan jobType mengandung \"PREVENTIVE\"
Belum PM = Total Unit - Sudah PM
Persentase = (Sudah PM / Total Unit) × 100%
```

**Contoh:**
- Total unit di unit_assets: 100 unit
- Unit yang ada job PM: 65 unit
- Hasil: **65 Sudah PM**, **35 Belum PM**, **65% Completed**

## 📱 UI/UX Features

- **Sidebar Navigation**: Menu drawer dengan user profile header
- **Access Control**: Badge \"Admin\" untuk menu admin dashboard
- **Responsive Design**: Tampilan optimal di berbagai ukuran layar
- **Loading States**: Circular progress indicator saat loading
- **Error Handling**: Pesan error dengan tombol retry
- **Pull-to-Refresh**: Swipe down untuk refresh data
- **Visual Feedback**: 
  - Color-coded status (hijau/merah)
  - Progress bars
  - Interactive charts
  - Filter chips

## 🔧 Technical Details

### Dependencies
```yaml
syncfusion_flutter_charts: ^31.2.4  # Charts (Doughnut, Bar)
path_provider: ^2.0.15              # File path
open_filex: 4.7.0                   # Open downloaded file
permission_handler: ^11.3.2         # Storage permission
intl: ^0.20.2                       # Date formatting
```

### File Structure
```
lib/
├── screens/
│   ├── admin_dashboard_screen.dart  # Main dashboard
│   └── home_screen.dart             # Updated with drawer/sidebar
├── models/
│   ├── user.dart                    # User permissions
│   ├── unit.dart                    # Unit model
│   └── update_job.dart              # Job model
├── services/
│   └── api_service.dart             # API calls
└── constants/
    ├── colors.dart                  # Color scheme
    └── typography.dart              # Text styles
```

### Data Flow
1. Load data dari API (jobs & units)
2. Filter berdasarkan user permissions (branch/super admin)
3. **Compare serial_number** antara unit_assets dan update_jobs
4. Process data untuk statistik PM
5. Display dengan charts dan list
6. Export ke CSV dengan proper formatting

### Permissions
- **Storage Permission**: Untuk save file Excel
- **User Permission**: Super Admin atau Koordinator
- **Branch Access**: 
  - Super Admin: Lihat semua branch
  - Koordinator: Hanya branch sendiri

## 🎨 Color Scheme

- **Primary**: Dark Blue (#1a237e)
- **Success**: Green (#4caf50) - Sudah PM
- **Error**: Red (#f44336) - Belum PM
- **Info**: Blue (#2196f3)
- **Warning**: Orange (#ff9800) - Admin badge

## 🔐 Security

- **Role-based access**: Super Admin dan Koordinator
- **Branch filtering**: Data sesuai branch (kecuali Super Admin)
- **Permission checks**: Di level UI dan API
- **Sidebar menu**: Hanya muncul untuk authorized users

## 🐛 Error Handling

- Network errors: Retry button
- Permission denied: Alert message
- Empty data: Friendly empty state
- File write errors: Snackbar notification

## 📝 Notes

1. **CSV Format**: Menggunakan CSV karena lebih universal dan tidak perlu library berat
2. **File Location**: 
   - Android: External Storage
   - iOS: Application Documents
3. **Auto-open**: File otomatis dibuka setelah download (jika ada aplikasi yang support)
4. **Logic Update**: Perhitungan PM sekarang based on comparison serial_number antara 2 tabel

## 🆕 What's New (Latest Update)

✅ **Logic PM diperbaiki**: Sekarang membandingkan unit_assets vs update_jobs berdasarkan serial_number
✅ **Access diperluas**: Koordinator juga bisa akses admin dashboard
✅ **UI berubah**: Dari button AppBar ke Sidebar/Drawer menu
✅ **Sidebar features**: User profile header, organized menu, admin badge

## 🔄 Future Enhancements

- [ ] Excel format dengan styling (XLSX)
- [ ] Filter by date range
- [ ] Export PDF report
- [ ] Email report functionality
- [ ] More detailed analytics
- [ ] Custom chart configurations
- [ ] Schedule automated reports

---

**Version**: 1.1.0  
**Last Updated**: 2025-01-XX  
**Developer**: DRR Team