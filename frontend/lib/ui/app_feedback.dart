import 'dart:convert';

import 'package:flutter/material.dart';

class AppFeedback {
  static void success(BuildContext context, String message) {
    _show(
      context,
      title: 'Berhasil',
      message: message,
      icon: Icons.check_circle_rounded,
      background: const Color(0xFF0F5132),
    );
  }

  static void error(BuildContext context, String message) {
    _show(
      context,
      title: 'Gagal',
      message: message,
      icon: Icons.error_rounded,
      background: const Color(0xFF7A1C1C),
    );
  }

  static void _show(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    required Color background,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: background,
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String extractApiMessage(String responseBody) {
  try {
    final decoded = jsonDecode(responseBody);
    if (decoded is Map && decoded['message'] is String) {
      return decoded['message'] as String;
    }
  } catch (_) {
    // ignore
  }
  return responseBody;
}

String humanizeRegisterError(String rawMessage, {String? email}) {
  final msg = rawMessage.toLowerCase();
  if (msg.contains('sqlstate') && msg.contains('duplicate entry')) {
    if (email != null && email.trim().isNotEmpty) {
      return 'Email "$email" sudah terdaftar. Silakan gunakan email lain atau login.';
    }
    return 'Email sudah terdaftar. Silakan gunakan email lain atau login.';
  }
  if (msg.contains('email') && msg.contains('already') && msg.contains('taken')) {
    return 'Email sudah terdaftar. Silakan gunakan email lain atau login.';
  }
  // fallback: bersihkan noise SQL biar tidak terlalu panjang
  final cleaned = rawMessage
      .replaceAll(r'\n', '\n')
      .replaceAll(RegExp(r'SQLSTATE\[[^\]]+\]:\s*', caseSensitive: false), '')
      .trim();
  if (cleaned.length > 180) {
    return '${cleaned.substring(0, 180)}...';
  }
  return cleaned.isEmpty ? 'Terjadi kesalahan. Coba lagi.' : cleaned;
}

String humanizeLoginError(String rawMessage, {String? email}) {
  final msg = rawMessage.toLowerCase();

  // Variasi message backend yang umum
  if (msg.contains('tidak terdaftar') ||
      msg.contains('belum terdaftar') ||
      msg.contains('user not found') ||
      (msg.contains('email') && msg.contains('not found'))) {
    if (email != null && email.trim().isNotEmpty) {
      return 'Email "$email" belum terdaftar. Silakan daftar terlebih dahulu.';
    }
    return 'Email belum terdaftar. Silakan daftar terlebih dahulu.';
  }

  // Kredensial salah
  if (msg.contains('login gagal') ||
      msg.contains('invalid credentials') ||
      msg.contains('unauthorized') ||
      msg.contains('password') ||
      msg.contains('credentials') ||
      msg.contains('email atau password')) {
    return 'password salah.';
  }

  final cleaned = rawMessage.replaceAll(r'\n', '\n').trim();
  return cleaned.isEmpty ? 'Password salah.' : cleaned;
}
