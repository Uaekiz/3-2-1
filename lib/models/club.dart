class Club {
  final int id;
  final String name;
  final String country;

  Club({required this.id, required this.name, required this.country});

  factory Club.fromMap(Map<String, dynamic> map) {
    return Club(
      id: map['id'] as int,
      name: map['name'] as String,
      country: (map['country'] ?? '') as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'country': country};
  }
}
