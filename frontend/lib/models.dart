import 'package:flutter/material.dart';

enum UserLevel { admin, pegawai }

class UserAccount {
  const UserAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.emailVerifiedAt,
    this.rememberToken,
    this.createdAt,
    this.updatedAt,
    this.profil,
  });

  final int id;
  final String name;
  final String email;
  final String password;
  final String role;
  final DateTime? emailVerifiedAt;
  final String? rememberToken;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final UserProfil? profil;
}

class UserProfil {
  const UserProfil({
    required this.id,
    required this.userId,
    required this.nama,
    required this.statusKepegawaian,
    required this.satuanKerja,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int userId;
  final String nama;
  final String statusKepegawaian;
  final String satuanKerja;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

class AttendanceRecord {
  AttendanceRecord({
    required this.id,
    required this.userId,
    required this.nama,
    required this.email,
    required this.tanggal,
    required this.jamMasuk,
    required this.jamPulang,
    required this.statusKepegawaian,
    required this.posisi,
    this.potongan,
    this.totalJamKerja,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int userId;
  final String nama;
  final String email;
  final DateTime tanggal;
  final String jamMasuk;
  final String jamPulang;
  final String statusKepegawaian;
  final String posisi;
  final num? potongan;
  final String? totalJamKerja;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      nama: json['nama'] ?? '',
      email: json['email'] ?? '',
      tanggal: DateTime.parse(json['tanggal']),
      jamMasuk: json['jam_masuk'] ?? '',
      jamPulang: json['jam_pulang'] ?? '',
      statusKepegawaian: json['status_kepegawaian'] ?? '',
      posisi: json['posisi'] ?? '',
      potongan: json['potongan'] as num?,
      totalJamKerja: json['total_jam_kerja']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }
}

class AttendanceStore {
  static final List<AttendanceRecord> records = <AttendanceRecord>[];
}

String formatDateTime(DateTime dateTime) {
  final day = dateTime.day.toString().padLeft(2, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  final year = dateTime.year.toString();
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final second = dateTime.second.toString().padLeft(2, '0');
  return '$day-$month-$year $hour:$minute:$second';
}
