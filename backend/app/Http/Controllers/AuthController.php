<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    public function register(Request $req)
    {
        $user = User::create([
            'name' => $req->name,
            'email' => $req->email,
            'password' => Hash::make($req->password),
            'role' => 'pegawai' // default
        ]);

        return response()->json($user);
    }

    public function login(Request $req)
    {
        $user = User::where('email',$req->email)->first();

        if(!$user || !Hash::check($req->password,$user->password)){
            return response()->json(['message'=>'Login gagal'],401);
        }

        $token = $user->createToken('token')->plainTextToken;

        return response()->json([
            'token'=>$token,
            'user'=>$user
        ]);
    }
}
