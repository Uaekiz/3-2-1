import 'dart:convert';

class GameEvent {
  final String type;
  final Map<String, dynamic> payload;

  GameEvent({required this.type, required this.payload});

  String toJson() => jsonEncode({'type': type, 'payload': payload});

  factory GameEvent.fromJson(String str) {
    final data = jsonDecode(str) as Map<String, dynamic>;
    return GameEvent(
      type: data['type'] as String,
      payload: (data['payload'] ?? {}) as Map<String, dynamic>,
    );
  }
}

// Olay Tipleri (Action Constants)
class EventTypes {
  static const String joinRoom = 'JOIN_ROOM';
  static const String updateSettings = 'UPDATE_SETTINGS';
  static const String lobbyUpdate = 'LOBBY_UPDATE';
  static const String startRound = 'START_ROUND';
  static const String selectTeam = 'SELECT_TEAM';
  static const String teamsLocked = 'TEAMS_LOCKED';
  static const String trigger321 = 'TRIGGER_321';
  static const String buzzerPressed = 'BUZZER_PRESSED';
  static const String buzzerWinner = 'BUZZER_WINNER';
  static const String answerResult = 'ANSWER_RESULT';
  static const String yellowCard = 'YELLOW_CARD';
  static const String nextRound = 'NEXT_ROUND';
  static const String gameOver = 'GAME_OVER';
}
