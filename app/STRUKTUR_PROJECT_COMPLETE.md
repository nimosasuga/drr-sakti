# 📁 STRUKTUR FILE PROJECT FLUTTER + PHP API - IMPLEMENTASI LENGKAP

## 🗃️ DATABASE STRUCTURE (MySQL)

```sql
-- TABEL: data_user
`id`, `name`, `nrpp`, `password`, `status_user`, `branch`, `created_at`, `updated_at`

-- TABEL: unit_assets
`id`, `supported_by`, `customer`, `location`, `branch`, `serial_number`, `unit_type`, `year`, `status`, `delivery`, `jenis_unit`, `note`, `created_at`, `updated_at`, `qr_token`

-- TABEL: update_jobs
`id`, `branch`, `status_mekanik`, `pic`, `partner`, `in_time`, `out_time`, `vehicle`, `nopol`, `date`, `serial_number`, `unit_type`, `year`, `hour_meter`, `nomor_lambung`, `customer`, `location`, `job_type`, `status_unit`, `problem_date`, `rfu_date`, `lead_time_rfu`, `pm`, `rm`, `problem`, `action`, `recommendations_json`, `install_parts_json`, `created_at`, `updated_at`
```

---

## 🔗 PHP API STRUCTURE

```
public_html/appsheetcore.my.id/
├──/.well-known/
├──/admin/
├── .htpasswd
├── error_log
├── generate_qr_images.php
├── generate_qr_tokens_by_pair.php
└── tokens.php
├──/tcpdf/
├──/vendor/
├── .htaccess
├──composer.json
├──/api/
├──composer.lock
├──customer.php
├──error_log
├──export_error.log
├──export_excel.php
├──export_pdf.php
├──generate_qr_images.php
├── config.php                          # Database configuration & CORS
├── login.php                           # Authentication
├── read.php                            # Get all units
├── read_one.php                        # Get single unit
├── read_by_branch.php                  # Get units by branch
├── read_update_jobs.php                # Get all/single update jobs
├── read_update_jobs_by_branch.php      # Get update jobs by branch
├── read_partners_by_branch.php         # Get team partners by branch
├── create.php                          # Create unit
├── create_update_job.php               # Create update job
├── update.php                          # Update unit
├── update_update_job.php               # Update update job
├── delete.php                          # Delete unit
├── delete_update_job.php               # Delete update job
├── check_serial.php                    # Check serial number existence
└──mechanic_stats.php                   # Get mechanic statistics
├── /objects/
    ├── unit.php                        # Unit model
    └── user.php                        # User model
```

---

## 📱 FLUTTER STRUCTURE (lib/)

```
/lib/
├── main.dart                           # App entry point
├── constants/
│   ├── colors.dart                     # App color scheme
│   └── typography.dart                 # Text styles
├── models/
│   ├── user.dart                       # User model with permissions
│   ├── unit.dart                       # Unit asset model
│   └── update_job.dart                 # Update job model with PartItem
├── services/
│   ├── api_service.dart                # REST API calls (http)
│   ├── auth_service.dart               # Authentication service
│   └── auth_service_dio.dart           # Authentication with Dio
└── screens/
    ├── login_screen.dart               # NRPP & password login
    ├── home_screen.dart                # Dashboard & navigation + SIDEBAR MENU (UPDATED v1.1)
    ├── profile_screen.dart             # User profile + mechanic stats
    ├── unit_assets_screen.dart         # List units with search
    ├── unit_detail_screen.dart         # Unit details
    ├── unit_form_screen.dart           # Create/edit unit
    ├── update_job_screen.dart          # List jobs grouped by month + search
    ├── update_job_detail_screen.dart   # Job details + WhatsApp share FAB
    ├── update_job_form.dart            # Create/edit job with auto-fill + back confirmation
    └── admin_dashboard_screen.dart     # 🆕 ADMIN DASHBOARD (NEW v1.1)
```

---

## 🎯 FITUR YANG SUDAH DIIMPLEMENTASIKAN

### ✅ AUTHENTICATION & AUTHORIZATION

- Login dengan NRPP & password
- Role-based permissions (Super Admin, Field Service, FMC, Koordinator)
- Branch-based access control
- Session management

### ✅ UNIT ASSETS MANAGEMENT

- CRUD operations dengan branch restriction
- Search & filtering
- Serial number validation
- QR token system

### ✅ UPDATE JOBS MANAGEMENT

