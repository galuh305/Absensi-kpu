import 'package:flutter/material.dart';
import 'package:frontend/models.dart';
import 'package:frontend/penghitung_absensi/dashboard_page.dart';
import 'package:frontend/login/register.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/config/api_host.dart';
import 'package:frontend/ui/app_feedback.dart';
import 'package:frontend/widgets/semi_transparent_image_background.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const String _rememberMeKey = 'remember_me';
  static const String _rememberedEmailKey = 'remembered_email';
  static const String _rememberedPasswordKey = 'remembered_password';

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;
  bool _rememberMe = false;

  bool _isLoading = false;
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userJson = prefs.getString('user');

    if (token != null && userJson != null) {
      final userData = jsonDecode(userJson);
      final user = UserAccount(
        id: userData['id'],
        name: userData['name'],
        email: userData['email'],
        password: '',
        role: userData['role'],
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => DashboardPage(account: user)),
      );
    } else {
      final remembered = prefs.getBool(_rememberMeKey) ?? false;
      if (remembered) {
        _emailController.text = prefs.getString(_rememberedEmailKey) ?? '';
        _passwordController.text = prefs.getString(_rememberedPasswordKey) ?? '';
      }
      if (mounted) {
        setState(() {
          _rememberMe = remembered;
          _isCheckingAuth = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    
    try {
      final response = await http.post(
        apiUri('/api/login'),
        headers: {'Accept': 'application/json'},
        body: {
          'email': email,
          'password': password,
        },
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final userData = data['user'];
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('user', jsonEncode(userData));
        if (_rememberMe) {
          await prefs.setBool(_rememberMeKey, true);
          await prefs.setString(_rememberedEmailKey, email);
          await prefs.setString(_rememberedPasswordKey, password);
        } else {
          await prefs.remove(_rememberMeKey);
          await prefs.remove(_rememberedEmailKey);
          await prefs.remove(_rememberedPasswordKey);
        }

        final user = UserAccount(
          id: userData['id'],
          name: userData['name'],
          email: userData['email'],
          password: '',
          role: userData['role'],
        );

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => DashboardPage(account: user)),
        );
      } else {
        if (!mounted) return;
        final email = _emailController.text.trim();
        final msg = extractApiMessage(response.body);

        // Prioritas: bedakan pakai status code (kalau backend mendukung)
        if (response.statusCode == 404) {
          AppFeedback.error(
            context,
            email.isEmpty
                ? 'Email belum terdaftar. Silakan daftar terlebih dahulu.'
                : 'Email "$email" belum terdaftar. Silakan daftar terlebih dahulu.',
          );
        } else if (response.statusCode == 401 || response.statusCode == 422) {
          // Umumnya backend memakai 401/422 untuk kredensial salah
          AppFeedback.error(context, 'Password salah.');
        } else {
          // Fallback: humanize dari message backend
          final pretty = humanizeLoginError(
            msg.isEmpty ? 'Password salah.' : msg,
            email: email,
          );
          AppFeedback.error(context, pretty);
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      AppFeedback.error(context, 'Koneksi ke server gagal. Coba lagi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: SemiTransparentImageBackground(
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SemiTransparentImageBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          height: 52,
                          width: 52,
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.how_to_reg_rounded,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Absen Pegawai',
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Silakan masukkan email dan password Anda',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.alternate_email_rounded),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email wajib diisi';
                            }
                            if (!RegExp(
                              r'^[^@]+@[^@]+\.[^@]+',
                            ).hasMatch(value)) {
                              return 'Format email tidak valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _hidePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_rounded),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _hidePassword = !_hidePassword;
                                });
                              },
                              icon: Icon(
                                _hidePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 6),
                        CheckboxListTile(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: const Text('Remember me'),
                        ),
                        const SizedBox(height: 16),
                        if (_isLoading)
                          const Center(child: CircularProgressIndicator())
                        else ...[
                          FilledButton(
                            onPressed: _handleLogin,
                            child: const Text('Masuk'),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const RegisterPage(),
                                ),
                              );
                            },
                            child: const Text('Daftar Akun Pegawai'),
                          ),
                        ],
                        const SizedBox(height: 4),

                      ],
                    ),
                  ),
                ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
