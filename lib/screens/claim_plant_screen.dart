// lib/screens/claim_plant_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/premium_paywall.dart';
import '../widgets/premium_bonus_dialog.dart';

class ClaimPlantScreen extends StatefulWidget {
  final Map<String, dynamic> plantData;
  const ClaimPlantScreen({super.key, required this.plantData});

  @override
  State<ClaimPlantScreen> createState() => _ClaimPlantScreenState();
}

class _ClaimPlantScreenState extends State<ClaimPlantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _verifCtrl = TextEditingController();
  bool _isLoading = false;

  void _submitClaim() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Ambil ID User yang sedang login
      String? userId = await AuthService.getUserId();

      if (userId == null) {
        CustomSnackBar.show(
          context,
          "Sesi Anda telah habis. Silakan login kembali.",
          isError: true,
        );
        setState(() => _isLoading = false);
        return;
      }

      // 2. Kirim data claim ke API (Sekarang mengembalikan Map)
      final result = await ApiService.claimPlant(
        widget.plantData['qr_code'] ?? '',
        _verifCtrl.text.trim(),
        userId,
      );

      if (mounted) {
        if (result['status'] == true) {
          // Cek apakah user mendapatkan bonus premium
          bool isBonus = result['is_premium_bonus'] == true;

          if (isBonus) {
            // Panggil dialog perayaan
            await AuthService.setPremiumStatus(true);
            PremiumBonusDialog.show(
              context,
              result['message'] ??
                  "Anda mendapatkan akses Premium selama 1 bulan!",
              () {
                // Callback saat tombol ditekan
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                );
              },
            );
          } else {
            // Tampilkan SnackBar Biasa
            CustomSnackBar.show(
              context,
              result['message'] ??
                  "Berhasil! Tanaman telah masuk ke Dashboard Anda.",
              isError: false,
            );
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
            );
          }
        } else {
          // GAGAL
          if (result['is_limit_reached'] == true) {
            // TAMPILKAN PAYWALL JIKA LIMIT TERCAPAI
            PremiumPaywall.show(context, result['message']);
          } else {
            // ERROR BIASA (Misal: Kode salah, QR sudah diklaim)
            CustomSnackBar.show(context, result['message'], isError: true);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          e.toString().replaceAll('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _verifCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Aktivasi Tanaman',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ilustrasi / Ikon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security,
                    size: 80,
                    color: Color(0xFF059669),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Masukkan Kode Verifikasi',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Temukan 6 digit kode verifikasi di dalam kemasan tanaman Anda dari toko.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 32),

              // Input Kode Verifikasi
              TextFormField(
                controller: _verifCtrl,
                decoration: _inputDecoration(
                  "Kode Verifikasi",
                  Icons.vpn_key_rounded,
                  "Contoh: AB12CD",
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Kode verifikasi tidak boleh kosong";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 40),

              // Tombol Submit
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF059669),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _submitClaim,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Aktifkan Tanaman',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // Desain Form Input
  InputDecoration _inputDecoration(String label, IconData icon, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black26, fontSize: 13),
      prefixIcon: Icon(icon, color: Colors.blueGrey[300], size: 20),
      floatingLabelStyle: const TextStyle(
        color: Color(0xFF059669),
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
    );
  }
}
