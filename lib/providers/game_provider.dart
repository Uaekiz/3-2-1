import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/database/db_helper.dart';
import '../core/network/socket_server.dart';
import '../core/network/socket_client.dart';
import '../models/club.dart';
import '../models/player.dart';
import '../models/game_event.dart';
import '../models/game_state.dart';

class GameProvider extends ChangeNotifier {
  bool isAdmin = false;
  String? myPlayerId;
  String? myPlayerName;

  GameState gameState = GameState(roomCode: '');

  // Admin için canlı arama ve ipucu sonuçları
  List<Player> verifiedPlayers = [];
  List<Player> hintPlayers = [];
  bool isSearchingPlayer = false;
  String? yellowCardWarning;

  Timer? _roundTimer;
  Timer? _buzzerTimer;

  // -------------------------------------------------------------
  // ADMIN YÖNETİMİ
  // -------------------------------------------------------------

  // 1. Odayı Kurma
  Future<void> createRoom({
    required int targetScore,
    required int roundTime,
    required int buzzerTime,
    required bool isRandomMode,
    GameFormat format = GameFormat.clubVsClub,
    bool keepCountryPickerOnFail = true,
  }) async {
    isAdmin = true;
    final code = (1000 + Random().nextInt(9000)).toString();

    gameState = GameState(
      roomCode: code,
      targetScore: targetScore,
      roundTime: roundTime,
      buzzerTime: buzzerTime,
      isRandomMode: isRandomMode,
      format: format,
      keepCountryPickerOnFail: keepCountryPickerOnFail,
      phase: GamePhase.lobby,
    );

    final server = SocketServer.instance;
    await server.startServer(roomCode: code);

    server.onEventReceived = (event, sender) {
      _handleAdminEvent(event);
    };

    server.onClientDisconnected = (_) {
      notifyListeners();
    };

    notifyListeners();
  }

  // 2. Ayarları Dinamik Güncelleme
  void updateSettings({
    int? targetScore,
    int? roundTime,
    int? buzzerTime,
    bool? isRandomMode,
    GameFormat? format,
    bool? keepCountryPickerOnFail,
  }) {
    if (!isAdmin) return;
    if (targetScore != null) gameState.targetScore = targetScore;
    if (roundTime != null) gameState.roundTime = roundTime;
    if (buzzerTime != null) gameState.buzzerTime = buzzerTime;
    if (isRandomMode != null) gameState.isRandomMode = isRandomMode;
    if (format != null) gameState.format = format;
    if (keepCountryPickerOnFail != null) {
      gameState.keepCountryPickerOnFail = keepCountryPickerOnFail;
    }

    _broadcastState();
    notifyListeners();
  }

  // 3. Turu Başlatma
  Future<void> startRound() async {
    if (!isAdmin) return;
    yellowCardWarning = null;
    verifiedPlayers = [];
    hintPlayers = [];

    // Seçim durumlarını ve kilitleri temizle
    for (var p in gameState.players) {
      p.selectedClub = null;
      p.selectedCountry = null;
      p.isLocked = false;
    }

    if (gameState.format == GameFormat.countryVsClub) {
      // Ülke seçecek oyuncu henüz atanmadıysa ilk turda Oyuncu 1'e ver
      if (gameState.countryPickerPlayerId == null &&
          gameState.players.isNotEmpty) {
        gameState.countryPickerPlayerId = gameState.players[0].id;
      }

      if (gameState.isRandomMode) {
        final pair = await DbHelper.instance.getRandomClubAndCountry();
        if (pair != null) {
          gameState.clubA = Club(
            id: pair['club_id'] as int,
            name: pair['club_name'] as String,
            country: pair['club_country'] as String,
          );
          gameState.activeCountry = pair['player_country'] as String;
          gameState.phase = GamePhase.teamSelection;
        }
      } else {
        gameState.clubA = null;
        gameState.clubB = null;
        gameState.activeCountry = null;
        gameState.phase = GamePhase.teamSelection;
      }
    } else {
      // Klasik Takım - Takım Formatı
      if (gameState.isRandomMode) {
        final pair = await DbHelper.instance.getRandomPairWithCommonPlayers();
        if (pair != null) {
          gameState.clubA = pair[0];
          gameState.clubB = pair[1];
          gameState.phase = GamePhase.teamSelection;
        }
      } else {
        gameState.clubA = null;
        gameState.clubB = null;
        gameState.phase = GamePhase.teamSelection;
      }
    }

    _broadcastState();
    notifyListeners();
  }

