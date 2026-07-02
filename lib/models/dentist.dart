class Dentist {
  final String id;
  final String name;
  final bool isActive;

  Dentist({
    required this.id,
    required this.name,
    this.isActive = true,
  });

  Dentist copyWith({
    String? id,
    String? name,
    bool? isActive,
  }) {
    return Dentist(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
    );
  }

  factory Dentist.fromJson(Map<String, dynamic> json, String documentId) {
    return Dentist(
      id: documentId,
      name: json['name'] ?? '',
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'isActive': isActive,
    };
  }
}
