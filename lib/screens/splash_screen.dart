import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import 'welcome_screen.dart';
import '../services/auth_service.dart';
// Note: Jika kamu menggunakan modul/halaman Home, pastikan untuk mengimportnya di sini
// import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth(); // Menjalankan fungsi pengecekan saat splash screen muncul
  }

  Future<void> _checkAuth() async {
    // 1. Menahan splash screen selama 3 detik agar user bisa melihat logo
    await Future.delayed(const Duration(seconds: 3));

    // 2. Mengambil data token dari SharedPreferences
    final token = await AuthService.getAccessToken();

    // 3. Jika context sudah tidak valid (user keburu menutup app), batalkan navigasi biar tidak crash
    if (!mounted) return;

    // 4. Logika routing berdasarkan ada/tidaknya token
    if (token != null && token.isNotEmpty) {
      // Jika token ADA, arahkan ke Home menggunakan rute nama (atau sesuaikan dengan navigasi projekmu)
      Navigator.pushReplacementNamed(context, '/home');

      // ATAU jika kamu tidak pakai named route, bisa pakai baris di bawah ini:
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
    } else {
      // Jika token TIDAK ADA, arahkan ke Welcome Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Background putih sesuai request
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Menampilkan logo Growink Hijau kamu
            Image.asset(
              'assets/images/logo-Growink-hijau.png',
              width: 150,
              height: 150,
            ),

            const SizedBox(height: 24),

            // Loading indicator warna hijau agar kontras dengan background putih
            const CircularProgressIndicator(color: Colors.green),
          ],
        ),
      ),
    );
  }
}
