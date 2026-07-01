// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/custom_snackbar.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  const LoginScreen({super.key, this.onLoginSuccess});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo-Growink-hijau.png', height: 120),
              const SizedBox(height: 20),
              const Text(
                "Selamat Datang Kembali",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Text(
                "Masuk untuk akses fitur botani",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),

              // Input Modern
              _buildTextField(
                _idController,
                "Username atau Email",
                Icons.person_outline,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                _passController,
                "Password",
                Icons.lock_outline,
                obscure: true,
              ),

              const SizedBox(height: 30),

              // Button Modern
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _doLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "MASUK",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: const Text(
                  "Belum punya akun? Daftar di sini",
                  style: TextStyle(color: Colors.green),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void _doLogin() async {
    setState(() => _isLoading = true);
    final result = await AuthService().login(
      _idController.text,
      _passController.text,
    );
    setState(() => _isLoading = false);

    if (result['success']) {
      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!(); // Jalankan callback aksi tertunda
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      CustomSnackBar.show(context, result['message'], isError: true);
    }
  }
}
