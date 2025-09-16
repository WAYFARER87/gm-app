class Category {
  final String id;
  final String name;
  final String mIcon;

  Category({required this.id, required this.name, required this.mIcon});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      mIcon: json['m_icon']?.toString() ?? '',
    );
  }
}
