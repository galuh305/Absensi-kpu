<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

use App\Models\AbsenLog;

class LaporanController extends Controller
{
    public function laporan()
    {
        $data = AbsenLog::all();
        $hasil = [];

        foreach($data as $d){
            $potongan = 0;
            $jam_masuk = $d->jam_masuk;
            $jam_pulang = $d->jam_pulang;

            $pulang_minimal = '16:00:00';

            // aturan masuk
            if($jam_masuk){
                if($jam_masuk < '07:30:00'){
                    $pulang_minimal = '16:00:00';
                } elseif($jam_masuk <= '08:29:59'){
                    $telat = strtotime($jam_masuk) - strtotime('07:30:00');
                    $pulang_minimal = date('H:i:s', strtotime('16:00:00') + $telat);
                } else {
                    $potongan += 2.5;
                }
            } else {
                $potongan += 2.5;
            }

            // aturan pulang
            if(!$jam_pulang || $jam_pulang < $pulang_minimal){
                $potongan += 2.5;
            }

            // total jam kerja
            if($jam_masuk && $jam_pulang){
                $selisih = strtotime($jam_pulang) - strtotime($jam_masuk);
                $total_jam = round($selisih / 3600,2);
            } else {
                $total_jam = '-';
            }

            $hasil[] = [
                'id'=>$d->id,
                'user_id'=>$d->user_id,
                'nama'=>$d->nama,
                'email'=>$d->email,
                'status_kepegawaian'=>$d->status_kepegawaian,
                'posisi'=>$d->posisi,
                'tanggal'=>$d->tanggal,
                'jam_masuk'=>$jam_masuk,
                'jam_pulang'=>$jam_pulang,
                'potongan'=>$potongan,
                'total_jam_kerja'=>$total_jam
            ];
        }

        return response()->json($hasil);
    }
}