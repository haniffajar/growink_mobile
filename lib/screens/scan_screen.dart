// lib/screens/scan_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'plant_detail_screen.dart';
import 'scan_detail_screen.dart';
import '../widgets/custom_snackbar.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  bool _isProcessing = false;
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  late AnimationController _animationController;

  String? _lastScannedCode;
  DateTime? _lastScanTime;

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
    _scannerController.dispose();
    super.dispose();
  }

  // LOGIKA BARU: Proses deteksi QR
  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    if (capture.barcodes.isEmpty) return;

    final qrCode = capture.barcodes.first.rawValue;

    if (qrCode == null) return;

    // Cooldown 2 detik
    if (_lastScannedCode == qrCode &&
        _lastScanTime != null &&
        DateTime.now().difference(_lastScanTime!) <
            const Duration(seconds: 2)) {
      return;
    }

    _lastScannedCode = qrCode;
    _lastScanTime = DateTime.now();

    _isProcessing = true;

    setState(() {});

    // stop scanner
    await _scannerController.stop();

    await _processScannedQR(qrCode);
  }

  // LOGIKA BARU: Pemisahan arah navigasi berdasarkan API
  Future<void> _processScannedQR(String qrCode) async {
    try {
      // Ambil ID User secara dinamis
      String? currentUserId = await AuthService.getUserId();

      var response = await ApiService.scanQRCode(qrCode, currentUserId);

      if (response['type'] == 'owner_detail') {
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PlantDetailScreen(
              plantData: response['data'],
              // displayImage: response['display_image'] ?? '', // Jika menggunakan format displayImage dari BE
            ),
          ),
        );
        return;
      } else if (response['type'] == 'public_info') {
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ScanDetailScreen(
              plantMasterData: response['data'],
              qrCode: response['qr_code'] ?? qrCode,
              isClaimed: response['is_claimed'] ?? false,
            ),
          ),
        );
        return;
      }
    } catch (e) {
      if (!mounted) return;

      _isProcessing = false;

      setState(() {});

      await _scannerController.start();

      CustomSnackBar.show(
        context,
        e.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    }
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
          // SCANNER CAMERA
          MobileScanner(controller: _scannerController, onDetect: _onDetect),

          // UI LAMA: Animasi Kotak Border Hijau
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.greenAccent.withOpacity(
                    0.5,
                  ), // menggunakan withOpacity
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
                            color: Colors.greenAccent.withOpacity(0.8),
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

          // LOADING OVERLAY
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.7),
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
