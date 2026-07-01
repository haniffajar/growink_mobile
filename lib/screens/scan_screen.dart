// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';
import 'plant_detail_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  bool _isProcessing = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Scan Label Tanaman',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) async {
              if (_isProcessing) return;
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? code = barcodes.first.rawValue;
                if (code != null && code.startsWith('GWK-')) {
                  setState(() => _isProcessing = true);
                  try {
                    final data = await ApiService.getPlantDetail(code);
                    if (mounted) {
                      // HAPUS Pengecekan user_id, LANGSUNG lempar ke PlantDetailScreen
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PlantDetailScreen(plantData: data),
                        ),
                      );
                    }
                  } catch (e) {
                    setState(() => _isProcessing = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Gagal mengambil data tanaman'),
                        ),
                      );
                    }
                  }
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.greenAccent.withValues(alpha: 0.5),
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Align(
                    alignment: Alignment(
                      0,
                      -1.0 + (_animationController.value * 2.0),
                    ),
                    child: Container(
                      height: 4,
                      width: 260,
                      decoration: BoxDecoration(
                        color: Colors.greenAccent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.greenAccent.withValues(alpha: 0.8),
                            blurRadius: 15,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.greenAccent),
                    SizedBox(height: 20),
                    Text(
                      "Memproses data...",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
