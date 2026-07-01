// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../models/plant_model.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'claim_plant_screen.dart';
import '../widgets/custom_snackbar.dart';

class PlantDetailScreen extends StatefulWidget {
  final Map<String, dynamic> plantData;
  const PlantDetailScreen({super.key, required this.plantData});

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  List<dynamic> _activityHistory = [];
  List<dynamic> _aiRecommendations = [];
  bool _isLoadingHistory = true;
  bool _isLoadingRecommendations = true;
  bool _isLoggedIn = false;
  bool _isOwner = false;
  bool _isUnclaimed = false;

  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkLoginAndFetchData();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkLoginAndFetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final dynamic rawUid = prefs.get('uid');
    final String? currentUserId = rawUid?.toString();

    final dynamic rawPlantUserId = widget.plantData['user_id'];
    final String? plantOwnerId = rawPlantUserId?.toString();

    if (rawPlantUserId == null) {
      _isUnclaimed = true;
    }

    if (token != null && token.isNotEmpty) {
      if (mounted) {
        setState(() {
          _isLoggedIn = true;
          if (currentUserId != null &&
              plantOwnerId != null &&
              currentUserId == plantOwnerId) {
            _isOwner = true;
          }
        });
      }
      _loadHistory();
      _loadAiRecommendations();
    } else {
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
          _isLoadingRecommendations = false;
        });
      }
    }
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;
    setState(() => _isLoadingHistory = true);
    final history = await ApiService.getPlantHistory(
      widget.plantData['id'].toString(),
    );
    if (mounted) {
      setState(() {
        _activityHistory = history;
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _loadAiRecommendations() async {
    if (!mounted) return;
    setState(() => _isLoadingRecommendations = true);
    final recs = await ApiService.getAiRecommendations(
      widget.plantData['id'].toString(),
    );
    if (mounted) {
      setState(() {
        _aiRecommendations = recs;
        _isLoadingRecommendations = false;
      });
    }
  }

  void _handleAction(
    BuildContext context,
    String action,
    String plantId, {
    String notes = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final token = prefs.getString('jwt_token');

    if (token == null || token.isEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(
            onLoginSuccess: () {
              Navigator.pop(context);
              _handleAction(context, action, plantId, notes: notes);
            },
          ),
        ),
      );
      return;
    }

    bool success = await ApiService.recordActivity(
      plantId,
      action,
      notes: notes,
    );

    if (success) {
      CustomSnackBar.show(
        context,
        "Aktivitas $action berhasil dicatat!",
        isError: false,
      );
      _notesCtrl.clear();
      _loadHistory();
    } else {
      if (mounted) {
        CustomSnackBar.show(
          context,
          "Terjadi kesalahan atau sesi habis.",
          isError: true,
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  void _showActionDialog(BuildContext context, String action, String plantId) {
    final TextEditingController notesCtrl = TextEditingController();
    final bool isBug = action == 'cek hama';
    final Color primaryColor = isBug
        ? Colors.redAccent
        : Colors.orange.shade600;
    final IconData iconDialog = isBug
        ? Icons.bug_report_rounded
        : Icons.eco_rounded;
    final String titleText = isBug ? "Catatan Cek Hama" : "Catatan Repotting";
    final String hintText = isBug
        ? "Misal: Ditemukan kutu putih pada bagian bawah daun..."
        : "Misal: Mengganti pot ke ukuran lebih besar...";

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 8,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconDialog, color: primaryColor, size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  titleText,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Tambahkan catatan kondisi tanaman saat ini untuk melengkapi riwayat perawatanmu.",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blueGrey.shade400,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: notesCtrl,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(
                      color: Colors.blueGrey.shade200,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: Colors.blueGrey.shade50.withValues(alpha: 0.5),
                    contentPadding: const EdgeInsets.all(16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.blueGrey.shade100),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: primaryColor, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: BorderSide(color: Colors.blueGrey.shade200),
                        ),
                        child: const Text(
                          "Batal",
                          style: TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _handleAction(
                            context,
                            action,
                            plantId,
                            notes: notesCtrl.text,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Simpan",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleClaimPlant() {
    if (!_isLoggedIn) {
      CustomSnackBar.show(
        context,
        "Silakan login dahulu untuk menambahkan tanaman ke akunmu.",
        isError: true,
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(
            onLoginSuccess: () {
              Navigator.pop(context);
              _checkLoginAndFetchData().then((_) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ClaimPlantScreen(plantData: widget.plantData),
                  ),
                );
              });
            },
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClaimPlantScreen(plantData: widget.plantData),
      ),
    );
  }

  // ==================== EXPERIENCE CHAT AI BARU (BOTTOM SHEET) ====================
  void _showAiAssistantBottomSheet(
    BuildContext context,
    String plantName,
    String plantId,
  ) {
    final TextEditingController promptCtrl = TextEditingController();
    final ScrollController scrollCtrl = ScrollController();
    File? selectedImage;
    String? base64Str;
    bool isAiLoading = false;

    List<Map<String, String>> chatMessages = [
      {
        'role': 'model',
        'text':
            "Halo! Saya Asisten AI Growink.\nSilakan tanyakan keluhan tentang $plantName, atau unggah foto daun/batangnya agar saya bisa menganalisis penyakitnya.",
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext aiContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickImg(ImageSource source) async {
              final pickedFile = await ImagePicker().pickImage(
                source: source,
                imageQuality: 70,
              );
              if (pickedFile != null) {
                final file = File(pickedFile.path);
                final bytes = await file.readAsBytes();
                setDialogState(() {
                  selectedImage = file;
                  base64Str = base64Encode(bytes);
                });
              }
            }

            void animateToBottom() {
              Future.delayed(const Duration(milliseconds: 100), () {
                if (scrollCtrl.hasClients) {
                  scrollCtrl.animateTo(
                    scrollCtrl.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              });
            }

            void checkAndSaveRecommendation(String aiText) async {
              if (!_isLoggedIn) return; // Pengaman backend token

              if (aiText.contains('[REKOMENDASI]') &&
                  aiText.contains('[/REKOMENDASI]')) {
                final start =
                    aiText.indexOf('[REKOMENDASI]') + '[REKOMENDASI]'.length;
                final end = aiText.indexOf('[/REKOMENDASI]');
                final rawData = aiText.substring(start, end).trim();

                try {
                  final parts = rawData.split('|');
                  final jenis = parts[0].replaceAll('Jenis:', '').trim();
                  final detail = parts[1].replaceAll('Detail:', '').trim();

                  bool isSaved = await ApiService.saveRecommendationToDb(
                    plantId: plantId,
                    jenis: jenis,
                    detail: detail,
                  );

                  if (isSaved) {
                    _loadAiRecommendations(); // Perbarui list rekomendasi di latar belakang
                  }
                } catch (e) {
                  debugPrint("Gagal memparsing format rekomendasi: $e");
                }
              }
            }

            Future<void> sendMessage() async {
              final userText = promptCtrl.text.trim();
              if (userText.isEmpty && base64Str == null) return;

              setDialogState(() {
                isAiLoading = true;
                String displayMessage = userText;
                if (base64Str != null) {
                  displayMessage = userText.isEmpty
                      ? "📷 [Mengirim Foto Tanaman]"
                      : "📷 [Foto Tanaman] $userText";
                }
                chatMessages.add({'role': 'user', 'text': displayMessage});
              });

              final currentBase64 = base64Str;
              promptCtrl.clear();
              setDialogState(() {
                selectedImage = null;
                base64Str = null;
              });
              animateToBottom();

              try {
                String responseResult = await ApiService.interactWithAi(
                  plantName: plantName,
                  prompt: userText,
                  history: chatMessages.sublist(0, chatMessages.length - 1),
                  imageBase64: currentBase64,
                );

                // KUNCI UTAMA: Cek apakah respons dari ApiService merupakan pesan eror sistem
                if (responseResult.startsWith('Error Server') ||
                    responseResult.startsWith('Gagal terhubung')) {
                  // Sengaja dilempar ke blok catch(e) di bawah agar menampilkan pesan ramah
                  throw Exception(responseResult);
                }

                checkAndSaveRecommendation(responseResult);

                final cleanText = responseResult
                    .replaceAll(
                      RegExp(
                        r'\[REKOMENDASI\](.*?)\[/REKOMENDASI\]',
                        dotAll: true,
                      ),
                      '',
                    )
                    .trim();

                setDialogState(() {
                  chatMessages.add({'role': 'model', 'text': cleanText});
                  isAiLoading = false;
                });
              } catch (e) {
                setDialogState(() {
                  chatMessages.add({
                    'role': 'model',
                    'text':
                        "Server Pakar AI sedang penuh antrean. Silakan coba kirim pesan beberapa saat lagi, ya! 🌿",
                  });
                  isAiLoading = false;
                });
              }
              animateToBottom();
            }

            return Container(
              // Menggunakan clipBehavior agar lekukan container atas tidak terpotong gelembung warna putih
              clipBehavior: Clip.antiAlias,
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Scaffold(
                backgroundColor: Colors.transparent,
                // KUNCI UTAMA: Izinkan Scaffold menyesuaikan tinggi saat keyboard (inset) aktif
                resizeToAvoidBottomInset: true,
                body: SafeArea(
                  child: Column(
                    children: [
                      // 1. HEADER
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade700,
                              Colors.green.shade500,
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Dokter Tanaman AI",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    "Spesialis $plantName",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade100,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(aiContext),
                            ),
                          ],
                        ),
                      ),

                      // 2. CHAT TIMELINE (Menggunakan Expanded agar fleksibel mengecil saat keyboard naik)
                      Expanded(
                        child: Container(
                          color: Colors.grey.shade50,
                          child: ListView.builder(
                            controller: scrollCtrl,
                            padding: const EdgeInsets.all(16),
                            itemCount: chatMessages.length,
                            itemBuilder: (context, index) {
                              final msg = chatMessages[index];
                              final isModel = msg['role'] == 'model';
                              return Align(
                                alignment: isModel
                                    ? Alignment.centerLeft
                                    : Alignment.centerRight,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isModel
                                        ? Colors.white
                                        : Colors.green.shade600,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft: Radius.circular(
                                        isModel ? 0 : 16,
                                      ),
                                      bottomRight: Radius.circular(
                                        isModel ? 16 : 0,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.02,
                                        ),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    msg['text'] ?? '',
                                    style: TextStyle(
                                      color: isModel
                                          ? Colors.black87
                                          : Colors.white,
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // 3. PREVIEW FOTO JIKA ADA
                      if (selectedImage != null)
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  selectedImage!,
                                  height: 50,
                                  width: 50,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                "Foto siap dianalisis...",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(
                                  Icons.cancel,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () => setDialogState(() {
                                  selectedImage = null;
                                  base64Str = null;
                                }),
                              ),
                            ],
                          ),
                        ),

                      if (isAiLoading)
                        LinearProgressIndicator(
                          color: Colors.green,
                          backgroundColor: Colors.green.shade100,
                        ),

                      // 4. BAR INPUT (Otomatis didorong ke atas karena resizeToAvoidBottomInset)
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.white,
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.blue,
                              ),
                              onPressed: () => pickImg(ImageSource.camera),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.photo_library_rounded,
                                color: Colors.orange,
                              ),
                              onPressed: () => pickImg(ImageSource.gallery),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: TextField(
                                controller: promptCtrl,
                                maxLines: 2,
                                minLines: 1,
                                style: const TextStyle(fontSize: 14),
                                decoration: InputDecoration(
                                  hintText:
                                      "Ketik keluhan atau analisis foto...",
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(
                                Icons.send_rounded,
                                color: Colors.green,
                              ),
                              onPressed: isAiLoading
                                  ? null
                                  : () => sendMessage(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final plant = Plant.fromJson(widget.plantData);
    final displayName = plant.customName ?? plant.plantName;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                plant.qrCode,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          bottom: const TabBar(
            labelColor: Colors.green,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.green,
            tabs: [
              Tab(text: "Informasi"),
              Tab(text: "Aktivitas"),
              Tab(text: "Rekomendasi"),
            ],
          ),
        ),
        floatingActionButton: _isLoggedIn
            ? FloatingActionButton.extended(
                onPressed: () => _showAiAssistantBottomSheet(
                  context,
                  plant.plantName,
                  plant.id.toString(),
                ),
                backgroundColor: Colors.green.shade700,
                icon: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                ),
                label: const Text(
                  "Tanya AI Pakar",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        body: TabBarView(
          children: [
            _buildInformasiTab(plant),
            _buildAktivitasTab(context, plant),
            _buildRekomendasiTab(plant),
          ],
        ),
      ),
    );
  }

  Widget _buildInformasiTab(Plant plant) {
    final String serverUrl =
        'https://mitrablud.com:8443/growink-backend/uploads/';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 250,
                height: 250,
                color: Colors.green.shade50,
                child: (plant.image != null && plant.image!.isNotEmpty)
                    ? Image.network(
                        '$serverUrl${plant.image}',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.broken_image,
                            size: 80,
                            color: Colors.grey,
                          );
                        },
                      )
                    : const Icon(
                        Icons.energy_savings_leaf,
                        size: 100,
                        color: Colors.green,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            "Informasi Utama",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          _buildInfoRow("Tanggal Tanam", plant.plantedAt),
          _buildInfoRow("Lokasi", plant.location ?? "Belum diatur"),
          _buildInfoRow("Nama Ilmiah", plant.scientificName),

          const SizedBox(height: 20),
          const Text(
            "Panduan Perawatan Umum",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          _buildActivityTile(
            Icons.water_drop,
            "Penyiraman",
            "Setiap ${plant.wateringInterval} hari",
            Colors.blue,
          ),
          _buildActivityTile(
            Icons.wb_sunny,
            "Kebutuhan Cahaya",
            plant.sunlight,
            Colors.orange,
          ),
          _buildActivityTile(
            Icons.air,
            "Tingkat Kelembapan",
            plant.humidity,
            Colors.teal,
          ),
        ],
      ),
    );
  }

  Widget _buildAktivitasTab(BuildContext context, Plant plant) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (_isUnclaimed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  const Icon(Icons.stars, color: Colors.green, size: 40),
                  const SizedBox(height: 10),
                  const Text(
                    "Tanaman ini belum memiliki pemilik!",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Tambahkan ke kebunmu untuk mulai merawatnya.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    onPressed: _handleClaimPlant,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text("Tambahkan ke Akun"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 45),
                    ),
                  ),
                ],
              ),
            ),
          if (_isOwner)
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _handleAction(context, 'siram', plant.id),
                        icon: const Icon(Icons.water_drop),
                        label: const Text("Siram"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _handleAction(context, 'pupuk', plant.id),
                        icon: const Icon(Icons.compost),
                        label: const Text("Pupuk"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _showActionDialog(context, 'cek hama', plant.id),
                        icon: const Icon(Icons.bug_report),
                        label: const Text("Cek Hama"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _showActionDialog(context, 'repotting', plant.id),
                        icon: const Icon(Icons.grass),
                        label: const Text("Repotting"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          if (!_isOwner && !_isUnclaimed && _isLoggedIn)
            Container(
              padding: const EdgeInsets.all(15),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Hanya pemilik tanaman yang dapat menambahkan aktivitas.",
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Riwayat Perawatan",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: !_isLoggedIn
                ? const Center(
                    child: Text(
                      "Silakan login untuk melihat riwayat aktivitas",
                    ),
                  )
                : _isLoadingHistory
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  )
                : _activityHistory.isEmpty
                ? const Center(child: Text("Belum ada aktivitas tercatat"))
                : ListView.builder(
                    itemCount: _activityHistory.length,
                    itemBuilder: (context, index) {
                      final item = _activityHistory[index];
                      final type =
                          item['activity_type']?.toString().toLowerCase() ?? '';
                      final note = item['notes']?.toString() ?? '';

                      IconData icon = Icons.eco;
                      Color color = Colors.green;
                      String titleText = "Dirawat";

                      if (type == 'siram') {
                        icon = Icons.water_drop;
                        color = Colors.blue;
                        titleText = "Disiram";
                      } else if (type == 'pupuk') {
                        icon = Icons.compost;
                        color = Colors.brown;
                        titleText = "Diberi Pupuk";
                      } else if (type == 'cek hama') {
                        icon = Icons.bug_report;
                        color = Colors.red;
                        titleText = "Diperiksa Hama";
                      } else if (type == 'repotting') {
                        icon = Icons.grass;
                        color = Colors.orange;
                        titleText = "Dilakukan Repotting";
                      }

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: color),
                        ),
                        title: Text(
                          titleText,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['done_at'] ?? '-'),
                            if (note.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '"$note"',
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRekomendasiTab(Plant plant) {
    if (!_isLoggedIn) {
      return const Center(
        child: Text("Silakan login untuk melihat rekomendasi pakar"),
      );
    }

    if (_isLoadingRecommendations) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.green),
      );
    }

    if (_aiRecommendations.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            "Belum ada rekomendasi pakar khusus untuk tanaman ini.\nSilakan gunakan fitur 'Tanya AI Pakar' jika ada kendala.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _aiRecommendations.length,
      itemBuilder: (context, index) {
        final item = _aiRecommendations[index];
        final String category =
            item['type']?.toString().toLowerCase() ?? 'umum';
        final String detail = item['detail'] ?? '';
        final String createdAt = item['created_at'] ?? '';

        IconData icon = Icons.tips_and_updates_rounded;
        Color color = Colors.green;

        if (category.contains('siram')) {
          icon = Icons.water_drop_rounded;
          color = Colors.blue;
        } else if (category.contains('pupuk')) {
          icon = Icons.compost_rounded;
          color = Colors.brown;
        } else if (category.contains('cahaya')) {
          icon = Icons.wb_sunny_rounded;
          color = Colors.orange;
        } else if (category.contains('kelembapan')) {
          icon = Icons.air_rounded;
          color = Colors.teal;
        } else if (category.contains('hama')) {
          icon = Icons.bug_report_rounded;
          color = Colors.redAccent;
        } else if (category.contains('repotting')) {
          icon = Icons.grass_rounded;
          color = Colors.deepOrange;
        } else if (category.contains('pemangkasan')) {
          icon = Icons.content_cut_rounded;
          color = Colors.purple;
        }

        return Card(
          color: Colors.white,
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade100),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            category.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: color,
                              fontSize: 12,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            createdAt.split(' ')[0],
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        detail,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTile(
    IconData icon,
    String title,
    String subtitle,
    Color iconColor,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
    );
  }
}
