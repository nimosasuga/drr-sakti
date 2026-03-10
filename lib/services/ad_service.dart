// lib/services/ad_service.dart

import 'package:flutter/foundation.dart'; // Diperlukan untuk kDebugMode
import 'dart:developer';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // ===========================================================================
  // ID IKLAN (REAL dan TEST)
  // ===========================================================================

  // 1. GOOGLE TEST IDS (Wajib dipakai saat Development/Debug)
  // Ini adalah ID resmi dari Google untuk pengetesan.
  static const String _googleTestBannerId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _googleTestInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';

  // 2. YOUR REAL IDS (Hanya dipakai saat Release/Upload ke PlayStore)
  // Ganti dengan ID unit iklan Anda yang sesungguhnya.
  static const String _realBannerId = 'ca-app-pub-1438910997839159/6042963507';
  static const String _realInterstitialId =
      'ca-app-pub-1438910997839159/7017844262';

  // ID Perangkat Uji (Opsional: Tambahkan ID perangkat fisik Anda)
  // static const List<String> _testDeviceIds = ['ID_PERANGKAT_ANDA'];

  // 3. LOGIKA PEMILIHAN ID OTOMATIS BERDASARKAN MODE APLIKASI
  String get bannerAdUnitId {
    String id = kDebugMode ? _googleTestBannerId : _realBannerId;
    log(
      'AdMob Banner ID used: $id (Mode: ${kDebugMode ? "DEBUG - TEST ID" : "RELEASE - REAL ID"})',
    );
    return id;
  }

  String get interstitialAdUnitId {
    String id = kDebugMode ? _googleTestInterstitialId : _realInterstitialId;
    log(
      'AdMob Interstitial ID used: $id (Mode: ${kDebugMode ? "DEBUG - TEST ID" : "RELEASE - REAL ID"})',
    );
    return id;
  }

  // ===========================================================================

  // Instance iklan yang disimpan
  InterstitialAd? _interstitialAd;
  bool _isInitialized = false;

  // Initialize AdMob (Dipanggil di main.dart)
  Future<void> initialize() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    if (_isInitialized) return;

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      log('AdMob initialized successfully by AdService');

      // Jika Anda menggunakan ID Perangkat Uji:
      // RequestConfiguration configuration = RequestConfiguration(testDeviceIds: _testDeviceIds);
      // MobileAds.instance.updateRequestConfiguration(configuration);
    } catch (e) {
      log('Failed to initialize AdMob: $e');
    }
  }

  // Muat Iklan Interstitial
  Future<void> loadInterstitialAd() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    if (!_isInitialized) await initialize();
    if (_interstitialAd != null) return; // Jangan muat ulang jika sudah ada

    try {
      await InterstitialAd.load(
        adUnitId: interstitialAdUnitId, // Menggunakan logika auto-switch ID
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            _interstitialAd = ad;
            log('Interstitial ad loaded successfully (via AdService)');
          },
          onAdFailedToLoad: (LoadAdError error) {
            log('Interstitial ad failed to load (via AdService): $error');
            _interstitialAd = null;
          },
        ),
      );
    } catch (e) {
      log('Error loading interstitial ad: $e');
    }
  }

  // Dapatkan unit iklan banner (tanpa memuat, hanya untuk AdWidget)
  BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: bannerAdUnitId, // Menggunakan logika auto-switch ID
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) => log('Banner ad loaded (via AdService).'),
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          log('Banner ad failed to load (via AdService): $error');
          ad.dispose();
        },
      ),
    );
  }

  // Getter untuk interstitial ad
  InterstitialAd? get interstitialAd => _interstitialAd;

  // Fungsi untuk menghapus instance iklan interstitial
  void clearInterstitialAd() {
    _interstitialAd = null;
  }

  // Hapus semua iklan (untuk dispose global)
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