- CRUD operations dengan parts/recommendations
- Auto-fill data dari unit_assets
- Dynamic partners dropdown berdasarkan branch
- Grouping by month dengan expandable sections
- WhatsApp sharing dengan format profesional
- Text selection/copy untuk semua data

### ✅ USER PROFILE & STATISTICS

- User information & permissions display
- Real-time mechanic statistics:
  - Total jobs per bulan
  - Job type distribution (Doughnut chart)
  - Efficiency percentage
  - Pending breakdown alerts
  - Fuzzy PIC name matching

### 🆕 ADMIN DASHBOARD (NEW v1.1) ⭐

**Access:** Super Admin & Koordinator only

**Fitur Utama:**

#### 📊 Tab 1: Statistik PM

- **Total Preventive Maintenance Card:**
  - Logic: Compare `unit_assets` vs `update_jobs` by `serial_number`
  - Sudah PM: Unit yang serial_number-nya ada di update_jobs dengan jobType \"PREVENTIVE\"
  - Belum PM: Total unit - Sudah PM
  - Progress bar & percentage completion
- **Doughnut Chart:**
  - Visual proporsi Sudah PM vs Belum PM
  - Color-coded: Green (done) & Red (not done)
- **Bar Chart per Bulan:**
  - PM statistics 6 bulan terakhir
  - Grouped bar: Sudah PM & Belum PM
  - Interactive tooltip

#### 📝 Tab 2: Unit List

- **Filter Status PM:**
  - Semua unit
  - Sudah PM (green badge)
  - Belum PM (red badge)
- **Unit Information Display:**
  - Serial number
  - Unit type & Customer
  - Branch
  - PM status indicator (✓/✗)
- **Features:**
  - Pull-to-refresh
  - Real-time filtering
  - Count display

#### 📥 Tab 3: Download Excel

- **CSV Export:**
  - All update_jobs data
  - Filtered by user's branch
  - Auto-save to Downloads folder
  - Auto-open after download
- **File Format:**
  - Name: `update_jobs_[branch]_[timestamp].csv`
  - Headers: All update_jobs columns
  - Data: CSV with proper escaping

**UI Navigation:**

- Access via Sidebar/Drawer menu
- User profile header dengan avatar
- Badge \"Admin\" berwarna orange
- Organized menu structure
- About dialog

**Technical Implementation:**

- Uses Syncfusion Charts (Doughnut & Bar)
- Path provider for file storage
- Permission handler for storage access
- Cross-table data comparison logic
- Branch-based data filtering

**Permission Matrix:**
| Role | Access | Data Scope |
|------|--------|------------|
| Super Admin | ✅ Yes | All branches |
| Koordinator | ✅ Yes | Own branch only |
| Field Service | ❌ No | - |
| FMC | ❌ No | - |

### ✅ USER EXPERIENCE

- Responsive design
- Loading states & error handling
- Search functionality
- Refresh indicators
- Permission-based UI restrictions
- Text selection untuk copy-paste
- Back confirmation dialogs
- Professional color scheme
- **🆕 Sidebar navigation menu (Updated)**
- **🆕 Visual PM statistics & charts**
- **🆕 Excel export functionality**

### ✅ TECHNICAL IMPLEMENTATIONS

- REST API dengan PHP/MySQL
- Flutter dengan http & dio
- JSON handling untuk dynamic data
- CORS configuration
- Error handling & debugging
- Type safety conversions
- PDO database connections
- **🆕 Syncfusion charts integration**
- **🆕 CSV file generation**
- **🆕 Cross-table data comparison**
- **🆕 Storage permission handling**

---

## 🔧 KEY IMPLEMENTATION DETAILS

### Database Relations:

- `update_jobs.pic` → `data_user.name`
- `update_jobs.serial_number` → `unit_assets.serial_number` ⭐ (Used in Admin Dashboard)
- `update_jobs.branch` → `data_user.branch`

### Authentication Flow:

1. Login dengan NRPP & password
2. Server return user data + permissions
3. Client store user session
4. All subsequent requests include authentication

### Flutter State Management:

- Simple setState untuk UI updates
- API service class untuk data fetching
- Model classes dengan proper serialization
- Error boundaries dengan fallback UI

### 🆕 Admin Dashboard Data Flow:

1. **Load Data:** Fetch units & jobs from API
2. **Filter:** Branch-based filtering (except Super Admin)
3. **Compare:** Match serial_number between tables
4. **Calculate:** PM statistics & percentages
5. **Display:** Charts, lists, and export options

