import 'package:flutter/material.dart';
import 'package:frontend/models.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:frontend/widgets/semi_transparent_image_background.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key, required this.records});

  final List<AttendanceRecord> records;

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  final _searchController = TextEditingController();

  /// null = semua
  int? _filterTahun;
  int? _filterBulan;
  int? _filterTanggal;

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  void _setTahun(int? v) {
    setState(() {
      _filterTahun = v;
      _filterBulan = null;
      _filterTanggal = null;
    });
  }

  void _setBulan(int? v) {
    setState(() {
      _filterBulan = v;
      _filterTanggal = null;
    });
  }

  void _setTanggal(int? v) {
    setState(() {
      if (v != null && _filterTahun != null && _filterBulan != null) {
        final maxDay = _daysInMonth(_filterTahun!, _filterBulan!);
        _filterTanggal = v > maxDay ? null : v;
      } else {
        _filterTanggal = v;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<int> _tahunDariData() {
    final now = DateTime.now().year;
    final set = <int>{
      ...widget.records.map((r) => r.tanggal.year),
      now - 1,
      now,
      now + 1,
    };
    return set.toList()..sort();
  }

  String _ringkasanFilterTanggal() {
    if (_filterTahun == null && _filterBulan == null && _filterTanggal == null) {
      return 'Menampilkan semua tanggal';
    }
    if (_filterTahun != null &&
        _filterBulan != null &&
        _filterTanggal != null) {
      final t = DateTime(_filterTahun!, _filterBulan!, _filterTanggal!);
      return 'Satu hari: ${_formatTgl(t)}';
    }
    if (_filterTahun != null && _filterBulan != null) {
      return 'Bulan: ${_namaBulan(_filterBulan!)} ${_filterTahun!}';
    }
    if (_filterTahun != null) {
      return 'Tahun: ${_filterTahun!}';
    }
    return 'Filter tanggal';
  }

  String _formatTgl(DateTime t) {
    final dd = t.day.toString().padLeft(2, '0');
    final mm = t.month.toString().padLeft(2, '0');
    return '$dd-$mm-${t.year}';
  }

  String _namaBulan(int m) {
    const names = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return names[m - 1];
  }

  bool _sesuaiFilterTanggal(AttendanceRecord r) {
    final d = r.tanggal;
    if (_filterTahun != null && d.year != _filterTahun) return false;
    if (_filterBulan != null && d.month != _filterBulan) return false;
    if (_filterTanggal != null && d.day != _filterTanggal) return false;
    return true;
  }

  void _resetSemuaFilter() {
    _searchController.clear();
    _filterTahun = null;
    _filterBulan = null;
    _filterTanggal = null;
  }

  bool _isHariIni() {
    final n = DateTime.now();
    return _filterTahun == n.year &&
        _filterBulan == n.month &&
        _filterTanggal == n.day;
  }

  bool _isBulanIni() {
    final n = DateTime.now();
    return _filterTahun == n.year &&
        _filterBulan == n.month &&
        _filterTanggal == null;
  }

  bool _isTahunIni() {
    final n = DateTime.now();
    return _filterTahun == n.year &&
        _filterBulan == null &&
        _filterTanggal == null;
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final totalRecords = widget.records.length;
    final byDate = widget.records.where(_sesuaiFilterTanggal);
    final filtered = (query.isEmpty
            ? byDate
            : byDate.where((r) {
                return r.nama.toLowerCase().contains(query) ||
                    r.email.toLowerCase().contains(query) ||
                    r.statusKepegawaian.toLowerCase().contains(query) ||
                    r.posisi.toLowerCase().contains(query);
              }))
        .toList();

    final cs = Theme.of(context).colorScheme;
    final tahunUntukStrip = <int>{
      ..._tahunDariData(),
      if (_filterTahun != null) _filterTahun!,
    }.toList()
      ..sort();
    final rowsPerPage = filtered.isEmpty
        ? 10
        : (filtered.length < 10 ? filtered.length : 10);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Absensi'),
      ),
      backgroundColor: Colors.transparent,
      body: SemiTransparentImageBackground(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: SingleChildScrollView(
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: cs.surface.withValues(alpha: 0.72),
                    surfaceTintColor: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: Theme.of(context).textTheme.bodyMedium,
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: 'Cari nama / email / status...',
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  size: 20,
                                  color: cs.primary,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 12,
                                ),
                                filled: true,
                                fillColor: cs.surfaceVariant.withValues(alpha: 0.55),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: cs.outline.withValues(alpha: 0.18),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: cs.outline.withValues(alpha: 0.18),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: cs.primary,
                                    width: 1.6,
                                  ),
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.tonalIcon(
                            onPressed: () {
                              setState(_resetSemuaFilter);
                            },
                            icon: const Icon(Icons.clear_rounded, size: 14),
                            label: const Text('Reset'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              minimumSize: const Size(0, 30),
                              textStyle: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                height: 1.1,
                                color: cs.onSecondaryContainer,
                              ),
                              iconSize: 14,
                              visualDensity: VisualDensity.compact,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(
                        height: 18,
                        thickness: 1,
                        color: cs.outline.withValues(alpha: 0.10),
                      ),
                      Row(
                        children: [
                          Icon(Icons.tune_rounded, size: 20, color: cs.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Filter tanggal',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _PlainDateFilters(
                        tahunList: tahunUntukStrip,
                        filterTahun: _filterTahun,
                        filterBulan: _filterBulan,
                        filterTanggal: _filterTanggal,
                        onTahun: _setTahun,
                        onBulan: _setBulan,
                        onTanggal: _setTanggal,
                      ),
                      Divider(
                        height: 18,
                        thickness: 1,
                        color: cs.outline.withValues(alpha: 0.09),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _ringkasanFilterTanggal(),
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      Divider(
                        height: 18,
                        thickness: 1,
                        color: cs.outline.withValues(alpha: 0.08),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Pintasan',
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _FilterChip(
                            label: 'Semua',
                            icon: Icons.calendar_view_month_outlined,
                            selected: _filterTahun == null &&
                                _filterBulan == null &&
                                _filterTanggal == null,
                            onSelected: (v) {
                              if (!v) return;
                              setState(_resetSemuaFilter);
                            },
                          ),
                          _FilterChip(
                            label: 'Hari ini',
                            icon: Icons.today_rounded,
                            selected: _isHariIni(),
                            onSelected: (v) {
                              if (!v) return;
                              final n = DateTime.now();
                              setState(() {
                                _filterTahun = n.year;
                                _filterBulan = n.month;
                                _filterTanggal = n.day;
                              });
                            },
                          ),
                          _FilterChip(
                            label: 'Bulan ini',
                            icon: Icons.date_range_rounded,
                            selected: _isBulanIni(),
                            onSelected: (v) {
                              if (!v) return;
                              final n = DateTime.now();
                              setState(() {
                                _filterTahun = n.year;
                                _filterBulan = n.month;
                                _filterTanggal = null;
                              });
                            },
                          ),
                          _FilterChip(
                            label: 'Tahun ini',
                            icon: Icons.calendar_today_rounded,
                            selected: _isTahunIni(),
                            onSelected: (v) {
                              if (!v) return;
                              final n = DateTime.now();
                              setState(() {
                                _filterTahun = n.year;
                                _filterBulan = null;
                                _filterTanggal = null;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                          Text(
                            'Pilih tahun / bulan / tanggal dari dropdown di atas.',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: cs.outline),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Card(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final viewportW = constraints.maxWidth;
                        const minTableW = 960.0;
                        final tableW = viewportW < minTableW
                            ? minTableW
                            : viewportW;
                        if (totalRecords == 0) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.inbox_rounded,
                                      color: cs.onSurfaceVariant),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Belum ada data absensi.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Coba kembali ke dashboard dan isi absen terlebih dahulu.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: cs.onSurfaceVariant),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        if (filtered.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.filter_alt_off_rounded,
                                      color: cs.onSurfaceVariant),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Tidak ada data yang sesuai dengan filter tanggal ini.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Coba tekan Reset Filter atau pilih range tanggal yang berbeda.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: cs.onSurfaceVariant),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  FilledButton.tonalIcon(
                                    onPressed: () =>
                                        setState(_resetSemuaFilter),
                                    icon: const Icon(Icons.restart_alt_rounded,
                                        size: 18),
                                    label: const Text('Reset Filter'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: tableW,
                            child: SingleChildScrollView(
                              child: PaginatedDataTable(
                                headingRowHeight: 40,
                                dataRowMinHeight: 36,
                                dataRowMaxHeight: 44,
                                horizontalMargin: 12,
                                columnSpacing: 16,
                                header: Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Menampilkan ${filtered.length} data sesuai filter',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: cs.onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                ),
                                rowsPerPage: rowsPerPage,
                                showFirstLastButtons: true,
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
                                source: _LaporanDataSource(filtered),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
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

const _bulanSingkat = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

/// Filter tahun / bulan / tanggal terpisah (logika sama seperti dropdown), UI strip digital + scroll.
/// (Saat ini UI sudah diganti ke dropdown biasa, jadi kelas ini tidak dipakai.)
// ignore: unused_element
class _DigitalDateFilters extends StatelessWidget {
  const _DigitalDateFilters({
    required this.tahunList,
    required this.filterTahun,
    required this.filterBulan,
    required this.filterTanggal,
    required this.onTahun,
    required this.onBulan,
    required this.onTanggal,
  });

  final List<int> tahunList;
  final int? filterTahun;
  final int? filterBulan;
  final int? filterTanggal;
  final ValueChanged<int?> onTahun;
  final ValueChanged<int?> onBulan;
  final ValueChanged<int?> onTanggal;

  @override
  Widget build(BuildContext context) {
    final tahunItems = <int?>[null, ...tahunList];
    final bulanItems = <int?>[null, ...List.generate(12, (i) => i + 1)];
    final tanggalItems = <int?>[null, ...List.generate(31, (i) => i + 1)];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101014),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.brandRed.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandRed.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DigitalStripLabel('TAHUN — geser horizontal'),
          const SizedBox(height: 6),
          _DigitalScrollStrip(
            items: tahunItems,
            labelBuilder: (v) => v == null ? 'Semua' : '$v',
            isSelected: (v) =>
                v == null ? filterTahun == null : filterTahun == v,
            onSelected: onTahun,
          ),
          const SizedBox(height: 12),
          _DigitalStripLabel('BULAN'),
          const SizedBox(height: 6),
          _DigitalScrollStrip(
            items: bulanItems,
            labelBuilder: (v) =>
                v == null ? 'Semua' : _bulanSingkat[v - 1],
            isSelected: (v) =>
                v == null ? filterBulan == null : filterBulan == v,
            onSelected: onBulan,
          ),
          const SizedBox(height: 12),
          _DigitalStripLabel('TANGGAL'),
          const SizedBox(height: 6),
          _DigitalScrollStrip(
            items: tanggalItems,
            labelBuilder: (v) => v == null ? 'Semua' : '$v',
            isSelected: (v) =>
                v == null ? filterTanggal == null : filterTanggal == v,
            onSelected: onTanggal,
          ),
        ],
      ),
    );
  }
}

/// Filter tanggal versi "biasa": dropdown Tahun / Bulan / Tanggal.
class _PlainDateFilters extends StatelessWidget {
  const _PlainDateFilters({
    required this.tahunList,
    required this.filterTahun,
    required this.filterBulan,
    required this.filterTanggal,
    required this.onTahun,
    required this.onBulan,
    required this.onTanggal,
  });

  final List<int> tahunList;
  final int? filterTahun;
  final int? filterBulan;
  final int? filterTanggal;
  final ValueChanged<int?> onTahun;
  final ValueChanged<int?> onBulan;
  final ValueChanged<int?> onTanggal;

  int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tahunItems = <int?>[null, ...tahunList];
    final bulanItems = <int?>[
      null,
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12,
    ];

    final dayCount = (filterTahun != null && filterBulan != null)
        ? _daysInMonth(filterTahun!, filterBulan!)
        : 31;
    final tanggalItems = <int?>[null, ...List.generate(dayCount, (i) => i + 1)];

    // Jangan nested `Card` (sudah ada Card utama untuk panel filter).
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withValues(alpha: 0.55)),
        color: cs.surface.withValues(alpha: 0.65),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: filterTahun,
                  items: tahunItems
                      .map(
                        (v) => DropdownMenuItem<int?>(
                          value: v,
                          child: Text(v == null ? 'Semua' : '$v'),
                        ),
                      )
                      .toList(),
                  onChanged: onTahun,
                  dropdownColor: cs.surface,
                  borderRadius: BorderRadius.circular(12),
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: 'Tahun',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: cs.surfaceVariant.withValues(alpha: 0.55),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: cs.outline.withValues(alpha: 0.18),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: cs.outline.withValues(alpha: 0.18),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: cs.primary,
                        width: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: filterBulan,
                  items: bulanItems
                      .map(
                        (v) => DropdownMenuItem<int?>(
                          value: v,
                          child: Text(
                            v == null ? 'Semua' : _bulanSingkat[v - 1],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: onBulan,
                  dropdownColor: cs.surface,
                  borderRadius: BorderRadius.circular(12),
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: 'Bulan',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: cs.surfaceVariant.withValues(alpha: 0.55),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: cs.outline.withValues(alpha: 0.18),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: cs.outline.withValues(alpha: 0.18),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: cs.primary,
                        width: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int?>(
            value: filterTanggal,
            items: tanggalItems
                .map(
                  (v) => DropdownMenuItem<int?>(
                    value: v,
                    child: Text(v == null ? 'Semua' : '$v'),
                  ),
                )
                .toList(),
            onChanged: onTanggal,
            dropdownColor: cs.surface,
            borderRadius: BorderRadius.circular(12),
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              isDense: true,
              labelText: 'Tanggal',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              filled: true,
              fillColor: cs.surfaceVariant.withValues(alpha: 0.55),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: cs.outline.withValues(alpha: 0.18),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: cs.outline.withValues(alpha: 0.18),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: cs.primary,
                  width: 1.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DigitalStripLabel extends StatelessWidget {
  const _DigitalStripLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w800,
        color: AppTheme.brandRed.withValues(alpha: 0.95),
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _DigitalScrollStrip extends StatelessWidget {
  const _DigitalScrollStrip({
    required this.items,
    required this.labelBuilder,
    required this.isSelected,
    required this.onSelected,
  });

  final List<int?> items;
  final String Function(int?) labelBuilder;
  final bool Function(int?) isSelected;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 2),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final item = items[i];
          final sel = isSelected(item);
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelected(item),
              borderRadius: BorderRadius.circular(9),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: sel
                      ? AppTheme.brandRed
                      : const Color(0xFF1C1C24),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: sel
                        ? AppTheme.brandRed
                        : Colors.white.withValues(alpha: 0.08),
                    width: sel ? 1.2 : 1,
                  ),
                  boxShadow: sel
                      ? [
                          BoxShadow(
                            color: AppTheme.brandRed.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  labelBuilder(item),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                    letterSpacing: 0.3,
                    color: sel ? Colors.white : const Color(0xFFE8E8EC),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LaporanDataSource extends DataTableSource {
  _LaporanDataSource(this.records);

  final List<AttendanceRecord> records;

  @override
  DataRow? getRow(int index) {
    if (index < 0 || index >= records.length) return null;
    final r = records[index];
    final tanggalStr =
        '${r.tanggal.day.toString().padLeft(2, '0')}-${r.tanggal.month.toString().padLeft(2, '0')}-${r.tanggal.year}';
    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text('${index + 1}')),
        DataCell(Text(r.nama)),
        DataCell(Text(r.email)),
        DataCell(Text(r.statusKepegawaian.toUpperCase())),
        DataCell(Text(r.posisi)),
        DataCell(Text(tanggalStr)),
        DataCell(Text(r.jamMasuk.isNotEmpty ? r.jamMasuk : '-')),
        DataCell(Text(r.jamPulang.isNotEmpty ? r.jamPulang : '-')),
        DataCell(Text(r.totalJamKerja ?? '-')),
        DataCell(Text(r.potongan != null ? '${r.potongan}%' : '0%')),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => records.length;

  @override
  int get selectedRowCount => 0;
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FilterChip(
      avatar: Icon(
        icon,
        size: 16,
        color: selected ? cs.onSecondaryContainer : cs.onSurfaceVariant,
      ),
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      selectedColor: cs.secondaryContainer,
      onSelected: onSelected,
    );
  }
}
