// ignore_for_file: duplicate_ignore, use_build_context_synchronously

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_snackbar.dart';

class PremiumPaywall {
  static void show(BuildContext context, String message) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon atau Logo (Bisa menggunakan logo hijau Growink Anda)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  size: 64,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                "Upgrade ke Growink Premium",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Pesan yang dikirim dari Backend
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // List Keuntungan Premium
              _buildFeatureRow(
                Icons.eco_rounded,
                "Koleksi Tanaman Tanpa Batas",
              ),
              const SizedBox(height: 12),
              _buildFeatureRow(
                Icons.medical_services_rounded,
                "Akses Penuh AI Plant Doctor",
              ),
              const SizedBox(height: 12),
              _buildFeatureRow(
                Icons.menu_book_rounded,
                "Growpedia Eksklusif & Tips Lanjutan",
              ),
              const SizedBox(height: 32),

              // Tombol Langganan
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.green, // Sesuaikan dengan warna utama app Anda
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    // 1. Ambil ID User
                    String? userId = await AuthService.getUserId();
                    if (userId == null) return;

                    // 2. Tutup BottomSheet
                    Navigator.pop(context);

                    // 3. Panggil API (Bisa ditambahkan dialog loading disini jika perlu)
                    final result = await ApiService.upgradePremium(userId);

                    if (result['status'] == true) {
                      // Update status lokal
                      await AuthService.setPremiumStatus(true);

                      // Tampilkan pesan sukses
                      // ignore: use_build_context_synchronously
                      CustomSnackBar.show(
                        context,
                        result['message'],
                        isError: false,
                      );

                      // Opsional: Refresh halaman agar UI terganti
                      // ignore: use_build_context_synchronously
                      Navigator.pushReplacementNamed(context, '/home');
                    } else {
                      // ignore: use_build_context_synchronously
                      CustomSnackBar.show(
                        context,
                        result['message'],
                        isError: true,
                      );
                    }
                  },
                  child: const Text(
                    "Berlangganan - Rp 15.000 / Bulan",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tombol Nanti
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Mungkin Nanti",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.green, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
