import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/custom_snackbar.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _rePassCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureRePass = true;

  void _doRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await AuthService().register(
        _nameCtrl.text.trim(),
        _userCtrl.text.trim(),
        _emailCtrl.text.trim(),
        _passCtrl.text,
      );

      if (mounted) {
        CustomSnackBar.show(
          context,
          result['message'] ?? 'Proses registrasi selesai.',
          isError: !(result['success'] ?? false),
        );

        if (result['success'] == true) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Gagal terhubung dengan server Growink.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _userCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _rePassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryEmerald = Color(0xFF059669);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Pendaftaran Akun",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Hero(
                    tag: 'growink_logo',
                    child: Image.asset(
                      'assets/logo-Growink-hijau.png',
                      height: 50,
                      fit: BoxFit
                          .contain, // PERBAIKAN: Menggunakan enum BoxFit.contain
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.eco_rounded,
                        size: 50,
                        color: primaryEmerald,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Mulai Bergabung",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ), // PERBAIKAN: FontWeight.extrabold -> FontWeight.w800
                  ),
                  const Text(
                    "Kelola ekosistem botani pribadi Anda dengan mudah",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ), // PERBAIKAN: Colors.slate400 -> Colors.grey
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  _buildCardTextField(
                    controller: _nameCtrl,
                    label: "Nama Lengkap",
                    hint: "Masukkan nama lengkap Anda",
                    icon: Icons.person_outline_rounded,
                    validator: (v) => v == null || v.isEmpty
                        ? "Nama lengkap wajib diisi"
                        : null,
                  ),
                  const SizedBox(height: 16),

                  _buildCardTextField(
                    controller: _userCtrl,
                    label: "Username",
                    hint: "Contoh: officer_growink",
                    icon: Icons.alternate_email_rounded,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? "Username wajib diisi"
                        : null,
                  ),
                  const SizedBox(height: 16),

                  _buildCardTextField(
                    controller: _emailCtrl,
                    label: "Alamat Email",
                    hint: "Contoh: admin@growink.com",
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return "Alamat email wajib diisi";
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(v)) {
                        return "Format email tidak valid";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildCardTextField(
                    controller: _passCtrl,
                    label: "Kata Sandi",
                    hint: "Minimal 6 karakter",
                    icon: Icons.lock_open_rounded,
                    obscureText: _obscurePass,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                    validator: (v) => v == null || v.length < 6
                        ? "Kata sandi minimal 6 karakter"
                        : null,
                  ),
                  const SizedBox(height: 16),

                  _buildCardTextField(
                    controller: _rePassCtrl,
                    label: "Konfirmasi Kata Sandi",
                    hint: "Ulangi kata sandi Anda",
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscureRePass,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureRePass
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscureRePass = !_obscureRePass),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return "Konfirmasi kata sandi wajib diisi";
                      }
                      if (v != _passCtrl.text) {
                        return "Kata sandi konfirmasi tidak cocok";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 36),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _doRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryEmerald,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: primaryEmerald.withValues(
                          alpha: 0.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                        shadowColor: primaryEmerald.withValues(alpha: 0.3),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              "DAFTAR AKUN BARU",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withValues(
              alpha: 0.08,
            ), // PERBAIKAN: Colors.slate -> Colors.blueGrey
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF334155),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Colors.blueGrey,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ), // PERBAIKAN: Colors.slate -> Colors.blueGrey
          hintText: hint,
          hintStyle: const TextStyle(
            color: Colors.black26,
            fontSize: 13,
          ), // PERBAIKAN: Colors.slate[300] -> Colors.black26
          prefixIcon: Icon(
            icon,
            color: Colors.blueGrey[300],
            size: 20,
          ), // PERBAIKAN: Colors.slate[400] -> Colors.blueGrey[300]
          suffixIcon: suffixIcon,
          floatingLabelStyle: const TextStyle(
            color: Color(0xFF059669),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          errorStyle: const TextStyle(fontSize: 11, height: 0.8),
        ),
      ),
    );
  }
}
