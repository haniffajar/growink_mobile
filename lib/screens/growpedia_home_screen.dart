import 'package:flutter/material.dart';
import '../services/growpedia_service.dart'; // Sesuaikan path import Anda
import 'growpedia_list_screen.dart'; // Sesuaikan path import Anda

class GrowpediaHomeScreen extends StatefulWidget {
  const GrowpediaHomeScreen({super.key});

  @override
  State<GrowpediaHomeScreen> createState() => _GrowpediaHomeScreenState();
}

class _GrowpediaHomeScreenState extends State<GrowpediaHomeScreen> {
  late Future<List<String>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = GrowpediaService.getCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Growpedia'),
        backgroundColor: Colors.green, // Sesuaikan dengan tema aplikasi Anda
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<String>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada kategori ditemukan.'));
          }

          final categories = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 kolom
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.9,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return _buildCategoryCard(context, categories[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, String categoryName) {
    return Card(
      elevation: 3,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),

      child: InkWell(
        borderRadius: BorderRadius.circular(18),

        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GrowpediaListScreen(category: categoryName),
            ),
          );
        },

        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: Color(0xffE8F5E9),
                child: Icon(Icons.eco, color: Colors.green, size: 30),
              ),

              const SizedBox(height: 15),

              Text(
                categoryName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
