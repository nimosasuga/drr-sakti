// lib/main.dart (Revisi)

import 'dart:developer';
import 'package:flutter/material.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart'; // Hapus: Tidak perlu diimpor di sini
import 'screens/login_screen.dart';
// 👈 Tambahkan: Impor AdService
import '../services/ad_service.dart';

void main() async {
  // Enable logging in release mode
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null) {
      log('DRR_APP: $message');
    }
  };

  // FIX: Initialize bindings FIRST
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Panggil Inisialisasi melalui AdService
  // AdService akan menentukan apakah ini web atau mobile.
  await AdService().initialize();

  // Hapus blok inisialisasi MobileAds yang lama:
  /*
  if (!kIsWeb) {
    try {
      await MobileAds.instance.initialize();
      log('AdMob initialized successfully');
    } catch (e) {
      log('AdMob initialization error on mobile: $e');
    }
  } else {
    log('AdMob skipped: Running on Web');
  }
  */

  // Run app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DRR SAKTI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
      routes: {'/login': (context) => const LoginScreen()},
    );
  }
}
