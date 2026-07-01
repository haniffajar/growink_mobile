import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/custom_snackbar.dart';
import 'plant_detail_screen.dart';

class ClaimPlantScreen extends StatefulWidget {
  final Map<String, dynamic> plantData;
  const ClaimPlantScreen({super.key, required this.plantData});

  @override
  State<ClaimPlantScreen> createState() => _ClaimPlantScreenState();
}

class _ClaimPlantScreenState extends State<ClaimPlantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  bool _isLoading = false;

  void _submitClaim() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      bool success = await ApiService.claimPlant(
        widget.plantData['qr_code'],
        _nameCtrl.text.trim(),
        _locCtrl.text.trim(),
      );

      if (success && mounted) {
        final updatedData = await ApiService.getPlantDetail(
          widget.plantData['qr_code'],
        );

        if (mounted) {
          CustomSnackBar.show(
            context,
            "Tanaman berhasil didaftarkan ke ekosistem Anda!",
            isError: false,
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PlantDetailScreen(plantData: updatedData),
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          CustomSnackBar.show(
            context,
            "Gagal melakukan klaim registrasi tanaman.",
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        CustomSnackBar.show(
          context,
          "Koneksi terputus. Gagal menghubungi server Growink.",
          isError: true,
        );
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryEmerald = Color(0xFF059669);
    final String qrCode = widget.plantData['qr_code'] ?? 'GRW-UNKNOWN';
    final String defaultPlantName =
        widget.plantData['plant_name'] ?? 'Spesies Botani';

    return Scaffold(
      backgroundColor: const Color(
        0xFFF8FAFC,
      ), // Background abu-abu soft bersih
      appBar: AppBar(
        title: const Text(
          "Klaim Tanaman Baru",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Badge QR Code & Teks Sambutan
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF065F46), primaryEmerald],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: primaryEmerald.withValues(alpha: 0.2),
                        spreadRadius: 1,
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.qr_code_2_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            qrCode,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Identifikasi: $defaultPlantName",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Tag fisik ini terdeteksi kosong. Isi data kustomisasi di bawah ini untuk mengadopsi tanaman ke dalam kebun digital Anda.",
                        style: TextStyle(
                          color: Color(0xFFD1FAE5),
                          fontSize: 11,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                const Text(
                  "Konfigurasi Identitas Pot",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),

                // INPUT 1: NAMA UNIK KUSTOM
                _buildCardTextField(
                  controller: _nameCtrl,
                  label: "Nama Unik Panggilan",
                  hint: "Contoh: Monsteraku Cantik",
                  icon: Icons.label_important_outline_rounded,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? "Mohon berikan nama panggilan tanaman"
                      : null,
                ),
                const SizedBox(height: 16),

                // INPUT 2: LOKASI PENEMPATAN
                _buildCardTextField(
                  controller: _locCtrl,
                  label: "Lokasi Penempatan Pot",
                  hint: "Contoh: Balkon Lantai 2 / Ruang Tamu",
                  icon: Icons.place_outlined,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? "Mohon tentukan lokasi penempatan"
                      : null,
                ),
                const SizedBox(height: 36),

                // TOMBOL SUBMIT MEWAH
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitClaim,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryEmerald,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: primaryEmerald.withValues(
                        alpha: 0.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                      shadowColor: primaryEmerald.withValues(alpha: 0.3),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            "SIMPAN KE KEBUN SAYA",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget Helper untuk pembuatan TextField dengan bayangan halus
  Widget _buildCardTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withValues(alpha: 0.06),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF334155),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Colors.blueGrey,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black26, fontSize: 13),
          prefixIcon: Icon(icon, color: Colors.blueGrey[300], size: 20),
          floatingLabelStyle: const TextStyle(
            color: Color(0xFF059669),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          errorStyle: const TextStyle(fontSize: 11, height: 0.8),
        ),
      ),
    );
  }
}
