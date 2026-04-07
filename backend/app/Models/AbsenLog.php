<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AbsenLog extends Model
{
    protected $fillable = [
        'user_id','nama','email','tanggal',
        'jam_masuk','jam_pulang',
        'status_kepegawaian','posisi'
    ];
}
