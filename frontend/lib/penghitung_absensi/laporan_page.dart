import 'package:flutter/material.dart';
import 'package:frontend/models.dart';

class LaporanPage extends StatelessWidget {
  const LaporanPage({super.key, required this.records});

  final List<AttendanceRecord> records;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Absensi'),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('No')),
              DataColumn(label: Text('Nama')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Status Pegawai')),
              DataColumn(label: Text('Posisi')),
              DataColumn(label: Text('Tanggal')),
              DataColumn(label: Text('Jam Masuk')),
              DataColumn(label: Text('Jam Pulang')),
              DataColumn(label: Text('Total Jam Kerja')),
              DataColumn(label: Text('Potongan')),
            ],
            rows: List.generate(records.length, (index) {
              final r = records[index];
              return DataRow(cells: [
                DataCell(Text('${index + 1}')),
                DataCell(Text(r.nama)),
                DataCell(Text(r.email)),
                DataCell(Text(r.statusKepegawaian.toUpperCase())),
                DataCell(Text(r.posisi)),
                DataCell(Text('${r.tanggal.day.toString().padLeft(2, '0')}-${r.tanggal.month.toString().padLeft(2, '0')}-${r.tanggal.year}')),
                DataCell(Text(r.jamMasuk.isNotEmpty ? r.jamMasuk : '-')),
                DataCell(Text(r.jamPulang.isNotEmpty ? r.jamPulang : '-')),
                DataCell(Text(r.totalJamKerja ?? '-')),
                DataCell(Text(r.potongan != null ? '${r.potongan}%' : '0%')),
              ]);
            }),
          ),
        ),
      ),
    );
  }
}
