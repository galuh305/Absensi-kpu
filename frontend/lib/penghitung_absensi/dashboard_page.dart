import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:frontend/login/login_page.dart';
import 'package:frontend/models.dart';
import 'package:frontend/absensi/attendance_form_page.dart';
import 'package:frontend/penghitung_absensi/laporan_page.dart';
import 'package:frontend/config/api_host.dart';
import 'package:frontend/util/download_report_csv.dart';

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
      apiUri('/api/laporan'),
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

  Future<void> _downloadExcel(List<AttendanceRecord> records) async {
    final buffer = StringBuffer();
    buffer.writeln(
        'No,Nama,Email,Status Pegawai,Posisi,Tanggal,Jam Masuk,Jam Pulang,Total Jam Kerja,Potongan');

    for (int i = 0; i < records.length; i++) {
      final r = records[i];
      final tanggalStr =
          '${r.tanggal.day.toString().padLeft(2, '0')}-${r.tanggal.month.toString().padLeft(2, '0')}-${r.tanggal.year}';
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
      final escapedRow = row.map((field) => '"$field"').join(',');
      buffer.writeln(escapedRow);
    }

    final bytes = utf8.encode(buffer.toString());
    try {
      await downloadReportCsv(bytes, 'Laporan_Absensi.csv');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengekspor CSV: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = widget.account.role == 'admin';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Absen'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _futureAbsensi = fetchAbsensi();
              });
            },
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToForm,
        icon: const Icon(Icons.assignment_turned_in_outlined, size: 20),
        label: const Text('Isi Absen'),
        extendedPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      body: FutureBuilder<List<AttendanceRecord>>(
        future: _futureAbsensi,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Gagal memuat data:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            children: [
              _HeaderCard(
                name: widget.account.name,
                email: widget.account.email,
                role: widget.account.role,
              ),
              const SizedBox(height: 14),
              if (isAdmin) ...[
                _SectionTitle(
                  icon: Icons.groups_rounded,
                  title: 'Rekap Semua Pegawai',
                ),
                const SizedBox(height: 8),
                _StatWrap(
                  items: [
                    _CounterCard(
                      label: 'Total Submit',
                      value: totalGlobal,
                      icon: Icons.all_inbox_rounded,
                    ),
                    _CounterCard(
                      label: 'Hadir (Masuk)',
                      value: hadirGlobal,
                      icon: Icons.login_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _CompactActionButton(
                          onPressed:
                              records.isEmpty ? null : () => _goToLaporan(records),
                          icon: Icons.list_alt_rounded,
                          label: 'Laporan',
                        ),
                        _CompactActionButton(
                          onPressed: records.isEmpty
                              ? null
                              : () => _downloadExcel(records),
                          icon: Icons.file_download_rounded,
                          label: 'Unduh CSV',
                        ),
                        if (records.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 2),
                            child: Text(
                              'Belum ada data.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ] else ...[
                _SectionTitle(
                  icon: Icons.person_outline_rounded,
                  title: 'Ringkasan Absen Saya',
                ),
                const SizedBox(height: 8),
                _StatWrap(
                  items: [
                    _CounterCard(
                      label: 'Total Absen',
                      value: totalSaya,
                      icon: Icons.fact_check_rounded,
                    ),
                    _CounterCard(
                      label: 'Hadir (Masuk)',
                      value: hadirSaya,
                      icon: Icons.login_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (myRecords.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            height: 34,
                            width: 34,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.history_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 17,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Absen terakhir: '
                              '${myRecords.last.tanggal.day.toString().padLeft(2, "0")}-${myRecords.last.tanggal.month.toString().padLeft(2, "0")}-${myRecords.last.tanggal.year} '
                              '${myRecords.last.jamMasuk.isNotEmpty ? myRecords.last.jamMasuk : myRecords.last.jamPulang}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
              ],
              if (isAdmin) ...[
                _SectionTitle(
                  icon: Icons.history_rounded,
                  title: 'Riwayat Absen Semua Pegawai',
                ),
                const SizedBox(height: 8),
                if (records.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        'Belum ada data absensi.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
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
                _SectionTitle(
                  icon: Icons.event_note_rounded,
                  title: 'Riwayat Absen Saya',
                ),
                const SizedBox(height: 8),
                if (myRecords.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        'Belum ada data absensi Anda.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
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
    final cs = Theme.of(context).colorScheme;
    final icon = record.jamMasuk.isNotEmpty ? Icons.login_rounded : Icons.logout_rounded;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 30,
                  width: 30,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: cs.primary, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    showName && record.nama.isNotEmpty
                        ? '${record.nama} (${record.statusKepegawaian.toUpperCase()})'
                        : record.statusKepegawaian.toUpperCase(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Text(
                  jam,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Jenis: $type · Lokasi: ${record.posisi}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              tanggalStr,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: cs.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.name,
    required this.email,
    required this.role,
  });

  final String name;
  final String email;
  final String role;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isAdmin = role == 'admin';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.primaryContainer.withValues(alpha: 0.55),
              cs.surface,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                  color: cs.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, $name',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 8),
                    _RoleChip(
                      label: isAdmin ? 'Admin' : 'Pegawai',
                      icon: isAdmin
                          ? Icons.verified_user_rounded
                          : Icons.badge_rounded,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: cs.primary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterCard extends StatelessWidget {
  const _CounterCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: cs.primary, size: 17),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onPrimaryContainer.withValues(alpha: 0.9),
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onPrimaryContainer,
                ),
          ),
        ],
      ),
    );
  }
}

class _StatWrap extends StatelessWidget {
  const _StatWrap({required this.items});

  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        const spacing = 10.0;
        final isNarrow = maxW < 380;
        final itemWidth = isNarrow ? maxW : (maxW - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.map((w) => SizedBox(width: itemWidth, child: w)).toList(),
        );
      },
    );
  }
}

class _CompactActionButton extends StatelessWidget {
  const _CompactActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon, size: 15),
      label: Text(label),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: const Size(0, 30),
        maximumSize: const Size.fromHeight(34),
        textStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          height: 1.1,
          color: cs.onSecondaryContainer,
        ),
        iconSize: 15,
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