```
┌─────────────────┐         ┌─────────────────┐
│  unit_assets    │         │  update_jobs    │
│  (MySQL)        │         │  (MySQL)        │
│                 │         │                 │
│  serial_number  │◄────────┤  serial_number  │
│  (All units)    │ Compare │  (PM jobs only) │
└─────────────────┘         └─────────────────┘
         │                           │
         └───────────┬───────────────┘
                     │
                     ▼
         ┌───────────────────────┐
         │  Admin Dashboard      │
         │                       │
         │  Sudah PM = Count(    │
         │    PM jobs serials)   │
         │                       │
         │  Belum PM = Total -   │
         │    Sudah PM           │
         └───────────────────────┘
```

---

## 🚀 ARCHITECTURE PATTERNS

- **MVVM-like**: Models + Services + Screens
- **RESTful API**: Standard HTTP methods
- **Repository Pattern**: ApiService sebagai data layer
- **Component-based UI**: Reusable widgets
- **🆕 Drawer Navigation**: Sidebar menu pattern
- **🆕 Tab-based Dashboard**: Multi-view admin interface

---

## 💡 KEY FEATURES HIGHLIGHTS

1. **Role-based access control** - Different permissions per user type
2. **Branch isolation** - Data segregation by branch
3. **Real-time statistics** - Mechanic performance metrics
4. **Professional UI/UX** - Consistent design system
5. **Offline-capable** - Error handling & fallbacks
6. **Cross-platform** - iOS & Android compatible
7. **🆕 Admin Analytics Dashboard** - PM monitoring & reporting
8. **🆕 Data Export** - CSV download functionality
9. **🆕 Visual Charts** - Interactive data visualization
10. **🆕 Smart Filtering** - Real-time list filtering

---

## 📦 DEPENDENCIES (pubspec.yaml)

### Core Dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter
  url_launcher: ^6.1.11 # WhatsApp integration
  share_plus: ^12.0.1 # Share functionality
  http: ^1.5.0 # HTTP requests
  intl: ^0.20.2 # Date formatting
  shared_preferences: ^2.1.1 # Local storage
  dio: ^5.0.0 # Alternative HTTP client

  # Syncfusion (Charts & Data)
  syncfusion_flutter_datagrid: ^31.2.4
  syncfusion_flutter_core: ^31.2.4
  syncfusion_flutter_datepicker: ^31.2.4
  syncfusion_flutter_charts: ^31.2.4 # 🆕 For Admin Dashboard

  # File Operations (Admin Dashboard)
  open_filex: 4.7.0 # 🆕 Open downloaded files
  path_provider: ^2.0.15 # 🆕 File paths
  permission_handler: ^11.3.2 # 🆕 Storage permissions
```

---

## 🗂️ SCREEN FLOW DIAGRAM

```
┌──────────────────┐
│  LoginScreen     │
│  (NRPP + Pass)   │
└────────┬─────────┘
         │
         ▼
┌──────────────────────────────────────┐
│  HomeScreen (with Sidebar)           │
│  ┌────────────┐                      │
│  │ Sidebar    │  Main Content:       │
│  │ Menu       │  - Unit Assets       │
│  │            │  - Update Jobs       │
│  │ • Home     │  - Profile           │
│  │ • Units    │                      │
│  │ • Jobs     │                      │
│  │ • Profile  │                      │
│  │ ─────────  │                      │
│  │ • 🔒Admin  │◄─────────────────────┤
│  │   [Badge]  │  (Super Admin +      │
│  └────────────┘   Koordinator only)  │
└──────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│  AdminDashboardScreen (NEW)          │
│  ┌─────────────────────────────────┐ │
│  │ Tab 1: Statistik                │ │
│  │  • Total PM Card                │ │
│  │  • Doughnut Chart               │ │
│  │  • Bar Chart (Monthly)          │ │
│  ├─────────────────────────────────┤ │
│  │ Tab 2: Unit List                │ │
│  │  • Filter chips                 │ │
│  │  • Unit cards with badges       │ │
│  │  • PM status indicators         │ │
│  ├─────────────────────────────────┤ │
│  │ Tab 3: Download                 │ │
│  │  • CSV export button            │ │
│  │  • File info                    │ │
│  │  • Download to device           │ │
│  └─────────────────────────────────┘ │
└──────────────────────────────────────┘
```

---

## 📄 DOCUMENTATION FILES

```
/app/
├── STRUKTUR_PROJECT_COMPLETE.md       # This file (Complete structure)
├── ADMIN_DASHBOARD_README.md          # Admin dashboard features guide
├── INTEGRATION_GUIDE.md               # Integration & setup guide
├── CHANGELOG_ADMIN_DASHBOARD.md       # Version changes & updates
├── QUICK_START_ADMIN_DASHBOARD.md     # Quick start visual guide
└── README.md                          # Main project README
```

---

## 🎨 COLOR SCHEME

```dart
// Primary Colors
AppColors.primary       // #1a237e - Dark Blue (DRR Brand)
AppColors.secondary     // #00b0ff - Bright Blue
AppColors.accent        // #ffab00 - Amber/Orange

