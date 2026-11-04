class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final String description;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    this.description = '',
  });

  factory CategoryModel.fromMap(String id, Map<String, dynamic> data) {
    return CategoryModel(
      id: id,
      name: (data['name'] as String?) ?? '',
      icon: (data['icon'] as String?) ?? 'category',
      description: (data['description'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'icon': icon,
        'description': description,
      };
}

