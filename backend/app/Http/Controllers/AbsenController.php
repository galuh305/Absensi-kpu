<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\AbsenLog;
use Carbon\Carbon;
use Illuminate\Support\Facades\Auth;

class AbsenController extends Controller
{
    public function absenMasuk(Request $req)
    {
        $user = Auth::user();
        $now = Carbon::now();

        if ($now->format('H:i:s') < '07:30:00' || $now->format('H:i:s') > '08:29:59') {
            return response()->json(['message'=>'Diluar jam absen masuk'],400);
        }

        $cek = AbsenLog::where('user_id',$user->id)
            ->whereDate('tanggal',$now->toDateString())
            ->first();

        if($cek){
            return response()->json(['message'=>'Sudah absen masuk'],400);
        }

        AbsenLog::create([
            'user_id'=>$user->id,
            'nama'=>$user->name,
            'email'=>$user->email,
            'tanggal'=>$now->toDateString(),
            'jam_masuk'=>$now->format('H:i:s'),
            'status_kepegawaian'=>$req->status_kepegawaian,
            'posisi'=>$req->posisi
        ]);

        return response()->json(['message'=>'Absen masuk berhasil']);
    }

    public function absenPulang(Request $req)
    {
       $user = Auth::user();
        $now = Carbon::now();

        AbsenLog::create([
            'user_id'=>$user->id,
            'nama'=>$user->name,
            'email'=>$user->email,
            'tanggal'=>$now->toDateString(),
            'jam_pulang'=>$now->format('H:i:s'),
            'status_kepegawaian'=>$req->status_kepegawaian,
            'posisi'=> $req->posisi
        ]);

        return response()->json(['message'=>'Absen pulang berhasil']);
    }
}