// Status Colors
AppColors.success       // #4caf50 - Green (Sudah PM)
AppColors.error         // #f44336 - Red (Belum PM)
AppColors.warning       // #ff9800 - Orange (Admin Badge)
AppColors.info          // #2196f3 - Blue

// UI Colors
AppColors.background    // #f5f5f5 - Light Grey
AppColors.surface       // #ffffff - White
AppColors.disabled      // #9e9e9e - Grey
```

---

## 🔐 SECURITY & PERMISSIONS

### User Roles & Access:

| Feature                | Super Admin  | Koordinator | Field Service | FMC           |
| ---------------------- | ------------ | ----------- | ------------- | ------------- |
| View Units             | All branches | Own branch  | Own branch    | Own branch    |
| Create/Edit Units      | ✅ Yes       | ✅ Yes      | ❌ No         | ❌ No         |
| View Jobs              | All branches | Own branch  | Own branch    | Own branch    |
| Create Jobs            | ✅ Yes       | ✅ Yes      | ✅ Yes        | ✅ Yes        |
| Edit/Delete Jobs       | ✅ Yes       | ✅ Yes      | Own jobs only | Own jobs only |
| **🆕 Admin Dashboard** | **✅ Yes**   | **✅ Yes**  | **❌ No**     | **❌ No**     |
| **🆕 Download Excel**  | **✅ Yes**   | **✅ Yes**  | **❌ No**     | **❌ No**     |

### Data Access Control:

- **Branch Filtering**: Automatic based on user.branch
- **Super Admin Exception**: Can access all branches
- **Serial Number Matching**: Cross-table validation
- **Storage Permission**: Required for Excel download (Android)

---

## 🆕 WHAT'S NEW IN v1.1.0

### ⭐ Major Features Added:

1. **Admin Dashboard Screen**

   - PM statistics with visual charts
   - Unit list with filter
   - Excel export functionality

2. **Sidebar Navigation**

   - Drawer menu dengan user profile
   - Organized menu structure
   - Admin badge indicator

3. **PM Calculation Logic**

   - Cross-table comparison (unit_assets vs update_jobs)
   - Accurate PM status tracking
   - Real-time statistics

4. **Extended Permissions**
   - Koordinator can access admin features
   - Branch-based data filtering maintained

### 📊 Technical Additions:

- Syncfusion Charts integration
- CSV file generation & export
- Storage permission handling
- Cross-table data queries
- Advanced filtering logic

---

## 🔮 FUTURE ROADMAP

### Planned Features:

- [ ] **Date Range Filter** - Filter PM by specific date period
- [ ] **XLSX Export** - Excel with formatting & charts
- [ ] **PDF Reports** - Formatted PDF reports
- [ ] **Email Integration** - Send reports via email
- [ ] **Push Notifications** - PM overdue alerts
- [ ] **Offline Mode** - Work without internet
- [ ] **Advanced Analytics** - More detailed metrics
- [ ] **Custom Dashboard** - Configurable admin views
- [ ] **Multi-language** - Internationalization support
- [ ] **Dark Mode** - Theme switching

---

**Version**: 1.1.0 (Current)  
**Last Updated**: 2025-01-XX  
**Platform**: Flutter + PHP + MySQL  
**Status**: ✅ Production Ready

---

## 📞 SUPPORT & DOCUMENTATION

**Main Documentation:**

- 📖 `ADMIN_DASHBOARD_README.md` - Feature documentation
- 🚀 `QUICK_START_ADMIN_DASHBOARD.md` - Quick start guide
- 🔧 `INTEGRATION_GUIDE.md` - Integration & setup
- 📝 `CHANGELOG_ADMIN_DASHBOARD.md` - Version history

**Contact:**

- Development Team: DRR SAKTI
- API Endpoint: `https://exprosa.com/api/`

---

**🎉 Project Complete with Admin Dashboard v1.1.0!**
