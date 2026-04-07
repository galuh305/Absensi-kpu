import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/models.dart';

class AttendanceFormPage extends StatefulWidget {
  const AttendanceFormPage({super.key, required this.account});

  final UserAccount account;

  @override
  State<AttendanceFormPage> createState() => _AttendanceFormPageState();
}

class _AttendanceFormPageState extends State<AttendanceFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _posisiController = TextEditingController();

  String _statusKepegawaian = 'PNS';
  String _jenisAbsen = 'Jam Masuk'; // "Jam Masuk" or "Jam Pulang"

  bool _isLoading = false;

  @override
  void dispose() {
    _posisiController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    String url = '';
    Map<String, dynamic> body = {};

    if (_jenisAbsen == 'Jam Masuk') {
      url = 'http://127.0.0.1:8000/api/absen-masuk';
      body = {
        'status_kepegawaian': _statusKepegawaian,
        'posisi': '-', // Nilai default supaya tidak error database jika not null
      };
    } else {
      url = 'http://127.0.0.1:8000/api/absen-pulang';
      if (_posisiController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Posisi saat ini wajib diisi')),
        );
        setState(() { _isLoading = false; });
        return;
      }
      body = {
        'status_kepegawaian': _statusKepegawaian,
        'posisi': _posisiController.text, // Simpan posisi saat jam pulang
      };
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('Absen Berhasil'),
            content: Text('Anda berhasil absen $_jenisAbsen pada sistem.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Tutup dialog
                  Navigator.of(context).pop(); // Kembali ke halaman dashboard
                },
                child: const Text('Kembali'),
              ),
            ],
          ),
        );
      } else {
        if (!mounted) return;
        final msg = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: ${msg['message'] ?? response.body}')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Koneksi bermasalah: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Form Absensi Harian')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Data akan disimpan sesuai Waktu Realtime Server',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: widget.account.name,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  border: OutlineInputBorder(),
                ),
                enabled: false,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: widget.account.email,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                enabled: false,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _jenisAbsen,
                decoration: const InputDecoration(
                  labelText: 'Pilih Absen (Jam Masuk / Jam Pulang) *',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Jam Masuk', child: Text('Jam Masuk')),
                  DropdownMenuItem(value: 'Jam Pulang', child: Text('Jam Pulang')),
                ],
                onChanged: (value) {
                  setState(() {
                    _jenisAbsen = value!;
                  });
                },
              ),
              
              if (_jenisAbsen == 'Jam Pulang') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _posisiController,
                  decoration: const InputDecoration(
                    labelText: 'Posisi saat ini *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Posisi wajib diisi';
                    }
                    return null;
                  },
                ),
              ],
              
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _statusKepegawaian,
                decoration: const InputDecoration(
                  labelText: 'Status Kepegawaian *',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'PNS', child: Text('PNS')),
                  DropdownMenuItem(value: 'PPPK', child: Text('PPPK')),
                  DropdownMenuItem(value: 'PPNPN', child: Text('PPNPN')),
                ],
                onChanged: (value) {
                  setState(() {
                    _statusKepegawaian = value!;
                  });
                },
              ),
              
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : FilledButton.icon(
                      onPressed: _submitForm,
                      icon: const Icon(Icons.send),
                      label: const Text('Submit Absen (Realtime)'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
