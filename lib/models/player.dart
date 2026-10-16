class Player {
  final int id;
  final String name;

  Player({required this.id, required this.name});

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(id: map['id'] as int, name: map['name'] as String);
  }
}
