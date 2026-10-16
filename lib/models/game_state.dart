import 'club.dart';

enum GamePhase {
  lobby, // Oyuncular bekleniyor / ayarlar
  teamSelection, // Takım seçme / kilitlenme fazı
  countdown321, // Ekranda 3-2-1 geri sayımı
  answering, // Takımlar yansıdı, süre akıyor
  buzzerActive, // Biri bastı, konuşma süresi akıyor
  roundEnded, // Sarı kart veya doğru cevap sonrası bekleme
  gameOver, // Biri hedef puana ulaştı
}

class PlayerState {
  final String id;
  final String name;
  int score;
  int yellowCards; // 0, 1 (2 olunca kırmızıya döner)
  Club? selectedClub;
  bool isLocked;

  PlayerState({
    required this.id,
    required this.name,
    this.score = 0,
    this.yellowCards = 0,
    this.selectedClub,
    this.isLocked = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'score': score,
    'yellowCards': yellowCards,
    'selectedClub': selectedClub?.toMap(),
    'isLocked': isLocked,
  };

  factory PlayerState.fromMap(Map<String, dynamic> map) => PlayerState(
    id: map['id'],
    name: map['name'],
    score: map['score'] ?? 0,
    yellowCards: map['yellowCards'] ?? 0,
    selectedClub: map['selectedClub'] != null
        ? Club.fromMap(map['selectedClub'])
        : null,
    isLocked: map['isLocked'] ?? false,
  );
}

class GameState {
  String roomCode;
  int targetScore;
  int roundTime; // 0 ise sınırsız
  int buzzerTime; // Konuşma süresi (sn)
  bool isRandomMode;

  GamePhase phase;
  List<PlayerState> players;
  Club? clubA;
  Club? clubB;
  String? buzzerPlayerId;
  int remainingRoundTime;
  int remainingBuzzerTime;

  // Maçta daha önce seçilmiş takımların ID listesi (Sarı kart kontrolü için)
  Set<int> usedClubIds;

  GameState({
    required this.roomCode,
    this.targetScore = 5,
    this.roundTime = 30,
    this.buzzerTime = 5,
    this.isRandomMode = false,
    this.phase = GamePhase.lobby,
    List<PlayerState>? players,
    this.clubA,
    this.clubB,
    this.buzzerPlayerId,
    this.remainingRoundTime = 30,
    this.remainingBuzzerTime = 5,
    Set<int>? usedClubIds,
  }) : players = players ?? [],
       usedClubIds = usedClubIds ?? {};

  Map<String, dynamic> toMap() => {
    'roomCode': roomCode,
    'targetScore': targetScore,
    'roundTime': roundTime,
    'buzzerTime': buzzerTime,
    'isRandomMode': isRandomMode,
    'phase': phase.index,
    'players': players.map((p) => p.toMap()).toList(),
    'clubA': clubA?.toMap(),
    'clubB': clubB?.toMap(),
    'buzzerPlayerId': buzzerPlayerId,
    'remainingRoundTime': remainingRoundTime,
    'remainingBuzzerTime': remainingBuzzerTime,
    'usedClubIds': usedClubIds.toList(),
  };

  factory GameState.fromMap(Map<String, dynamic> map) => GameState(
    roomCode: map['roomCode'],
    targetScore: map['targetScore'],
    roundTime: map['roundTime'],
    buzzerTime: map['buzzerTime'],
    isRandomMode: map['isRandomMode'],
    phase: GamePhase.values[map['phase'] ?? 0],
    players: (map['players'] as List? ?? [])
        .map((e) => PlayerState.fromMap(e))
        .toList(),
    clubA: map['clubA'] != null ? Club.fromMap(map['clubA']) : null,
    clubB: map['clubB'] != null ? Club.fromMap(map['clubB']) : null,
    buzzerPlayerId: map['buzzerPlayerId'],
    remainingRoundTime: map['remainingRoundTime'] ?? 30,
    remainingBuzzerTime: map['remainingBuzzerTime'] ?? 5,
    usedClubIds: Set<int>.from(map['usedClubIds'] ?? []),
  );
}
