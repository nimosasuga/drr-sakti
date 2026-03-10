# DRR SAKTI - AI MASTER CONTEXT

> [!IMPORTANT]
> **FOR AI AGENTS**: This file is the **SINGLE SOURCE OF TRUTH** for the `drr_sakti` project. It consolidates all critical documentation (Context, Schema, API, Plan) into one file.
> **DO NOT IGNORE THIS FILE**. Read it before performing any task.

---

## 1. PROJECT IDENTITY & RULES

- **Name**: DRR SAKTI (DRR Unit Assets Management)
- **Version**: 2.2.0 (Production Ready)
- **Purpose**: Mobile application for managing heavy equipment assets, maintenance jobs, and logistics (Delivery/Penarikan).
- **Target Users**: Mechanics, Coordinators, and Admins.
- **Language**:
  - **Code/Comments**: English.
  - **UI/UX**: Indonesian (Bahasa Indonesia) - **Strict Requirement**.

### **Coding Conventions**
- **UI Text**: Always use **Indonesian**.
- **Error Handling**: `try-catch` with `dart:developer` logging.
- **Networking**: Prefer **Dio** for new features.
- **State**: `setState` (Legacy) -> **Provider/Riverpod** (Future).

### **Color Scheme (Material 3)**
-   **Primary**: `#1a237e` (Dark Blue - Brand)
-   **Success**: `#4caf50` (Green - Sudah PM)
-   **Error**: `#f44336` (Red - Belum PM)
-   **Warning**: `#ff9800` (Orange - Admin Badge)

### **Required Permissions**
- **Camera**: For unit inspection photos.
- **Location**: For verifying mechanic position.
- **Storage**: For exporting Excel reports (Admin Dashboard).

### **Recommended Tools**
- **VSCode Extensions**: See `app/vscode-extensions-guide.md` for productivity tools (Error Lens, Better Comments, etc.).

---

## 2. DOCUMENTATION MAP (Located in `app/`)

- **`PROJECT STRUCTURE TREE v2.2.0.md`**: **Architecture & Folder Structure**.
- **`STRUKTUR_PROJECT_COMPLETE.md`**: Database Schema & API List.
- **`QUICK_START_ADMIN_DASHBOARD.md`**: **Visual Guide & Quick Start** for Admin features.
- **`ADMIN_DASHBOARD_README.md`**: Deep dive into Admin features and PM logic.
- **`INTEGRATION_GUIDE.md`**: Setup and deployment guide.
- **`DOCUMENTATION_INDEX.md`**: Guide to all documentation files.

---

## 3. DATABASE SCHEMA (Key Tables)

### **Users (`data_user`)**
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | INT (PK) | Unique ID |
| `nrpp` | VARCHAR | Login ID |
| `status_user` | VARCHAR | Role |
| `branch` | VARCHAR | Branch |

### **Unit Assets (`unit_assets`)**
| Column | Type | Description |
| :--- | :--- | :--- |
| `serial_number` | VARCHAR | Unique SN |
| `unit_type` | VARCHAR | Type |
| `status_unit` | VARCHAR | Condition |
| `qr_token` | VARCHAR | QR Token |

### **Update Jobs (`update_jobs`)**
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | INT (PK) | Job ID |
| `job_type` | VARCHAR | Preventive/Troubleshooting |
| `recommendations_json` | JSON | Parts Recommended |
| `install_parts_json` | JSON | Parts Installed |

### **Delivery Units (`delivery_units`)** ⭐ (New v2.2)
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | VARCHAR (PK) | UUID |
| `date` | DATE | Delivery Date |
| `serial_number` | VARCHAR | Unit SN |
| `customer` | VARCHAR | Customer Name |
| `branch` | VARCHAR | Origin Branch |

### **Penarikan Units (`penarikan_units`)**
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | VARCHAR (PK) | UUID |
| `date` | DATE | Withdrawal Date |
| `serial_number` | VARCHAR | Unit SN |
| `status_unit` | VARCHAR | Condition (RFU/Breakdown) |

*(See `lib/models/` for Battery and Charger models)*

---

## 4. API STRUCTURE & FLOW

**Base URL**: `https://drr.exprosa.com/api`

### **App Flow**
1.  **Login**: `POST /login.php`
2.  **Home**: Sidebar Navigation.
3.  **Modules**:
    -   **Assets**: `/read.php`
    -   **Jobs**: `/read_update_jobs.php`
    -   **Delivery**: `/delivery/delivery_units.php` (New)
    -   **Admin**: `/mechanic_stats.php`, `/export_data.php`

### **Key Endpoints**
-   **Auth**: `/login.php`
-   **Units**: `/read.php`, `/create.php`, `/update.php`
-   **Jobs**: `/read_update_jobs.php`, `/create_update_job.php`
-   **Delivery**: `/delivery/delivery_units.php`
-   **Admin**: `/admin/tokens.php`, `/export_excel.php`

---

## 5. KEY BUSINESS LOGIC

### **PM Status Calculation (Admin Dashboard)**
-   **Logic**: Cross-table comparison between `unit_assets` and `update_jobs`.
-   **Sudah PM**: Unit exists in `update_jobs` with `job_type` containing "PREVENTIVE".
-   **Belum PM**: Total Units (from `unit_assets`) - Sudah PM.
-   **Reference**: See `app/ADMIN_DASHBOARD_README.md` for full details.

### **Key Database Relations**
-   `update_jobs.pic` -> `data_user.name` (Mechanic assignment)
-   `update_jobs.serial_number` -> `unit_assets.serial_number` (PM Status check)
-   `update_jobs.branch` -> `data_user.branch` (Data segregation)

---

## 6. PROJECT PLAN & ROADMAP

### **Current Status (v2.2.0)**
-   ✅ **Delivery Module**: Complete (Screens + API).
-   ✅ **Admin Dashboard**: Charts & Export.
-   ✅ **Sidebar**: Full navigation implemented.

### **Roadmap**
1.  **Stabilization**: Migrate remaining `http` calls to `Dio`.
2.  **Modernization**: Implement `Riverpod` for state management.
3.  **Features**:
    -   [ ] **Push Notifications**: FCM for job updates.
    -   [ ] **Offline Support**: Local DB (Hive/SQLite).
    -   [ ] **Advanced Analytics**: Date Range Filters, PDF Reports.
    -   [ ] **Export Enhancements**: XLSX format with styling.
    -   [ ] **UI/UX**: Dark Mode, Multi-language support.

---

> [!TIP]
> **Quick Start for AI**:
> 1.  **Check `PROJECT STRUCTURE TREE v2.2.0.md`** for file locations.
> 2.  **Use `delivery/` folder** for logistics features.
> 3.  **Follow Indonesian UI** rule strictly.

---

## 7. CORE DEPENDENCIES

### **Flutter Packages**
-   **Networking**: `dio` (Preferred), `http` (Legacy).
-   **UI/Charts**: `syncfusion_flutter_charts`, `syncfusion_flutter_datagrid`.
-   **Utils**: `intl` (Formatting), `shared_preferences` (Local Storage), `permission_handler`.
-   **File/IO**: `path_provider`, `open_filex`.
-   **Features**: `share_plus` (Sharing), `url_launcher` (External Links).

### **Backend (PHP)**
-   **Extensions**: `mysqli`, `pdo`, `json`, `gd` (QR Codes).