  // 4. Admin "Yansıt" Dediğinde (3-2-1 ve Sarı Kart Kontrolü)
  void triggerReflect() {
    if (!isAdmin) return;

    if (!gameState.isRandomMode) {
      PlayerState? cardCulprit;
      String? culpritReason;

      // 1. Kulüp tekrarı kontrolü
      for (var p in gameState.players) {
        if (p.selectedClub != null &&
            gameState.usedClubIds.contains(p.selectedClub!.id)) {
          cardCulprit = p;
          culpritReason =
              'daha önce seçilmiş "${p.selectedClub!.name}" takımını tekrar seçtiği için';
          break;
        }
      }

      // 2. Ülke tekrarı kontrolü (Ülke - Kulüp formatı)
      if (cardCulprit == null && gameState.format == GameFormat.countryVsClub) {
        for (var p in gameState.players) {
          if (p.selectedCountry != null &&
              gameState.usedCountries.contains(
                p.selectedCountry!.trim().toLowerCase(),
              )) {
            cardCulprit = p;
            culpritReason =
                'daha önce seçilmiş "${p.selectedCountry}" ülkesini tekrar seçtiği için';
            break;
          }
        }
      }

      // Kural ihlali varsa tur durdurulur ve sarı kart verilir
      if (cardCulprit != null) {
        cardCulprit.yellowCards += 1;
        yellowCardWarning =
            '${cardCulprit.name}, $culpritReason SARI KART gördü!';

        if (cardCulprit.yellowCards >= 2) {
          final opponent = gameState.players.firstWhere(
            (other) => other.id != cardCulprit!.id,
            orElse: () => cardCulprit!,
          );
          opponent.score += 1;
          gameState.phase = GamePhase.gameOver;
        } else {
          gameState.phase = GamePhase.roundEnded;
        }

        _broadcastState();
        notifyListeners();
        return;
      }

      // İhlal yoksa kullanılanlar havuzuna ekle
      if (gameState.format == GameFormat.clubVsClub) {
        if (gameState.players.length >= 2) {
          gameState.clubA = gameState.players[0].selectedClub;
          gameState.clubB = gameState.players[1].selectedClub;
          if (gameState.clubA != null)
            gameState.usedClubIds.add(gameState.clubA!.id);
          if (gameState.clubB != null)
            gameState.usedClubIds.add(gameState.clubB!.id);
        }
      } else {
        final clubPlayer = gameState.players.firstWhere(
          (p) => p.selectedClub != null,
          orElse: () => gameState.players[0],
        );
        gameState.clubA = clubPlayer.selectedClub;
        if (gameState.clubA != null)
          gameState.usedClubIds.add(gameState.clubA!.id);
        if (gameState.activeCountry != null) {
          gameState.usedCountries.add(
            gameState.activeCountry!.trim().toLowerCase(),
          );
        }
      }
    }

    gameState.phase = GamePhase.countdown321;
    _broadcastState();
    notifyListeners();

    Timer(const Duration(seconds: 3), () {
      gameState.phase = GamePhase.answering;
      gameState.remainingRoundTime = gameState.roundTime;
      _broadcastState();
      notifyListeners();
      _startRoundTimer();
    });
  }

