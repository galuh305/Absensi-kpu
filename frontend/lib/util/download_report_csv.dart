import 'download_report_csv_stub.dart'
    if (dart.library.html) 'download_report_csv_web.dart'
    if (dart.library.io) 'download_report_csv_io.dart'
    as impl;

/// Unduh / bagikan CSV: browser memicu download; mobile/desktop membuka sheet share.
Future<void> downloadReportCsv(List<int> bytes, String filename) =>
    impl.downloadReportCsv(bytes, filename);
