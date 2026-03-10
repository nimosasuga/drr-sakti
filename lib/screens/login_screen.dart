// lib/screens/login_screen.dart (Revisi - Implementasi AdService dan Perbaikan Struktur)

import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../constants/colors.dart';
import '../constants/typography.dart';
import '/screens/home_screen.dart';
// 👈 PENTING: Impor AdService yang aman
import '../services/ad_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nrppController = TextEditingController();
  final _passwordController = TextEditingController();
  // 💡 Note: _isLoading dan _obscurePassword dipertahankan karena digunakan di _buildLoginForm
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _hasNavigated = false;

  // Hapus semua variabel dan ID AdMob lokal.
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  // InterstitialAd? _interstitialAd; <- Dikelola oleh AdService
  // bool _isInterstitialAdLoaded = false; <- Dikelola oleh AdService
  // static const String testBannerId = '...'; <- Dikelola oleh AdService
  // static const String testInterstitialId = '...'; <- Dikelola oleh AdService

  User? _user;

  // Instance AdService
  final AdService _adService = AdService();

  @override
  void initState() {
    super.initState();
    // Ganti logika AdMob lama dengan AdService
    _loadAds();
  }

  void _loadAds() {
    if (kIsWeb) return;

    // 1. Muat Iklan Banner menggunakan AdService
    _bannerAd = _adService.createBannerAd();
    _bannerAd!
        .load()
        .then((_) {
          if (mounted) {
            setState(() {
              _isBannerAdLoaded = true;
            });
          }
        })
        .catchError((error) {
          log('Banner load failed (via AdService): $error');
          _isBannerAdLoaded = false;
        });

    // 2. Muat Iklan Interstisial (AdService akan menggunakan ID yang aman)
    _adService.loadInterstitialAd();
  }

  // Hapus _loadBannerAd() dan _loadInterstitialAd() yang lama

  void _showInterstitialAd() {
    if (_hasNavigated) {
      log('Already navigated, skipping ad');
      return;
    }

    // Ambil InterstitialAd dari AdService
    final InterstitialAd? interstitialAd = _adService.interstitialAd;

    if (interstitialAd != null) {
      log('Showing interstitial ad');

      // Setup FullScreenContentCallback untuk menangani navigasi
      interstitialAd.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (InterstitialAd ad) {
          log('Interstitial ad showed full screen');
        },
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          log('Interstitial ad dismissed');
          // ⚠️ PENTING: AdService yang akan menangani ad.dispose() dan muat ulang
          // Navigasi setelah iklan selesai
          _navigateToHome();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          log('Interstitial ad failed to show: $error');
          // ⚠️ PENTING: AdService yang akan menangani ad.dispose() dan muat ulang
          // Jika iklan gagal tampil, tetap navigasi
          _navigateToHome();
        },
      );

      try {
        interstitialAd.show();
      } catch (e) {
        log('Error when calling interstitialAd.show(): $e');
        // Jika gagal tampil, navigasi langsung dan coba muat ulang iklan
        _adService.loadInterstitialAd();
        _navigateToHome();
      }
    } else {
      log('Interstitial ad not ready, navigating directly');
      _navigateToHome();
      // Coba muat lagi untuk kali berikutnya
      _adService.loadInterstitialAd();
    }
  }

  void _navigateToHome() {
    if (_hasNavigated) {
      log('Already navigated, skipping duplicate navigation');
      return;
    }

    if (!mounted) {
      log('Widget not mounted, cannot navigate');
      return;
    }

    if (_user == null) {
      log('User data is null, cannot navigate');
      return;
    }

    _hasNavigated = true;
    log('Navigating to home screen');

    // PERBAIKAN: Gunakan WidgetsBinding untuk memastikan navigation terjadi setelah frame selesai
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(user: _user!)),
        (route) => false,
      );
    });
    if (_hasNavigated) {
      log('Already navigated, skipping duplicate navigation');
      return;
    }
    if (!mounted) {
      log('Widget not mounted, cannot navigate');
      return;
    }

    if (_user == null) {
      log('User data is null, cannot navigate');
      return;
    }

    _hasNavigated = true;
    log('Navigating to home screen');

    // PERBAIKAN: Hapus WidgetsBinding.instance.addPostFrameCallback((_)
    // Navigasi langsung di sini, atau di callback AdMob, untuk menghindari masalah konteks.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen(user: _user!)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildHeaderSection(),
              const SizedBox(height: 32),

              if (_isBannerAdLoaded && _bannerAd != null) _buildAdBanner(),

              const SizedBox(height: 16),

              _buildLoginForm(),
              const SizedBox(height: 24),

              _buildFooterSection(),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // 👇 METODE YANG PERLU DIKEMBALIKAN UNTUK MENGHILANGKAN UNDEFINED_METHOD
  // =========================================================

  Widget _buildHeaderSection() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(76),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.forklift, size: 80, color: Colors.white),
        ),
        const SizedBox(height: 24),

        Text(
          'DRR SAKTI',
          style: AppTextStyles.headlineLarge.copyWith(
            color: AppColors.primary,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 15),
        Text(
          'Rental Management System',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.disabled),
        ),
      ],
    );
  }

  Widget _buildAdBanner() {
    return Container(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      alignment: Alignment.center,
      child: AdWidget(ad: _bannerAd!),
    );
  }

  Widget _buildLoginForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _nrppController,
            decoration: InputDecoration(
              labelText: 'NRPP',
              prefixIcon: const Icon(Icons.person, color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.disabled),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'NRPP harus diisi';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock, color: AppColors.primary),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: AppColors.disabled,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password harus diisi';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('MASUK', style: AppTextStyles.button),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterSection() {
    return Column(
      children: [
        Text(
          'Pastikan NRPP dan Password sudah benar',
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info, size: 14, color: AppColors.disabled),
            const SizedBox(width: 4),
            Text(
              'Hubungi admin jika lupa password',
              style: AppTextStyles.caption,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.disabled.withAlpha(100)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.ads_click, size: 12, color: AppColors.disabled),
              const SizedBox(width: 4),
              Text(
                'Ads by google admob',
                style: AppTextStyles.caption.copyWith(fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _login() async {
    // Reset flag navigasi saat login ulang
    _hasNavigated = false;

    // Validate fields
    if (_nrppController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorDialog('NRPP dan Password harus diisi');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      final result = await authService.login(
        _nrppController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (result['success'] == true && result['user'] != null) {
        _user = result['user'] as User;
        log('Login successful, user: ${_user!.name}');

        // PERBAIKAN: Tambahkan delay kecil sebelum menampilkan ad/navigate
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _showInterstitialAd();
          }
        });
      } else {
        _showErrorDialog(result['message'] ?? 'Login gagal');
      }
      if (result['success'] == true && result['user'] != null) {
        _user = result['user'] as User;
        log('Login successful, user: ${_user!.name}');

        // PERBAIKAN: Hapus Future.delayed() di sini.
        // Panggil _showInterstitialAd() langsung.
        // Penanganan error / loading sudah ada di _showInterstitialAd().
        _showInterstitialAd();
      } else {
        _showErrorDialog(result['message'] ?? 'Login gagal');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      _showErrorDialog('Terjadi kesalahan: $e');
      log('Login error: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error, color: AppColors.error),
            const SizedBox(width: 8),
            Text('Login Gagal', style: AppTextStyles.headlineSmall),
          ],
        ),
        content: Text(message, style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'COBA LAGI',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================

  @override
  void dispose() {
    _nrppController.dispose();
    _passwordController.dispose();
    _bannerAd?.dispose();
    // ⚠️ Hapus: _interstitialAd?.dispose(); karena sudah di-dispose oleh AdService
    super.dispose();
  }
}
