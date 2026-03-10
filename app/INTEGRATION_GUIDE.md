# 🚀 Panduan Integrasi Admin Dashboard

## File-file yang Telah Dibuat

### 1. **admin_dashboard_screen.dart** (NEW)

**Lokasi**: `lib/screens/admin_dashboard_screen.dart`

**Deskripsi**: Screen utama admin dashboard dengan 3 tabs (Statistik, Unit List, Download)

**Dependencies yang digunakan:**

```dart
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
```

### 2. **home_screen.dart** (UPDATED)

**Lokasi**: `lib/screens/home_screen.dart`

**Perubahan**:

- Ditambahkan import `admin_dashboard_screen.dart`
- Ditambahkan IconButton di AppBar untuk akses admin dashboard
- Button hanya muncul jika `user.isSuperAdmin == true`

### 3. **main.dart** (UPDATED)

**Lokasi**: `lib/main.dart`

**Perubahan**:

- Cleaned up duplicate main() function
- Simplified structure

---

## 📦 Dependencies Check

Pastikan `pubspec.yaml` sudah memiliki dependencies berikut:

```yaml
dependencies:
  flutter:
    sdk: flutter
  syncfusion_flutter_charts: ^31.2.4 # ✅ Sudah ada
  intl: ^0.20.2 # ✅ Sudah ada
  path_provider: ^2.0.15 # ✅ Sudah ada
  open_filex: 4.7.0 # ✅ Sudah ada
  permission_handler: ^11.3.2 # ✅ Sudah ada
  http: ^1.5.0 # ✅ Sudah ada
```

**Status**: ✅ Semua dependencies sudah tersedia di pubspec.yaml Anda!

---

## 🔧 Langkah Integrasi

### Step 1: Copy File ke Project Flutter Anda

Copy 3 file berikut ke project Flutter Anda:

```bash
# File baru
lib/screens/admin_dashboard_screen.dart

# File updated (replace yang lama)
lib/screens/home_screen.dart
lib/main.dart
```

### Step 2: Android Permissions (AndroidManifest.xml)

Tambahkan permissions di `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android=\"http://schemas.android.com/apk/res/android\">
    <!-- Existing permissions -->

    <!-- Add these for file download -->
    <uses-permission android:name=\"android.permission.WRITE_EXTERNAL_STORAGE\"/>
    <uses-permission android:name=\"android.permission.READ_EXTERNAL_STORAGE\"/>
    <uses-permission android:name=\"android.permission.MANAGE_EXTERNAL_STORAGE\"/>

    <application
        ...
        android:requestLegacyExternalStorage=\"true\">
        <!-- Rest of your config -->
    </application>
</manifest>
```

### Step 3: iOS Permissions (Info.plist)

Tambahkan di `ios/Runner/Info.plist`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to save downloaded files</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>We need access to save downloaded files</string>
```

### Step 4: Run Flutter Commands

```bash
# Get dependencies (jika ada yang belum)
flutter pub get

# Clean build (recommended)
flutter clean
flutter pub get

# Run app
flutter run
```

---

## 🧪 Testing

### Test 1: Access Admin Dashboard

1. Login sebagai Super Admin
2. Lihat icon ⚙️ di AppBar (kanan atas)
3. Klik icon tersebut
4. Dashboard harus terbuka dengan 3 tabs

### Test 2: View Statistics

1. Buka tab \"Statistik\"
2. Pastikan card total PM muncul
3. Pastikan Doughnut Chart terlihat
4. Pastikan Bar Chart per bulan terlihat
5. Pull-to-refresh untuk reload data

### Test 3: Filter Unit List

1. Buka tab \"Unit List\"
2. Test filter: Semua, Sudah PM, Belum PM
3. Pastikan list berubah sesuai filter
4. Pastikan badge status (hijau/merah) muncul

### Test 4: Download Excel

1. Buka tab \"Download\"
2. Klik tombol \"Download Excel\"
3. Izinkan permission storage (jika diminta)
4. File harus tersimpan di Downloads
5. File harus terbuka otomatis (jika ada app yang support)

---

## 🐛 Troubleshooting

### Problem 1: Permission Denied (Android)

**Solution**:

```dart
// Tambahkan di AndroidManifest.xml
android:requestLegacyExternalStorage=\"true\"

// Atau gunakan Android 11+ storage access
if (Platform.isAndroid && android.os.Build.VERSION.SDK_INT >= 30) {
    await Permission.manageExternalStorage.request();
}
```

### Problem 2: Charts Tidak Muncul

**Solution**:

```bash
# Pastikan syncfusion sudah terinstall
flutter pub get

# Clean build
flutter clean
flutter pub get
```

### Problem 3: API Error / Data Tidak Muncul

**Check**:

- Apakah API `https://exprosa.com/api/` accessible?
- Apakah user memiliki permission yang benar?
- Check console logs untuk error details

### Problem 4: File Tidak Tersimpan

**Check**:

```dart
// Lihat log path file
log('File path: $filePath');

// Test manual write
await file.writeAsString('test');
```

---

## 📱 Platform-Specific Notes

### Android

- Perlu permission WRITE_EXTERNAL_STORAGE
- File tersimpan di `/storage/emulated/0/Android/data/[app]/files/`
- Support auto-open file dengan Open File app

### iOS

- File tersimpan di Application Documents directory
- Tidak perlu permission khusus untuk app directory
- Auto-open mungkin tidak work (iOS restriction)

---

## 🎯 Features Recap

✅ **Statistik PM**

- Total sudah/belum PM
- Doughnut chart
- Bar chart per bulan
- Progress percentage

✅ **Unit List dengan Filter**

- Filter: All, Sudah PM, Belum PM
- Visual badge status
- Detail unit information

✅ **Download Excel**

- CSV format
- Semua kolom update_jobs
- Auto-save ke Downloads
- Auto-open file

✅ **Permissions & Security**

- Hanya Super Admin
- Branch-based filtering
- Role-based access control

---

## 📞 Support

Jika ada kendala:

1. **Check Logs**: Lihat console untuk error messages
2. **Verify API**: Test API endpoint dengan Postman/curl
3. **Check Permissions**: Pastikan AndroidManifest.xml sudah benar
4. **Clean Build**: `flutter clean && flutter pub get`

---

## 🔄 Next Steps (Optional Enhancements)

1. **Excel XLSX Format**

   - Add `syncfusion_flutter_xlsio` dependency
   - Implement styled Excel export

2. **Date Range Filter**

   - Add date picker untuk filter by period
   - Show stats for specific date range

3. **PDF Report**

   - Add `pdf` package
   - Generate formatted PDF report

4. **Email Functionality**
   - Add `mailer` package
   - Send report via email

---

**✅ Integrasi Selesai! Dashboard Admin siap digunakan.**

Jika ada pertanyaan atau butuh modifikasi, silakan hubungi developer.
"
