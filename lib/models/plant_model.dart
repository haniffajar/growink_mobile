class Plant {
  final String id;
  final String qrCode;
  final String? userId;
  final String plantName;
  final String scientificName;
  final String wateringInterval;
  final String sunlight;
  final String humidity;
  final String plantedAt;
  final String? customName; // Bisa null
  final String? location; // Bisa null
  final String? image;

  Plant({
    required this.id,
    required this.qrCode,
    this.userId,
    required this.plantName,
    required this.scientificName,
    required this.wateringInterval,
    required this.sunlight,
    required this.humidity,
    required this.plantedAt,
    this.customName,
    this.location,
    this.image,
  });

  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      id: json['id']?.toString() ?? '',
      qrCode: json['qr_code'] ?? '',
      userId: json['user_id']?.toString(),

      plantName: json['plant_name'] ?? 'Tanaman',

      scientificName: json['scientific_name'] ?? json['latin_name'] ?? '-',

      wateringInterval: json['watering_interval'] ?? json['watering'] ?? '-',

      sunlight: json['sunlight'] ?? json['light_requirement'] ?? '-',

      humidity: json['humidity'] ?? '-',

      plantedAt: json['planted_at'] ?? '',

      customName: json['custom_name'],

      location: json['location'],

      image: json['image']?.toString(),
    );
  }
}
