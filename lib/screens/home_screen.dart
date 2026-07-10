// ignore_for_file: use_build_context_synchronously
import 'package:badges/badges.dart' as badges; // Package badges
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'scan_screen.dart';
import 'plant_detail_screen.dart';
import 'growpedia_home_screen.dart';
import 'profile_screen.dart';
import 'notification_log_screen.dart';
import '../widgets/custom_snackbar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<dynamic> _myPlants = [];
  bool _isLoading = true;

  // Mendefinisikan URL dasar penyimpanan aset gambar di backend CodeIgniter 4
  final String _baseUrlUploads = "http://192.168.1.16:8080/uploads/";

  @override
  void initState() {
    super.initState();
    _fetchMyPlants();
  }

  Future<void> _fetchMyPlants() async {
    setState(() => _isLoading = true);

    try {
      // Ambil ID User untuk diteruskan ke API
      String? userId = await AuthService.getUserId();
      if (userId != null) {
        // Menggunakan fetchMyPlants yang sudah membutuhkan parameter userId
        final plants = await ApiService.fetchMyPlants(userId);
        if (mounted) {
          setState(() {
            _myPlants = plants;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        CustomSnackBar.show(context, 'Gagal memuat data: $e', isError: true);
      }
    }
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ScanScreen()),
      ).then((_) => _fetchMyPlants());
    } else if (index == 2) {
      // GANTI: Arahkan ke halaman Profil, bukan langsung Logout
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      ).then((_) => _fetchMyPlants()); // Refresh home saat kembali dari profil
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryEmerald = Color(0xFF059669);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Kebun Saya",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // TOMBOL LONCENG NOTIFIKASI DITAMBAHKAN DI SINI
          FutureBuilder<SharedPreferences>(
            future: SharedPreferences.getInstance(),
            builder: (context, snapshot) {
              int unreadCount = 0;
              if (snapshot.hasData) {
                // Ambil daftar log dari SharedPreferences
                List<String> logs =
                    snapshot.data!.getStringList('notif_logs') ?? [];
                // Hitung berapa yang isRead == false
                unreadCount = logs
                    .where((log) => jsonDecode(log)['isRead'] == false)
                    .length;
              }

              return IconButton(
                icon: badges.Badge(
                  showBadge:
                      unreadCount > 0, // Hanya tampil jika ada notif baru
                  badgeContent: Text(
                    unreadCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  child: const Icon(Icons.notifications),
                ),
                onPressed: () {
                  // Arahkan ke halaman riwayat/log notifikasi
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationLogScreen(),
                    ),
                  ).then((_) {
                    // Refresh tampilan setelah kembali (supaya badge merah menghilang jika sudah dibaca)
                    setState(() {});
                  });
                },
              );
            },
          ),
          // Tombol Refresh asli tetap dipertahankan
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchMyPlants,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildGrowpediaCard(),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _myPlants.isEmpty
                ? _buildEmptyState()
                : _buildPlantGrid(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner_rounded, size: 30),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: primaryEmerald,
        unselectedItemColor: Colors.blueGrey[200],
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.eco_outlined, size: 80, color: Colors.blueGrey[100]),
            const SizedBox(height: 16),
            const Text(
              "Belum ada tanaman di kebunmu",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Pindai QR Code stiker fisik untuk mendaftarkan pot tanaman baru Anda",
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _onItemTapped(1),
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
              label: const Text(
                "SCAN LABEL SEKARANG",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowpediaCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),

      child: InkWell(
        borderRadius: BorderRadius.circular(18),

        onTap: () {
          Navigator.push(
            context,

            MaterialPageRoute(builder: (_) => const GrowpediaHomeScreen()),
          );
        },

        child: Container(
          padding: const EdgeInsets.all(20),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),

            gradient: const LinearGradient(
              colors: [Color(0xff16A34A), Color(0xff22C55E)],
            ),
          ),

          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),

                decoration: BoxDecoration(
                  color: Colors.white24,

                  borderRadius: BorderRadius.circular(14),
                ),

                child: const Icon(
                  Icons.menu_book,

                  color: Colors.white,

                  size: 34,
                ),
              ),

              const SizedBox(width: 20),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      "Growpedia",

                      style: TextStyle(
                        color: Colors.white,

                        fontSize: 22,

                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 6),

                    Text(
                      "Pelajari ratusan tanaman lengkap beserta cara perawatannya.",

                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.arrow_forward_ios, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlantGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.78,
      ),
      itemCount: _myPlants.length,
      itemBuilder: (context, index) {
        final plant = _myPlants[index];
        final name = plant['custom_name'] ?? plant['plant_name'] ?? 'Tanaman';
        final scientific = plant['scientific_name'] ?? '';
        final imageName =
            plant['image'] ??
            plant['master_image'] ??
            ''; // fallback ke master_image jika ada

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.blueGrey.withValues(
                  alpha: 0.06,
                ), // Diubah ke withOpacity agar lebih kompatibel dengan Flutter versi lama/baru
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // KUNCI PERBAIKAN: Langsung oper data 'plant' tanpa perlu memanggil API loading
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlantDetailScreen(
                        plantData: plant,
                      ), // Lempar langsung
                    ),
                  ).then(
                    (_) => _fetchMyPlants(),
                  ); // Refresh data saat user kembali (misal setelah mengedit sesuatu)
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Container(
                        color: const Color(0xFFF1F5F9),
                        child: imageName.isNotEmpty
                            ? Image.network(
                                "$_baseUrlUploads$imageName",
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Color(0xFF059669),
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      );
                                    },
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildFallbackIcon(),
                              )
                            : _buildFallbackIcon(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            scientific.isNotEmpty
                                ? scientific
                                : 'Tidak ada nama ilmiah',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blueGrey[300],
                              fontStyle: scientific.isNotEmpty
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallbackIcon() {
    return Center(
      child: Icon(
        Icons.local_florist_rounded,
        size: 45,
        color: Colors.blueGrey[200],
      ),
    );
  }
}
