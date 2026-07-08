// lib/screens/plant_detail_screen.dart
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
  final String? displayImage;

  const PlantDetailScreen({
    super.key,
    required this.plantData,
    this.displayImage,
  });

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

  // Controller untuk tab Edit
  final _editNameCtrl = TextEditingController();
  final _editLocationCtrl = TextEditingController();
  File? _tempUpdatedImage;
  bool _isSavingProfile = false;

  final String _serverUrl = 'http://192.168.1.16:8080/uploads/';

  @override
  void initState() {
    super.initState();
    _editNameCtrl.text = widget.plantData['custom_name'] ?? '';
    _editLocationCtrl.text = widget.plantData['location'] ?? '';
    _checkLoginAndFetchData();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _editNameCtrl.dispose();
    _editLocationCtrl.dispose();
    super.dispose();
  }

  // LOGIKA: Parsing JSON Hama
  List<String> _parsePests(dynamic pestsData) {
    if (pestsData == null) return [];
    List<dynamic> rawList = [];

    if (pestsData is String) {
      try {
        final decoded = jsonDecode(pestsData);
        if (decoded is List) rawList = decoded;
      } catch (e) {
        return [];
      }
    } else if (pestsData is List) {
      rawList = pestsData;
    }

    List<String> formattedPests = [];
    for (var item in rawList) {
      if (item is Map) {
        String name = item['name']?.toString() ?? 'Hama';
        String effect = item['effect']?.toString() ?? '';
        if (effect.isNotEmpty) {
          formattedPests.add("$name – $effect");
        } else {
          formattedPests.add(name);
        }
      } else if (item is String) {
        formattedPests.add(item.toString());
      }
    }
    return formattedPests;
  }

  Future<void> _checkLoginAndFetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final dynamic rawUid = prefs.get('uid');
    final String? currentUserId = rawUid?.toString();

    final dynamic rawPlantUserId = widget.plantData['user_id'];
    final String? plantOwnerId = rawPlantUserId?.toString();

    if (rawPlantUserId == null) _isUnclaimed = true;

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
    if (mounted)
      setState(() {
        _activityHistory = history;
        _isLoadingHistory = false;
      });
  }

  Future<void> _loadAiRecommendations() async {
    if (!mounted) return;
    setState(() => _isLoadingRecommendations = true);
    final recs = await ApiService.getAiRecommendations(
      widget.plantData['id'].toString(),
    );
    if (mounted)
      setState(() {
        _aiRecommendations = recs;
        _isLoadingRecommendations = false;
      });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() => _tempUpdatedImage = File(pickedFile.path));
    }
  }

  Future<void> _saveProfile() async {
    if (_editNameCtrl.text.isEmpty) {
      CustomSnackBar.show(
        context,
        "Nama kustom tidak boleh kosong",
        isError: true,
      );
      return;
    }

    setState(() => _isSavingProfile = true);
    try {
      String? newImagePath = await ApiService.updatePlantProfile(
        widget.plantData['id'].toString(),
        _editNameCtrl.text,
        _editLocationCtrl.text,
        _tempUpdatedImage,
      );

      if (mounted) {
        setState(() {
          widget.plantData['custom_name'] = _editNameCtrl.text;
          widget.plantData['location'] = _editLocationCtrl.text;
          if (newImagePath != null) widget.plantData['image'] = newImagePath;
        });
        CustomSnackBar.show(
          context,
          "Profil tanaman berhasil disimpan!",
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) CustomSnackBar.show(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  void _handleAction(
    BuildContext context,
    String action,
    String plantId, {
    String notes = '',
  }) async {
    // ... (Logika handler action sama seperti sebelumnya)
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
      CustomSnackBar.show(context, "Terjadi kesalahan.", isError: true);
    }
  }

  // ============ BOTTOM SHEET AI DIHILANGKAN DARI SINI UNTUK KERINGKASAN (Gunakan kode AI sebelumnya) ============
  void _showAiAssistantBottomSheet(
    BuildContext context,
    String plantName,
    String plantId,
  ) {
    // ... [Isi dengan fungsi AI Modal persis dari kode Anda sebelumnya] ...
  }

  @override
  Widget build(BuildContext context) {
    final plant = Plant.fromJson(widget.plantData);
    final displayName = plant.customName ?? plant.plantName;
    final plantData = widget.plantData;

    // 1. Logika Gambar Prioritas
    String imageUrlToUse = '';

    // Ambil nilai dari map plantData agar lebih aman dari perbedaan key model
    final userImage = plantData['user_image']?.toString();
    final masterImage = plantData['master_image']?.toString();

    if (widget.displayImage != null && widget.displayImage!.isNotEmpty) {
      // Prioritas 1: Gambar hasil upload/crop sementara di aplikasi
      imageUrlToUse = '$_serverUrl${widget.displayImage}';
    } else if (userImage != null &&
        userImage.isNotEmpty &&
        userImage.toLowerCase() != 'null') {
      // Prioritas 2: Gambar kustom dari user (dari kolom user_image)
      imageUrlToUse = '$_serverUrl$userImage';
    } else if (masterImage != null &&
        masterImage.isNotEmpty &&
        masterImage.toLowerCase() != 'null') {
      // Prioritas 3: Fallback ke master plant jika di user_plants kosong
      imageUrlToUse = '$_serverUrl$masterImage';
    }

    List<String> commonPests = _parsePests(widget.plantData['common_pests']);

    return DefaultTabController(
      length: 4, // 4 TAB
      child: Scaffold(
        backgroundColor: Colors.white,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 320.0,
                pinned: true,
                backgroundColor: const Color(0xFF059669),
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black87, blurRadius: 10)],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      _tempUpdatedImage != null
                          ? Image.file(_tempUpdatedImage!, fit: BoxFit.cover)
                          : imageUrlToUse.isNotEmpty
                          ? Image.network(imageUrlToUse, fit: BoxFit.cover)
                          : Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.local_florist,
                                size: 80,
                                color: Colors.grey,
                              ),
                            ),
                      // Gradient agar teks mudah dibaca
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.center,
                            colors: [Colors.black87, Colors.transparent],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(kTextTabBarHeight),
                  child: Container(
                    color: Colors.white,
                    child: const TabBar(
                      isScrollable: true,
                      labelColor: Color(0xFF059669),
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Color(0xFF059669),
                      indicatorWeight: 3,
                      tabs: [
                        Tab(text: "Informasi"),
                        Tab(text: "Aktivitas"),
                        Tab(text: "Rekomendasi"),
                        Tab(text: "Edit Profil"),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              _buildInformasiTab(plant, commonPests),
              _buildAktivitasTab(context, plant),
              _buildRekomendasiTab(plant),
              _buildEditTab(), // TAB BARU
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
      ),
    );
  }

  Widget _buildInformasiTab(Plant plant, List<String> commonPests) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          widget.plantData['latin_name'] ?? 'Nama Latin Tidak Diketahui',
          style: const TextStyle(
            fontSize: 16,
            fontStyle: FontStyle.italic,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 20),

        // Data Kepemilikan (Khusus user_plants)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow("Tanggal Ditanam", plant.plantedAt),
              const Divider(),
              _buildInfoRow("Lokasi Tanaman", plant.location ?? 'Belum diatur'),
            ],
          ),
        ),

        const SizedBox(height: 24),
        const Text(
          "Deskripsi",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          widget.plantData['description'] ??
              'Belum ada deskripsi untuk tanaman ini.',
          style: const TextStyle(
            fontSize: 15,
            height: 1.5,
            color: Colors.black87,
          ),
        ),

        const Divider(height: 30, thickness: 1),
        const Text(
          "Panduan Perawatan Umum",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildCareItem(
          Icons.wb_sunny_rounded,
          "Kebutuhan Cahaya",
          widget.plantData['light_requirement'],
        ),
        _buildCareItem(
          Icons.water_drop_rounded,
          "Penyiraman",
          widget.plantData['watering'],
        ),
        _buildCareItem(
          Icons.grass_rounded,
          "Media Tanam",
          widget.plantData['growing_media'],
        ),
        _buildCareItem(
          Icons.eco_rounded,
          "Pemupukan",
          widget.plantData['fertilizing'],
        ),

        // Segmen Hama (Bentuk List Column)
        if (commonPests.isNotEmpty) ...[
          const Divider(height: 30, thickness: 1),
          const Text(
            "Waspada Hama",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: commonPests.map((pestText) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "• ",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        pestText,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 80), // Padding bawah FAB
      ],
    );
  }

  // ============== TAB EDIT (BARU) ==============
  Widget _buildEditTab() {
    if (!_isOwner) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            "Hanya pemilik tanaman yang dapat mengubah profil ini.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          "Edit Profil Tanaman",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        // Pilih Gambar
        Center(
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 150,
              width: 150,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.green.shade300,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: _tempUpdatedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(_tempUpdatedImage!, fit: BoxFit.cover),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_rounded,
                          size: 40,
                          color: Colors.green,
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Pilih Foto",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Input Custom Name
        const Text(
          "Nama Panggilan Tanaman",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _editNameCtrl,
          decoration: InputDecoration(
            hintText: "Cth: Monstera Kesayangan",
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Input Lokasi
        const Text(
          "Lokasi Penempatan",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _editLocationCtrl,
          decoration: InputDecoration(
            hintText: "Cth: Teras Depan / Ruang Tamu",
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Tombol Simpan
        ElevatedButton(
          onPressed: _isSavingProfile ? null : _saveProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF059669),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isSavingProfile
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  "Simpan Perubahan",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  // ================= KOMPONEN HELPER =================
  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildCareItem(IconData icon, String title, String? description) {
    if (description == null || description.isEmpty)
      return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green[50],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF059669), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: Colors.black87, height: 1.4),
                ),
              ],
            ),
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
          if (_isOwner)
            Column(
              children: [
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _handleAction(
                          context,
                          'siram',
                          plant.id.toString(),
                        ),
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
                        onPressed: () => _handleAction(
                          context,
                          'pupuk',
                          plant.id.toString(),
                        ),
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
                        onPressed: () => _showActionDialog(
                          context,
                          'cek hama',
                          plant.id.toString(),
                        ),
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
                        onPressed: () => _showActionDialog(
                          context,
                          'repotting',
                          plant.id.toString(),
                        ),
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
          if (!_isOwner && _isLoggedIn)
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
}
