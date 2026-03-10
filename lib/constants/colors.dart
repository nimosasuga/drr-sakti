// lib/constants/colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Colors
  static const Color primary = Color(0xFF1a237e); // Dark Blue - DRR Brand
  static const Color primaryLight = Color(0xFF534bae); // Light Blue
  static const Color primaryDark = Color(0xFF000051); // Darker Blue

  // Secondary Colors
  static const Color secondary = Color(0xFF00b0ff); // Bright Blue
  static const Color accent = Color(0xFFffab00); // Amber/Orange

  // Status Colors
  static const Color success = Color(0xFF4caf50); // Green
  static const Color warning = Color(0xFFff9800); // Orange
  static const Color error = Color(0xFFf44336); // Red
  static const Color info = Color(0xFF2196f3); // Blue

  // Neutral Colors
  static const Color background = Color(0xFFf5f5f5); // Light Grey
  static const Color surface = Color(0xFFffffff); // White
  static const Color onSurface = Color(0xFF212121); // Dark Grey
  static const Color disabled = Color(0xFF9e9e9e); // Grey

  // Status Badge Colors
  static const Color active = Color(0xFF4caf50); // Green
  static const Color backup = Color(0xFF2196f3); // Blue
  static const Color rental = Color(0xFFff9800); // Orange
  static const Color inactive = Color(0xFFf44336); // Red

  // Job Status Colors
  static const Color rfu = Color(0xFF4caf50); // Green
  static const Color breakdown = Color(0xFFf44336); // Red
  static const Color monitoring = Color(0xFFff9800); // Orange
  static const Color waitingPart = Color(0xFF9c27b0); // Purple

  // Text & Background Colors
  static const Color textDefault = Color(
    0xFF212121,
  ); // Dark Gray (Pengganti textPrimary)
  static const Color white = Colors.white;

  // Perbaikan: Tambahkan properti textPrimary untuk kompatibilitas mundur
  static const Color textPrimary = textDefault;
}
