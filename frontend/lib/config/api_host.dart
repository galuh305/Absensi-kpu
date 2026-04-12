/// **Konfigurasi alamat server backend (Laravel)**
///
/// Isi [kApiBaseUrl] dengan IP komputer Anda agar HP bisa terhubung
/// (HP dan PC harus satu jaringan Wi‑Fi).
///
/// 1. Di folder backend jalankan:
///    `php artisan serve --host=0.0.0.0 --port=8000`
///    (`--host=0.0.0.0` wajib supaya HP bisa mengakses, bukan hanya PC.)
/// 2. Di Windows cek IP Wi‑Fi: buka CMD → `ipconfig` → cari **IPv4 Address**
///    pada adapter Wi‑Fi (misalnya `192.168.1.50`).
/// 3. Ganti nilai di bawah menjadi `http://IP_ANDA:8000` (tanpa spasi di akhir).
///
/// Contoh lain:
/// - Hanya uji di **emulator Android** (server di PC yang sama): `http://10.0.2.2:8000`
/// - Hanya **browser di PC**: `http://127.0.0.1:8000`
const String kApiBaseUrl = 'http://10.57.207.163:8000';

/// Membangun URL endpoint API (path harus diawali `/`, mis. `/api/login`).
Uri apiUri(String path) {
  final p = path.startsWith('/') ? path : '/$path';
  return Uri.parse('$kApiBaseUrl$p');
}
