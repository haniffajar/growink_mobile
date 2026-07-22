// ignore_for_file: duplicate_ignore, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
      builder: (BuildContext modalContext) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    String? userId = await AuthService.getUserId();
                    if (userId == null) return;

                    showDialog(
                      context: modalContext,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(color: Colors.green),
                      ),
                    );

                    final invoiceUrl = await ApiService.createInvoice(userId);

                    if (modalContext.mounted) Navigator.pop(modalContext);

                    if (invoiceUrl != null) {
                      if (modalContext.mounted) Navigator.pop(modalContext);

                      final Uri url = Uri.parse(invoiceUrl);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.inAppBrowserView);

                        if (context.mounted) {
                          _checkPaymentStatus(context, userId);
                        }
                      } else {
                        if (context.mounted) {
                          CustomSnackBar.show(
                            context,
                            'Tidak dapat membuka halaman pembayaran',
                            isError: true,
                          );
                        }
                      }
                    } else {
                      if (context.mounted) {
                        CustomSnackBar.show(
                          context,
                          'Gagal membuat tagihan pembayaran.',
                          isError: true,
                        );
                      }
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
              TextButton(
                onPressed: () => Navigator.pop(modalContext),
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

  static Future<void> _checkPaymentStatus(
    BuildContext context,
    String userId,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: const [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(width: 20),
            Expanded(child: Text("Mengecek pembayaran...")),
          ],
        ),
      ),
    );

    final result = await ApiService.checkUserPremium(userId);
    bool isPremium = result['isPremium'];
    String message = result['message'];

    if (context.mounted) Navigator.pop(context);

    if (context.mounted) {
      if (isPremium) {
        await AuthService.setPremiumStatus(true);
        _showSuccessDialog(context);
      } else {
        CustomSnackBar.show(context, message, isError: true);
        await Future.delayed(const Duration(seconds: 1));
        if (context.mounted) {
          _showPendingDialog(context, userId);
        }
      }
    }
  }

  static void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars_rounded, size: 80, color: Colors.amber),
              const SizedBox(height: 16),
              const Text(
                "Selamat!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Akun Anda kini resmi Premium. Nikmati semua fitur eksklusif Growink!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    Navigator.pushReplacementNamed(
                      context,
                      '/home',
                    ); // Sesuaikan rute Anda
                  },
                  child: const Text(
                    "Mulai Jelajahi",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showPendingDialog(BuildContext context, String userId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Pembayaran Belum Terdeteksi"),
        content: const Text(
          "Kami belum menerima konfirmasi pembayaran Anda. Jika Anda sudah membayar, proses ini mungkin memakan waktu 1-2 menit.\n\nKlik 'Cek Ulang' untuk menyegarkan status.",
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              "Nanti Saja",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(dialogContext);
              _checkPaymentStatus(context, userId);
            },
            child: const Text(
              "Cek Ulang Status",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
