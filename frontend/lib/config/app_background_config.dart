import 'package:flutter/material.dart';

/// Pengaturan latar belakang gambar semi-transparan.
///
/// **Cara pakai**
/// 1. Letakkan file gambar di folder `assets/images/` (mis. `app_background.jpg`).
/// 2. Pastikan nama file sama dengan [assetPath] di bawah.
/// 3. Atur [imageOpacity] (0–1): semakin kecil, gambar semakin pudar.
/// 4. Atur [scrimOpacity] + [scrimColor]: lapisan di atas gambar agar konten tetap terbaca.
class AppBackgroundConfig {
  AppBackgroundConfig._();

  /// Path aset relatif ke root proyek (harus terdaftar di `pubspec.yaml` → `assets:`).
  static const String assetPath = 'assets/images/bgkonten.png';

  /// Opasitas **gambar** (bukan layar penuh). `1.0` = gambar penuh, `0.35` = sangat tembus pandang.
  static const double imageOpacity = 0.45;

  /// Warna "kabut" di atas gambar (biasanya putih atau hitam lembut).
  static const Color scrimColor = Color(0xFF0B1220);

  /// Opasitas kabut; naikkan jika teks/form sulit dibaca.
  static const double scrimOpacity = 0.40;

  /// Warna cadangan jika file gambar belum ada atau gagal dimuat.
  static const Color fallbackColor = Color(0xFF0B1220);
}
