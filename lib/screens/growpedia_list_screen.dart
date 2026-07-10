// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';

import '../models/plant_model.dart';
import '../services/growpedia_service.dart';
import '../services/api_service.dart';
import 'growpedia_detail_screen.dart';
import '../widgets/custom_snackbar.dart';

class GrowpediaListScreen extends StatelessWidget {
  final String category;

  const GrowpediaListScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Plant>>(
        future: GrowpediaService.getPlantsByCategory(category),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Belum ada tanaman"));
          }

          final plants = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: plants.length,
            itemBuilder: (context, index) {
              final plant = plants[index];

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),

                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: plant.image != null && plant.image!.isNotEmpty
                          ? Image.network(
                              '${ApiService.baseUrl.replaceAll('/api', '')}/uploads/${plant.image}',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.eco,
                                  color: Colors.green,
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.eco, color: Colors.green),
                            ),
                    ),
                  ),

                  title: Text(
                    plant.plantName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        plant.scientificName,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),

                      const SizedBox(height: 5),

                      Row(
                        children: [
                          const Icon(
                            Icons.category,
                            size: 14,
                            color: Colors.green,
                          ),

                          const SizedBox(width: 4),

                          Text(category),
                        ],
                      ),
                    ],
                  ),

                  trailing: const Icon(Icons.arrow_forward_ios),

                  onTap: () async {
                    try {
                      final detail = await GrowpediaService.getPlantDetail(
                        int.parse(plant.id),
                      );

                      if (!context.mounted) return;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GrowpediaDetailScreen(
                            plantMasterData: detail,
                            qrCode: '',
                            isClaimed: false,
                          ),
                        ),
                      );
                    } catch (e) {
                      CustomSnackBar.show(context, e.toString(), isError: true);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
