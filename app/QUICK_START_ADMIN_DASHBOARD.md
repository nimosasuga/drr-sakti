"# 🎯 Quick Start Guide - Admin Dashboard

## 📍 Akses Cepat

### Siapa yang Bisa Akses?
```
✅ Super Admin (ADMIN DRR)
✅ Koordinator (KOORDINATOR)
❌ Field Service
❌ FMC
```

### Cara Membuka Dashboard
```
1. Buka aplikasi DRR SAKTI
2. Login sebagai Super Admin atau Koordinator
3. Swipe dari kiri → Sidebar terbuka
4. Pilih \"Admin Dashboard\" (badge orange)
```

---

## 📊 Fitur Utama

### Tab 1: STATISTIK
```
┌─────────────────────────────────────┐
│  Total Preventive Maintenance       │
│                                     │
│  Sudah PM:    65 unit              │
│  Belum PM:    35 unit              │
│  Total:       100 unit             │
│  ═══════════════════ 65%           │
│                                     │
│  [Doughnut Chart]                  │
│  ● Sudah PM (65%)                  │
│  ● Belum PM (35%)                  │
│                                     │
│  [Bar Chart - 6 Bulan Terakhir]    │
│  ▓ Sudah PM                        │
│  ▓ Belum PM                        │
└─────────────────────────────────────┘
```

**Logic:**
```
Total Unit = Jumlah unit di unit_assets (by serial_number)
Sudah PM = Unit yang serial_number-nya ada di update_jobs 
           dengan jobType \"PREVENTIVE\"
Belum PM = Total Unit - Sudah PM
```

---

### Tab 2: UNIT LIST
```
┌─────────────────────────────────────┐
│  [Semua] [Sudah PM] [Belum PM]     │
│  Total: 35 unit                     │
│                                     │
│  ✅ SN-12345                        │
│     Excavator - PT ABC              │
│     Branch: Jakarta                 │
│     [Sudah PM]                      │
│                                     │
│  ❌ SN-67890                        │
│     Forklift - PT XYZ               │
│     Branch: Jakarta                 │
│     [Belum PM]                      │
└─────────────────────────────────────┘
```

**Filter:**
- Semua: Tampilkan semua unit
- Sudah PM: Hanya unit yang sudah PM
- Belum PM: Hanya unit yang belum PM

---

### Tab 3: DOWNLOAD
```
┌─────────────────────────────────────┐
│  Download Data Update Jobs          │
│                                     │
│  Branch: Jakarta                    │
│  Total Jobs: 150                    │
│                                     │
│  [📥 Download Excel]                │
│                                     │
│  Informasi:                         │
│  • File: CSV format                 │
│  • Lokasi: Folder Downloads         │
│  • Nama: update_jobs_Jakarta_...    │
└─────────────────────────────────────┘
```

**File Output:**
```csv
ID,Branch,Status Mekanik,PIC,Partner,...
1,Jakarta,Field Service,John,Mike,...
2,Jakarta,FMC,Jane,Tom,...
```

---

## 🗺️ Navigation Flow

```
Home Screen
    │
    ├─ Swipe dari kiri / Tap hamburger (☰)
    │
    └─ Sidebar Menu
        │
        ├─ Home
        ├─ Unit Assets
        ├─ Update Jobs
        ├─ Profile
        ├─ ─────────────
        ├─ 🔒 Admin Dashboard [Admin]  ← Klik ini
        ├─ ─────────────
        └─ About
            │
            └─ Admin Dashboard Screen
                │
                ├─ Tab: Statistik
                ├─ Tab: Unit List
                └─ Tab: Download
```

---

## 🔄 Data Flow Diagram

```
┌─────────────────┐         ┌─────────────────┐
│  unit_assets    │         │  update_jobs    │
│  (MySQL)        │         │  (MySQL)        │
│                 │         │                 │
│  • id           │         │  • id           │
│  • serial_number│◄────────┤  • serial_number│
│  • unit_type    │ Compare │  • job_type     │
│  • customer     │         │  • pm           │
│  • branch       │         │  • date         │
└─────────────────┘         └─────────────────┘
         │                           │
         └───────────┬───────────────┘
                     │
                     ▼
         ┌───────────────────────┐
         │  Admin Dashboard      │
         │  (Flutter)            │
         │                       │
         │  Calculate:           │
         │  • Total Units        │
         │  • Sudah PM           │
         │  • Belum PM           │
         │  • Percentage         │
         └───────────────────────┘
                     │
                     ▼
         ┌───────────────────────┐
         │  Display:             │
         │  • Charts             │
         │  • Lists              │
         │  • Export Excel       │
         └───────────────────────┘
```

---

## 🎨 UI Components

### Sidebar Menu
```
┌────────────────────────────────┐
│  ┌────────┐                    │
│  │   J    │  John Doe          │
│  └────────┘  Super Admin       │
│              Jakarta            │
├────────────────────────────────┤
│  🏠  Home                       │
│  📦  Unit Assets                │
│  🔧  Update Jobs                │
│  👤  Profile                    │
├────────────────────────────────┤
│  ⚙️  Admin Dashboard  [Admin]  │ ← Orange badge
├────────────────────────────────┤
│  ℹ️  About                      │
└────────────────────────────────┘
```

### Statistics Card
```
┌────────────────────────────────────┐
│  Total Preventive Maintenance      │
│  ────────────────────────────────  │
│                                    │
│    65         35         100       │
│  Sudah PM   Belum PM    Total      │
│  (Green)     (Red)     (Blue)      │
│                                    │
│  ████████████░░░░░░░░░░ 65%        │
│                                    │
│  65.0% Completed                   │
└────────────────────────────────────┘
```

---

## ⚡ Quick Tips

### 1. Refresh Data
- Pull down pada screen untuk refresh
- Data akan reload otomatis

### 2. Filter Unit
- Gunakan chips di atas list
- Klik untuk toggle filter

### 3. Download Excel
- Pastikan permission storage sudah granted
- File otomatis terbuka setelah download

### 4. Navigate
- Use back button untuk kembali
- Sidebar dapat dibuka kapan saja

---

## 🐛 Troubleshooting

### Problem: Menu Admin Dashboard tidak muncul
**Solution:**
- Cek user role: Harus Super Admin atau Koordinator
- Re-login jika perlu

### Problem: Data tidak muncul
**Solution:**
- Cek koneksi internet
- Pull-to-refresh
- Pastikan API accessible

### Problem: Download gagal
**Solution:**
- Grant storage permission di settings
- Cek space storage
- Coba lagi

### Problem: Chart tidak muncul
**Solution:**
- Pastikan ada data PM
- Refresh screen
- Restart app

---

## 📞 Support

Jika ada masalah:
1. Screenshot error message
2. Catat langkah yang dilakukan
3. Hubungi IT Support
4. Atau baca dokumentasi lengkap di:
   - `ADMIN_DASHBOARD_README.md`
   - `INTEGRATION_GUIDE.md`
   - `CHANGELOG_ADMIN_DASHBOARD.md`

---

**Happy Analyzing! 📊**
"