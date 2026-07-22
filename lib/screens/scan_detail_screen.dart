// lib/screens/growpedia_detail_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'claim_plant_screen.dart';
import '../widgets/custom_snackbar.dart';

class ScanDetailScreen extends StatefulWidget {
  final Map<String, dynamic> plantMasterData;
  final String qrCode;
  final bool isClaimed;

  const ScanDetailScreen({
    super.key,
    required this.plantMasterData,
    this.qrCode = '',
    this.isClaimed = true,
  });

  @override
  State<ScanDetailScreen> createState() => _ScanDetailScreenState();
}

class _ScanDetailScreenState extends State<ScanDetailScreen> {
  final String _baseUrlUploads = "https://growink.app/backend/uploads/";

  void _onClaimButtonPressed() async {
    String? userId = await AuthService.getUserId();

    if (userId == null) {
      CustomSnackBar.show(
        context,
        'Silakan login terlebih dahulu untuk klaim tanaman.',
        isError: true,
      );

      await Navigator.pushNamed(context, '/login');
      userId = await AuthService.getUserId();
    }

    if (userId != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ClaimPlantScreen(plantData: {'qr_code': widget.qrCode}),
        ),
      );
    }
  }

  // LOGIKA BARU: Parsing Array of Objects (Map) menjadi String yang digabungkan
  List<String> _parsePests(dynamic pestsData) {
    if (pestsData == null) return [];

    List<dynamic> rawList = [];

    // Jika datang dalam bentuk JSON string, decode dulu
    if (pestsData is String) {
      try {
        final decoded = jsonDecode(pestsData);
        if (decoded is List) {
          rawList = decoded;
        }
      } catch (e) {
        debugPrint("Error parsing pests JSON: $e");
        return [];
      }
    } else if (pestsData is List) {
      // Jika sudah berupa List
      rawList = pestsData;
    }

    List<String> formattedPests = [];

    for (var item in rawList) {
      if (item is Map) {
        // Ambil value dari key 'name' dan 'effect'
        String name = item['name']?.toString() ?? 'Hama';
        String effect = item['effect']?.toString() ?? '';

        // Gabungkan menjadi satu kalimat: "Nama - Efek"
        if (effect.isNotEmpty) {
          formattedPests.add("$name – $effect");
        } else {
          formattedPests.add(name);
        }
      } else if (item is String) {
        // Fallback jika kebetulan ada item yang cuma string biasa
        formattedPests.add(item.toString());
      }
    }

    return formattedPests;
  }

  @override
  Widget build(BuildContext context) {
    String imageUrl = widget.plantMasterData['image'] != null
        ? "$_baseUrlUploads${widget.plantMasterData['image']}"
        : "";

    // Ambil data hama yang sudah di-parsing
    List<String> commonPests = _parsePests(
      widget.plantMasterData['common_pests'],
    );

    // Cek ketersediaan verif_code
    String verifCodeStr =
        widget.plantMasterData['verif_code']?.toString() ?? '';
    bool hasVerifCode =
        verifCodeStr.isNotEmpty && verifCodeStr.toLowerCase() != 'null';

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            backgroundColor: const Color(0xFF059669),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.plantMasterData['plant_name'] ?? 'Detail Tanaman',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 10)],
                ),
              ),
              background: imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover)
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.local_florist,
                        size: 80,
                        color: Colors.grey,
                      ),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.plantMasterData['latin_name'] ??
                        'Nama Latin Tidak Diketahui',
                    style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.plantMasterData['category'] ?? 'Tanpa Kategori',
                      style: const TextStyle(
                        color: Color(0xFF059669),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Deskripsi",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.plantMasterData['description'] ??
                        'Belum ada deskripsi untuk tanaman ini.',
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                  const Divider(height: 30, thickness: 1),
                  const Text(
                    "Panduan Perawatan",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildCareItem(
                    Icons.wb_sunny_rounded,
                    "Kebutuhan Cahaya",
                    widget.plantMasterData['light_requirement'],
                  ),
                  _buildCareItem(
                    Icons.water_drop_rounded,
                    "Penyiraman",
                    widget.plantMasterData['watering'],
                  ),
                  _buildCareItem(
                    Icons.grass_rounded,
                    "Media Tanam",
                    widget.plantMasterData['growing_media'],
                  ),
                  _buildCareItem(
                    Icons.eco_rounded,
                    "Pemupukan",
                    widget.plantMasterData['fertilizing'],
                  ),

                  // UI BARU: Daftar hama diubah menjadi list ke bawah (Column) bukan Wrap/Chip
                  if (commonPests.isNotEmpty) ...[
                    const Divider(height: 30, thickness: 1),
                    const Text(
                      "Waspada Hama",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(hasVerifCode),
    );
  }

  Widget _buildBottomNavigationBar(bool hasVerifCode) {
    if (widget.qrCode.isEmpty) return const SizedBox.shrink();

    if (!widget.isClaimed && hasVerifCode) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, -4),
              blurRadius: 10,
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _onClaimButtonPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF059669),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            "Klaim Tanaman Ini",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    } else if (!widget.isClaimed && !hasVerifCode) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.grey[100],
        child: const Text(
          "Tanaman ini tidak tersedia untuk diklaim.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
        ),
      );
    } else if (widget.isClaimed) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.red[50],
        child: const Text(
          "Tanaman ini sudah terdaftar oleh pengguna lain.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildCareItem(IconData icon, String title, String? description) {
    if (description == null || description.isEmpty) {
      return const SizedBox.shrink();
    }
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
}