  // 5. Sayaçlar
  void _startRoundTimer() {
    _roundTimer?.cancel();
    if (gameState.roundTime <= 0) return; // 0 ise süresiz

    _roundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (gameState.phase != GamePhase.answering) {
        timer.cancel();
        return;
      }

      if (gameState.remainingRoundTime > 0) {
        gameState.remainingRoundTime--;
        _broadcastState();
        notifyListeners();
      } else {
        // Tur süresi bitti: İkisi de bilememiş sayılır
        timer.cancel();
        if (gameState.format == GameFormat.countryVsClub &&
            !gameState.keepCountryPickerOnFail) {
          _switchCountryPicker(); // Switch kapalıysa sıra diğer oyuncuya geçer
        }
        gameState.phase = GamePhase.roundEnded;
        _broadcastState();
        notifyListeners();
      }
    });
  }

  void _startBuzzerTimer() {
    _buzzerTimer?.cancel();
    gameState.remainingBuzzerTime = gameState.buzzerTime;

    _buzzerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (gameState.phase != GamePhase.buzzerActive) {
        timer.cancel();
        return;
      }

      if (gameState.remainingBuzzerTime > 0) {
        gameState.remainingBuzzerTime--;
        _broadcastState();
        notifyListeners();
      } else {
        // Konuşma süresi doldu, admin kararı bekleniyor
        timer.cancel();
        notifyListeners();
      }
    });
  }

  // 6. Buzzer'a Basıldığında
  void handleBuzzerPress(String playerId) {
    if (gameState.phase != GamePhase.answering) return;

    _roundTimer?.cancel();
    gameState.phase = GamePhase.buzzerActive;
    gameState.buzzerPlayerId = playerId;

    _startBuzzerTimer();
    _broadcastState();
    notifyListeners();
  }

  // 7. Admin Kararı
  void submitAnswerResult({required bool isCorrect}) {
    if (!isAdmin || gameState.buzzerPlayerId == null) return;
    _buzzerTimer?.cancel();

    final answeringPlayer = gameState.players.firstWhere(
      (p) => p.id == gameState.buzzerPlayerId,
    );

    if (isCorrect) {
      answeringPlayer.score += 1;
      gameState.buzzerPlayerId = null;

      // Doğru bilindiğinde ülke seçme sırası kesinlikle el değiştirir
      if (gameState.format == GameFormat.countryVsClub) {
        _switchCountryPicker();
      }

      if (answeringPlayer.score >= gameState.targetScore) {
        gameState.phase = GamePhase.gameOver;
      } else {
        gameState.phase = GamePhase.roundEnded;
      }
    } else {
      gameState.buzzerPlayerId = null;
      gameState.phase = GamePhase.answering;
      _startRoundTimer();
    }

    _broadcastState();
    notifyListeners();
  }

  void _switchCountryPicker() {
    if (gameState.players.length < 2) return;
    final currentPickerId = gameState.countryPickerPlayerId;
    final otherPlayer = gameState.players.firstWhere(
      (p) => p.id != currentPickerId,
      orElse: () => gameState.players[0],
    );
    gameState.countryPickerPlayerId = otherPlayer.id;
  }

  // 8. Diğer Tura Geç Butonu (Admin)
  void nextRound() {
    if (!isAdmin) return;

    for (var p in gameState.players) {
      if (p.yellowCards >= 2) {
        final opponent = gameState.players.firstWhere(
          (other) => other.id != p.id,
        );
        opponent.score += 1;
        p.yellowCards = 0;

        if (opponent.score >= gameState.targetScore) {
          gameState.phase = GamePhase.gameOver;
          _broadcastState();
          notifyListeners();
          return;
        }
      }
    }

    startRound();
  }

  // Yeni Maç Başlatma (Her şeyi sıfırlar)
  void resetMatch() {
    if (!isAdmin) return;

    for (var p in gameState.players) {
      p.score = 0;
      p.yellowCards = 0;
      p.selectedClub = null;
      p.selectedCountry = null;
      p.isLocked = false;
    }
    gameState.usedClubIds.clear();
    gameState.usedCountries.clear();
    gameState.activeCountry = null;
    gameState.countryPickerPlayerId = null;
    yellowCardWarning = null;

    startRound();
  }

  // 9. Canlı Doğrulama ve İpucu Motoru
  Future<void> searchPlayerInCurrentClubs(String query) async {
    if (gameState.clubA == null) return;
    isSearchingPlayer = true;
    notifyListeners();

    if (gameState.format == GameFormat.countryVsClub) {
      if (gameState.activeCountry == null) {
        isSearchingPlayer = false;
        notifyListeners();
        return;
      }
      final players = await DbHelper.instance.getPlayersByClubAndCountry(
        gameState.clubA!.id,
        gameState.activeCountry!,
      );
      verifiedPlayers = players
          .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } else {
      if (gameState.clubB == null) {
        isSearchingPlayer = false;
        notifyListeners();
        return;
      }
      verifiedPlayers = await DbHelper.instance.checkCommonPlayer(
        clubAId: gameState.clubA!.id,
        clubBId: gameState.clubB!.id,
        query: query,
      );
    }

    isSearchingPlayer = false;
    notifyListeners();
  }

  Future<void> loadHints() async {
    if (gameState.clubA == null) return;

    if (gameState.format == GameFormat.countryVsClub) {
      if (gameState.activeCountry == null) return;
      hintPlayers = await DbHelper.instance.getPlayersByClubAndCountry(
        gameState.clubA!.id,
        gameState.activeCountry!,
      );
    } else {
      if (gameState.clubB == null) return;
      hintPlayers = await DbHelper.instance.getAllCommonPlayers(
        clubAId: gameState.clubA!.id,
        clubBId: gameState.clubB!.id,
      );
    }
    notifyListeners();
  }

  // -------------------------------------------------------------
  // OYUNCU (CLIENT) YÖNETİMİ
  // -------------------------------------------------------------

  Future<bool> joinRoom({
    required String roomCode,
    required String playerName,
  }) async {
    isAdmin = false;
    myPlayerName = playerName;
    myPlayerId = 'player_${Random().nextInt(99999)}';

    final client = SocketClient.instance;
    final success = await client.discoverAndConnect(targetRoomCode: roomCode);

    if (success) {
      client.onEventReceived = _handleClientEvent;
      client.send(
        GameEvent(
          type: EventTypes.joinRoom,
          payload: {'id': myPlayerId, 'name': myPlayerName},
        ),
      );
      return true;
    }
    return false;
  }

  void lockSelectedClub(Club club) {
    if (isAdmin) return;
    SocketClient.instance.send(
      GameEvent(
        type: EventTypes.selectTeam,
        payload: {'playerId': myPlayerId, 'club': club.toMap()},
      ),
    );
  }

  void lockSelectedCountry(String country) {
    if (gameState.phase != GamePhase.teamSelection) return;

    if (isAdmin) {
      _processCountryLock(myPlayerId ?? '', country);
    } else {
      SocketClient.instance.send(
        GameEvent(
          type: EventTypes.selectCountry,
          payload: {'playerId': myPlayerId, 'country': country},
        ),
      );

      final myPlayer = gameState.players.firstWhere((p) => p.id == myPlayerId);
      myPlayer.selectedCountry = country;
      myPlayer.isLocked = true;
      notifyListeners();
    }
  }

  void _processCountryLock(String playerId, String country) {
    final player = gameState.players.firstWhere(
      (p) => p.id == playerId,
      orElse: () => gameState.players[0],
    );
    player.selectedCountry = country;
    player.isLocked = true;
    gameState.activeCountry = country;

    _checkIfBothLocked();
    _broadcastState();
    notifyListeners();
  }

  void _checkIfBothLocked() {
    if (gameState.players.length < 2) return;

    final p1 = gameState.players[0];
    final p2 = gameState.players[1];

    if (p1.isLocked && p2.isLocked) {
      if (gameState.format == GameFormat.clubVsClub) {
        gameState.clubA = p1.selectedClub;
        gameState.clubB = p2.selectedClub;
      } else {
        final clubPlayer = p1.selectedClub != null ? p1 : p2;
        gameState.clubA = clubPlayer.selectedClub;
      }
    }
  }

  void pressBuzzer() {
    if (isAdmin || gameState.phase != GamePhase.answering) return;
    SocketClient.instance.send(
      GameEvent(
        type: EventTypes.buzzerPressed,
        payload: {'playerId': myPlayerId},
      ),
    );
  }

  // -------------------------------------------------------------
  // İLETİŞİM PAKETLERİ (EVENT HANDLERS)
  // -------------------------------------------------------------

  void _handleAdminEvent(GameEvent event) {
    switch (event.type) {
      case EventTypes.joinRoom:
        final id = event.payload['id'];
        final name = event.payload['name'];
        if (gameState.players.length < 2) {
          gameState.players.add(PlayerState(id: id, name: name));
          _broadcastState();
          notifyListeners();
        }
        break;

      case EventTypes.selectTeam:
        final pId = event.payload['playerId'];
        final clubMap = event.payload['club'];
        final player = gameState.players.firstWhere((p) => p.id == pId);
        player.selectedClub = Club.fromMap(clubMap);
        player.isLocked = true;
        _checkIfBothLocked();
        _broadcastState();
        notifyListeners();
        break;

      case EventTypes.selectCountry:
        if (isAdmin) {
          final playerId = event.payload['playerId'] as String;
          final country = event.payload['country'] as String;
          _processCountryLock(playerId, country);
        }
        break;

      case EventTypes.buzzerPressed:
        final pId = event.payload['playerId'];
        handleBuzzerPress(pId);
        break;
    }
  }

  void _handleClientEvent(GameEvent event) {
    if (event.type == EventTypes.lobbyUpdate) {
      gameState = GameState.fromMap(event.payload);
      notifyListeners();
    }
  }

  void _broadcastState() {
    SocketServer.instance.broadcast(
      GameEvent(type: EventTypes.lobbyUpdate, payload: gameState.toMap()),
    );
  }

  @override
  void dispose() {
    _roundTimer?.cancel();
    _buzzerTimer?.cancel();
    super.dispose();
  }
}
