import 'dart:convert';

class GameMessage {
  final String type;
  final Map<String, dynamic> data;

  GameMessage({required this.type, required this.data});

  factory GameMessage.fromJson(String jsonStr) {
    final Map<String, dynamic> map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return GameMessage(
      type: map['type'] as String,
      data: map['data'] as Map<String, dynamic>? ?? {},
    );
  }

  String toJson() {
    return jsonEncode({
      'type': type,
      'data': data,
    });
  }

  @override
  String toString() => 'GameMessage(type: $type, data: $data)';
}

// Player model
class Player {
  final String id;
  final String name;
  int budget;
  List<String> wonFootballers;

  Player({
    required this.id,
    required this.name,
    required this.budget,
    List<String>? wonFootballers,
  }) : wonFootballers = wonFootballers ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'budget': budget,
      'wonFootballers': wonFootballers,
    };
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'] as String,
      name: map['name'] as String,
      budget: map['budget'] as int,
      wonFootballers: List<String>.from(map['wonFootballers'] as List? ?? []),
    );
  }
}
