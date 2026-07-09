class CategoryModel {
  final String name;

  final int total;

  CategoryModel({required this.name, required this.total});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      name: json['category'] ?? '',

      total: int.parse(json['total'].toString()),
    );
  }
}
