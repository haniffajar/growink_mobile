import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../widgets/premium_paywall.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = 'User';
  String _email = 'user@email.com';
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('name') ?? 'Pengguna Growink';
      _email = prefs.getString('email') ?? '';
    });

    bool premiumStatus = await AuthService.getPremiumStatus();
    setState(() {
      _isPremium = premiumStatus;
    });
  }

  void _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Profil Saya',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Bagian Foto Profil & Nama
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFF059669),
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              _name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              _email,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 24),

            // Kartu Status Premium / Free
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: _isPremium
                    ? const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      )
                    : const LinearGradient(
                        colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
                      ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    _isPremium ? Icons.workspace_premium : Icons.stars_rounded,
                    size: 48,
                    color: _isPremium ? Colors.white : Colors.grey[600],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isPremium ? 'Growink Premium' : 'Akun Gratis',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _isPremium ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isPremium
                        ? 'Semua fitur eksklusif & kuota tanaman tak terbatas telah terbuka.'
                        : 'Buka kuota tanaman tak terbatas dan fitur AI Plant Doctor.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: _isPremium ? Colors.white70 : Colors.black54,
                    ),
                  ),

                  // Tombol Upgrade jika belum Premium
                  if (!_isPremium) ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        PremiumPaywall.show(
                          context,
                          "Tingkatkan pengalaman merawat tanaman Anda dengan Premium.",
                        );
                      },
                      child: const Text(
                        'Upgrade Sekarang',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Tombol Logout
            ListTile(
              onTap: _logout,
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Keluar (Log Out)',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.black26),
            ),
          ],
        ),
      ),
    );
  }
}
