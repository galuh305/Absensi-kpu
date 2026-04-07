<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Profil extends Model
{
    protected $fillable = [
        'user_id','nama','status_kepegawaian','satuan_kerja'
    ];
}
