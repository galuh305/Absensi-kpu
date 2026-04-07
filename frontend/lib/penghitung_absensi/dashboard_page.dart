import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:frontend/login/login_page.dart';
import 'package:frontend/models.dart';
import 'package:frontend/absensi/attendance_form_page.dart';
import 'package:frontend/penghitung_absensi/laporan_page.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.account});

  final UserAccount account;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<List<AttendanceRecord>> _futureAbsensi;

  @override
  void initState() {
    super.initState();
    _futureAbsensi = fetchAbsensi();
  }

  Future<List<AttendanceRecord>> fetchAbsensi() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final response = await http.get(
      Uri.parse('http://127.0.0.1:8000/api/laporan'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => AttendanceRecord.fromJson(json)).toList();
    } else {
      throw Exception('Gagal mengambil data absensi');
    }
  }

  void _goToForm() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AttendanceFormPage(account: widget.account),
      ),
    );
    setState(() {
      _futureAbsensi = fetchAbsensi();
    });
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _goToLaporan(List<AttendanceRecord> records) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LaporanPage(records: records)),
    );
  }

  void _downloadExcel(List<AttendanceRecord> records) {
    // Buat isi CSV (Comma Separated Values)
    final buffer = StringBuffer();
    // Header
    buffer.writeln('No,Nama,Email,Status Pegawai,Posisi,Tanggal,Jam Masuk,Jam Pulang,Total Jam Kerja,Potongan');
    
    // Baris
    for (int i = 0; i < records.length; i++) {
      final r = records[i];
      final tanggalStr = '${r.tanggal.day.toString().padLeft(2, '0')}-${r.tanggal.month.toString().padLeft(2, '0')}-${r.tanggal.year}';
      final row = [
        (i + 1).toString(),
        r.nama,
        r.email,
        r.statusKepegawaian,
        r.posisi,
        tanggalStr,
        r.jamMasuk.isNotEmpty ? r.jamMasuk : '-',
        r.jamPulang.isNotEmpty ? r.jamPulang : '-',
        r.totalJamKerja ?? '-',
        '${r.potongan ?? 0}%',
      ];
      // Escape CSV untuk aman kalau ada koma
      final escapedRow = row.map((field) => '"$field"').join(',');
      buffer.writeln(escapedRow);
    }

    final bytes = utf8.encode(buffer.toString());
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'Laporan_Absensi.csv')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = widget.account.role == 'admin';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Absen'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToForm,
        icon: const Icon(Icons.assignment_turned_in_outlined),
        label: const Text('Isi Absen'),
      ),
      body: FutureBuilder<List<AttendanceRecord>>(
        future: _futureAbsensi,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Gagal memuat data: \\n${snapshot.error}'),
            );
          }
          final records = snapshot.data ?? [];
          final myRecords = records
              .where((r) => r.userId == widget.account.id)
              .toList();
          final totalGlobal = records.length;
          final hadirGlobal = records
              .where((r) => r.jamMasuk.isNotEmpty)
              .length;
          
          final totalSaya = myRecords.length;
          final hadirSaya = myRecords
              .where((r) => r.jamMasuk.isNotEmpty)
              .length;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, ${widget.account.name}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text('${widget.account.email}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (isAdmin) ...[
                Text(
                  'Rekap Semua Pegawai',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _CounterCard(label: 'Total Submit', value: totalGlobal),
                    _CounterCard(label: 'Hadir (Masuk)', value: hadirGlobal),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: () => _goToLaporan(records),
                      icon: const Icon(Icons.list_alt),
                      label: const Text('Lihat Laporan'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      onPressed: () => _downloadExcel(records),
                      icon: const Icon(Icons.file_download),
                      label: const Text('Unduh File Excel (.csv)'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ] else ...[
                Text(
                  'Ringkasan Absen Saya',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _CounterCard(label: 'Total Absen', value: totalSaya),
                    _CounterCard(label: 'Hadir', value: hadirSaya),
                  ],
                ),
                const SizedBox(height: 14),
                if (myRecords.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Absen terakhir: '
                        '${myRecords.last.tanggal.day.toString().padLeft(2, "0")}-${myRecords.last.tanggal.month.toString().padLeft(2, "0")}-${myRecords.last.tanggal.year} '
                        '${myRecords.last.jamMasuk.isNotEmpty ? myRecords.last.jamMasuk : myRecords.last.jamPulang}',
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
              ],
              if (isAdmin) ...[
                Text(
                  'Riwayat Absen Semua Pegawai',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (records.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Belum ada data absensi.'),
                    ),
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Absen Masuk', style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 6),
                            ...records.where((r) => r.jamMasuk.isNotEmpty).toList().reversed.map((record) => _buildHistoryCard(record, true)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Absen Pulang', style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 6),
                            ...records.where((r) => r.jamMasuk.isEmpty).toList().reversed.map((record) => _buildHistoryCard(record, true)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ] else ...[
                Text(
                  'Riwayat Absen Saya',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (myRecords.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Belum ada data absensi Anda.'),
                    ),
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Absen Masuk', style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 6),
                            ...myRecords.where((r) => r.jamMasuk.isNotEmpty).toList().reversed.map((record) => _buildHistoryCard(record, false)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Absen Pulang', style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 6),
                            ...myRecords.where((r) => r.jamMasuk.isEmpty).toList().reversed.map((record) => _buildHistoryCard(record, false)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(AttendanceRecord record, bool showName) {
    final tanggalStr = '${record.tanggal.day.toString().padLeft(2, "0")}-${record.tanggal.month.toString().padLeft(2, "0")}-${record.tanggal.year}';
    final type = record.jamMasuk.isNotEmpty ? 'Masuk' : 'Pulang';
    final jam = record.jamMasuk.isNotEmpty ? record.jamMasuk : record.jamPulang;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showName && record.nama.isNotEmpty)
              Text(
                '${record.nama} (${record.statusKepegawaian.toUpperCase()})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              )
            else
              Text(
                record.statusKepegawaian.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 4),
            Text('$type: $jam'),
            Text('Lokasi: ${record.posisi}'),
            const SizedBox(height: 4),
            Text(
              tanggalStr,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _CounterCard extends StatelessWidget {
  const _CounterCard({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 165,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text('$value', style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }
}
