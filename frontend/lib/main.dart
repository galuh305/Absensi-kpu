import 'package:flutter/material.dart';
import 'package:frontend/login/login_page.dart';
import 'package:frontend/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aplikasi Absen KPU',
      theme: AppTheme.light(),
      home: const LoginPage(),
    );
  }
}
