# DRR SAKTI - DRR Unit Assets Management

Aplikasi manajemen aset unit DRR (Disaster Risk Reduction) yang dirancang untuk mempermudah pelacakan, pengelolaan, dan pelaporan aset operasional.

## 📂 Struktur Folder

Struktur proyek diatur secara modular di dalam folder `lib/` untuk memudahkan pengembangan dan pemeliharaan:

- **`lib/constants/`**: Menyimpan nilai-nilai konstan seperti warna (`colors.dart`), gaya teks (`typography.dart`), dan konfigurasi global lainnya.
- **`lib/models/`**: Definisi kelas data (Data Models) seperti `User`, `Asset`, dll.
- **`lib/screens/`**: Berisi halaman-halaman antarmuka pengguna (UI).
  - `login_screen.dart`: Halaman autentikasi pengguna.
  - `home_screen.dart`: Halaman utama setelah login.
  - `dashboard_home_screen.dart`: Dashboard ringkasan data.
  - Sub-folder fitur: `delivery/`, `penarikan/`, `unit_assets/`, dll.
- **`lib/services/`**: Logika bisnis dan komunikasi dengan backend/API (contoh: `auth_service.dart`).
- **`lib/widgets/`**: Komponen UI yang dapat digunakan kembali (reusable widgets).
- **`lib/utils/`**: Fungsi utilitas dan helper.

## 🔄 Alur Aplikasi (Flow)

1. **Inisialisasi**:
   - Aplikasi dimulai dari `main.dart`.
   - Melakukan inisialisasi `WidgetsFlutterBinding` dan `MobileAds` (Google AdMob).
   
2. **Autentikasi (Login)**:
   - Pengguna disambut dengan halaman Login.
   - Input: **NRPP** dan **Password**.
   - Validasi dilakukan melalui `AuthService`.
   - **Iklan**: Menampilkan Banner Ad di halaman login dan Interstitial Ad saat login berhasil sebelum masuk ke Home.

3. **Navigasi Utama**:
   - Setelah login sukses, pengguna diarahkan ke `HomeScreen`.
   - Dari sini pengguna dapat mengakses berbagai modul seperti Dashboard, Delivery, Penarikan, dll.

## 🔐 Izin & Akses (Permissions)

Aplikasi ini memerlukan beberapa izin akses perangkat untuk berfungsi secara optimal, sebagaimana didefinisikan dalam `AndroidManifest.xml`:

- **Kamera** (`android.permission.CAMERA`): Untuk memindai barcode/QR code atau mengambil foto aset.
- **Lokasi** (`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`): Untuk pelacakan lokasi aset atau validasi lokasi input.
- **Internet** (`android.permission.INTERNET`): Untuk komunikasi data dengan server dan memuat iklan.
- **Status Jaringan** (`ACCESS_NETWORK_STATE`): Memeriksa ketersediaan koneksi internet.
- **Media/Penyimpanan** (`READ_MEDIA_IMAGES`): Mengakses galeri untuk upload foto.
- **Notifikasi** (`POST_NOTIFICATIONS`): Mengirimkan pemberitahuan terkait status aset atau tugas.

## 🎨 Tampilan Antarmuka (UI/UX)

Desain aplikasi mengutamakan kemudahan penggunaan dan estetika modern:

- **Tema Visual**: 
  - Menggunakan warna primer Biru dengan variasi gradient untuk elemen visual utama.
  - Desain berbasis **Material 3**.
- **Halaman Login**:
  - Header dengan logo gradient dan efek bayangan (shadow) untuk kesan kedalaman.
  - Form input yang bersih dengan validasi real-time.
  - Indikator loading saat proses autentikasi.
- **Interaksi**:
  - Transisi antar layar yang halus.
  - Umpan balik visual (Dialog, Snackbar) untuk aksi sukses atau gagal.

## 🔧 Troubleshooting

### Masalah CORS di Web (Development)
Jika Anda mengalami error CORS saat menjalankan aplikasi di browser (web) dengan pesan seperti:
`Access-Control-Allow-Origin response header...`

Ini terjadi karena browser memblokir akses ke API remote (`drr.exprosa.com`) dari `localhost`.

**Solusi:**

1. **Menggunakan VS Code (Rekomendasi):**
   - Buka tab **Run and Debug** (Ctrl+Shift+D).
   - Pilih konfigurasi **"Flutter Web (Disable CORS)"**.
   - Tekan tombol Play atau F5.
   - Ini akan membuka Chrome dengan flag keamanan dinonaktifkan khusus untuk sesi ini.

2. **Menggunakan Terminal:**
   Jalankan perintah berikut:
   ```bash
   flutter run -d chrome --web-browser-flag "--disable-web-security"
   ```

> [!IMPORTANT]
> Gunakan mode ini **hanya untuk pengembangan**. Jangan gunakan instance browser ini untuk browsing internet biasa karena fitur keamanan dimatikan.
