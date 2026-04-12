import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/config/api_host.dart';
import 'package:frontend/models.dart';
import 'package:frontend/ui/app_feedback.dart';

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

    late final Uri url;
    Map<String, dynamic> body = {};

    if (_jenisAbsen == 'Jam Masuk') {
      url = apiUri('/api/absen-masuk');
      body = {
        'status_kepegawaian': _statusKepegawaian,
        'posisi': '-', // Nilai default supaya tidak error database jika not null
      };
    } else {
      url = apiUri('/api/absen-pulang');
      if (_posisiController.text.trim().isEmpty) {
        AppFeedback.error(context, 'Posisi saat ini wajib diisi.');
        setState(() {
          _isLoading = false;
        });
        return;
      }
      body = {
        'status_kepegawaian': _statusKepegawaian,
        'posisi': _posisiController.text, // Simpan posisi saat jam pulang
      };
    }

    try {
      final response = await http.post(
        url,
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
            content: Text(
              'Absen $_jenisAbsen berhasil.\nWaktu dicatat realtime oleh server.',
            ),
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
        final msg = extractApiMessage(response.body);
        AppFeedback.error(
          context,
          msg.isEmpty ? 'Gagal mengirim absen. Coba lagi.' : msg,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      AppFeedback.error(context, 'Koneksi bermasalah. Coba lagi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Form Absensi Harian')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.fact_check_rounded, color: cs.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Absensi Realtime',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Waktu absen dicatat oleh server saat tombol Submit ditekan.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Data Pegawai',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: widget.account.name,
                        decoration: const InputDecoration(
                          labelText: 'Nama Lengkap',
                          prefixIcon: Icon(Icons.badge_rounded),
                        ),
                        enabled: false,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: widget.account.email,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.alternate_email_rounded),
                        ),
                        enabled: false,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Detail Absensi',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'Jam Masuk',
                            label: Text('Jam Masuk'),
                            icon: Icon(Icons.login_rounded),
                          ),
                          ButtonSegment(
                            value: 'Jam Pulang',
                            label: Text('Jam Pulang'),
                            icon: Icon(Icons.logout_rounded),
                          ),
                        ],
                        selected: <String>{_jenisAbsen},
                        onSelectionChanged: (selection) {
                          setState(() {
                            _jenisAbsen = selection.first;
                          });
                        },
                      ),
                      if (_jenisAbsen == 'Jam Pulang') ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _posisiController,
                          decoration: const InputDecoration(
                            labelText: 'Posisi saat ini *',
                            prefixIcon: Icon(Icons.my_location_rounded),
                          ),
                          validator: (value) {
                            if (_jenisAbsen != 'Jam Pulang') return null;
                            if (value == null || value.trim().isEmpty) {
                              return 'Posisi wajib diisi';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _statusKepegawaian,
                        decoration: const InputDecoration(
                          labelText: 'Status Kepegawaian *',
                          prefixIcon: Icon(Icons.work_rounded),
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
                      const SizedBox(height: 18),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : FilledButton.icon(
                              onPressed: _submitForm,
                              icon: const Icon(Icons.send_rounded),
                              label: const Text('Submit Absen'),
                            ),
                      const SizedBox(height: 8),
                      Text(
                        'Pastikan data sudah benar sebelum submit.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
