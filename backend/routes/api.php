<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

use App\Http\Controllers\AuthController;
use App\Http\Controllers\AbsenController;
use App\Http\Controllers\LaporanController;

Route::post('/register',[AuthController::class,'register']);
Route::post('/login',[AuthController::class,'login']);

Route::middleware('auth:sanctum')->group(function(){

    Route::post('/absen-masuk',[AbsenController::class,'absenMasuk']);
    Route::post('/absen-pulang',[AbsenController::class,'absenPulang']);

    Route::get('/laporan',[LaporanController::class,'laporan']);
});