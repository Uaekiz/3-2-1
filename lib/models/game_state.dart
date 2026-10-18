import 'club.dart';

enum GamePhase {
  lobby,
  teamSelection,
  countdown321,
  answering,
  buzzerActive,
  roundEnded,
  gameOver,
}

enum GameFormat { clubVsClub, countryVsClub }

class PlayerState {
  final String id;
  final String name;
  int score;
  int yellowCards;
  bool isLocked;
  Club? selectedClub;
  String? selectedCountry;

  PlayerState({
    required this.id,
    required this.name,
    this.score = 0,
    this.yellowCards = 0,
    this.isLocked = false,
    this.selectedClub,
    this.selectedCountry,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'score': score,
    'yellowCards': yellowCards,
    'isLocked': isLocked,
    'selectedClub': selectedClub?.toMap(),
    'selectedCountry': selectedCountry,
  };

  factory PlayerState.fromMap(Map<String, dynamic> map) => PlayerState(
    id: map['id'] as String,
    name: map['name'] as String,
    score: map['score'] as int? ?? 0,
    yellowCards: map['yellowCards'] as int? ?? 0,
    isLocked: map['isLocked'] as bool? ?? false,
    selectedClub: map['selectedClub'] != null
        ? Club.fromMap(Map<String, dynamic>.from(map['selectedClub'] as Map))
        : null,
    selectedCountry: map['selectedCountry'] as String?,
  );

  Map<String, dynamic> toJson() => toMap();
  factory PlayerState.fromJson(Map<String, dynamic> json) =>
      PlayerState.fromMap(json);
}

class GameState {
  String roomCode;
  GamePhase phase;
  GameFormat format;
  int targetScore;
  bool keepCountryPickerOnFail;
  String? countryPickerPlayerId;
  String? activeCountry;
  Set<String> usedCountries;

  List<PlayerState> players;
  Club? clubA;
  Club? clubB;
  bool isRandomMode;
  int roundTime;
  int buzzerTime;
  int remainingRoundTime;
  int remainingBuzzerTime;
  String? buzzerPlayerId;
  Set<int> usedClubIds;

  GameState({
    required this.roomCode,
    this.phase = GamePhase.lobby,
    this.format = GameFormat.clubVsClub,
    this.targetScore = 5,
    this.keepCountryPickerOnFail = true,
    this.countryPickerPlayerId,
    this.activeCountry,
    Set<String>? usedCountries,
    List<PlayerState>? players,
    this.clubA,
    this.clubB,
    this.isRandomMode = false,
    this.roundTime = 60,
    this.buzzerTime = 7,
    this.remainingRoundTime = 60,
    this.remainingBuzzerTime = 7,
    this.buzzerPlayerId,
    Set<int>? usedClubIds,
  }) : usedCountries = usedCountries ?? {},
       players = players ?? [],
       usedClubIds = usedClubIds ?? {};

  Map<String, dynamic> toMap() => {
    'roomCode': roomCode,
    'phase': phase.name,
    'format': format.name,
    'targetScore': targetScore,
    'keepCountryPickerOnFail': keepCountryPickerOnFail,
    'countryPickerPlayerId': countryPickerPlayerId,
    'activeCountry': activeCountry,
    'usedCountries': usedCountries.toList(),
    'players': players.map((p) => p.toMap()).toList(),
    'clubA': clubA?.toMap(),
    'clubB': clubB?.toMap(),
    'isRandomMode': isRandomMode,
    'roundTime': roundTime,
    'buzzerTime': buzzerTime,
    'remainingRoundTime': remainingRoundTime,
    'remainingBuzzerTime': remainingBuzzerTime,
    'buzzerPlayerId': buzzerPlayerId,
    'usedClubIds': usedClubIds.toList(),
  };

  factory GameState.fromMap(Map<String, dynamic> map) => GameState(
    roomCode: map['roomCode'] as String,
    phase: GamePhase.values.byName(map['phase'] as String),
    format: map['format'] != null
        ? GameFormat.values.byName(map['format'] as String)
        : GameFormat.clubVsClub,
    targetScore: map['targetScore'] as int? ?? 5,
    keepCountryPickerOnFail: map['keepCountryPickerOnFail'] as bool? ?? true,
    countryPickerPlayerId: map['countryPickerPlayerId'] as String?,
    activeCountry: map['activeCountry'] as String?,
    usedCountries:
        (map['usedCountries'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toSet() ??
        {},
    players:
        (map['players'] as List<dynamic>?)
            ?.map(
              (p) => PlayerState.fromMap(Map<String, dynamic>.from(p as Map)),
            )
            .toList() ??
        [],
    clubA: map['clubA'] != null
        ? Club.fromMap(Map<String, dynamic>.from(map['clubA'] as Map))
        : null,
    clubB: map['clubB'] != null
        ? Club.fromMap(Map<String, dynamic>.from(map['clubB'] as Map))
        : null,
    isRandomMode: map['isRandomMode'] as bool? ?? false,
    roundTime: map['roundTime'] as int? ?? 60,
    buzzerTime: map['buzzerTime'] as int? ?? 7,
    remainingRoundTime: map['remainingRoundTime'] as int? ?? 60,
    remainingBuzzerTime: map['remainingBuzzerTime'] as int? ?? 7,
    buzzerPlayerId: map['buzzerPlayerId'] as String?,
    usedClubIds:
        (map['usedClubIds'] as List<dynamic>?)?.map((e) => e as int).toSet() ??
        {},
  );

  Map<String, dynamic> toJson() => toMap();
  factory GameState.fromJson(Map<String, dynamic> json) =>
      GameState.fromMap(json);
}
