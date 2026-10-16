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
  String? yellowCardWarning; // "X daha önce seçilmiş takımı seçtiği için sarı kart gördü!"

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
  }) async {
    isAdmin = true;
    final code = (1000 + Random().nextInt(9000)).toString(); // 4 haneli kod

    gameState = GameState(
      roomCode: code,
      targetScore: targetScore,
      roundTime: roundTime,
      buzzerTime: buzzerTime,
      isRandomMode: isRandomMode,
      phase: GamePhase.lobby,
    );

    final server = SocketServer.instance;
    await server.startServer(roomCode: code);

    // Gelen olayları dinle
    server.onEventReceived = (event, sender) {
      _handleAdminEvent(event);
    };

    server.onClientDisconnected = (_) {
      // Oyuncu düştüğünde lobi güncellemesi
      notifyListeners();
    };

    notifyListeners();
  }

  // 2. Ayarları Dinamik Güncelleme (Lobi dağılmadan)
  void updateSettings({
    int? targetScore,
    int? roundTime,
    int? buzzerTime,
    bool? isRandomMode,
  }) {
    if (!isAdmin) return;
    if (targetScore != null) gameState.targetScore = targetScore;
    if (roundTime != null) gameState.roundTime = roundTime;
    if (buzzerTime != null) gameState.buzzerTime = buzzerTime;
    if (isRandomMode != null) gameState.isRandomMode = isRandomMode;

    _broadcastState();
    notifyListeners();
  }

  // 3. Turu Başlatma
  Future<void> startRound() async {
    if (!isAdmin) return;
    yellowCardWarning = null;
    verifiedPlayers = [];
    hintPlayers = [];

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
      for (var p in gameState.players) {
        p.selectedClub = null;
        p.isLocked = false;
      }
      gameState.phase = GamePhase.teamSelection;
    }

    _broadcastState();
    notifyListeners();
  }

  // 4. Admin "Yansıt" Dediğinde (3-2-1 ve Sarı Kart Kontrolü)
  void triggerReflect() {
    if (!isAdmin) return;

    // Takım Seçmeli Moddaysa: Daha önce kullanıldı mı kontrolü
    if (!gameState.isRandomMode) {
      PlayerState? cardCulprit;
      for (var p in gameState.players) {
        if (p.selectedClub != null &&
            gameState.usedClubIds.contains(p.selectedClub!.id)) {
          cardCulprit = p;
          break;
        }
      }

      if (cardCulprit != null) {
        // SARI KART YENDİ -> Tur durdurulur, tahmin yapılmaz!
        cardCulprit.yellowCards += 1;
        yellowCardWarning =
            '${cardCulprit.name}, daha önce seçilmiş olan "${cardCulprit.selectedClub!.name}" takımını seçtiği için SARI KART gördü!';
        gameState.phase = GamePhase.roundEnded;

        _broadcastState();
        notifyListeners();
        return;
      }

      // Kural ihlali yoksa takımları kullanılanlar havuzuna ekle
      if (gameState.players.length >= 2) {
        gameState.clubA = gameState.players[0].selectedClub;
        gameState.clubB = gameState.players[1].selectedClub;
        if (gameState.clubA != null)
          gameState.usedClubIds.add(gameState.clubA!.id);
        if (gameState.clubB != null)
          gameState.usedClubIds.add(gameState.clubB!.id);
      }
    }

    // 3-2-1 Geri Sayımını Başlat
    gameState.phase = GamePhase.countdown321;
    _broadcastState();
    notifyListeners();

    // 3 saniye sonra takımlar yansır ve soru süresi başlar
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
        // Tur süresi bitti
        timer.cancel();
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
        // Konuşma süresi doldu, admin kararı bekliyor
        timer.cancel();
        notifyListeners();
      }
    });
  }

  // 6. Buzzer'a Basıldığında
  void handleBuzzerPress(String playerId) {
    if (gameState.phase != GamePhase.answering) return;

    _roundTimer?.cancel(); // Genel süreyi dondur
    gameState.phase = GamePhase.buzzerActive;
    gameState.buzzerPlayerId = playerId;

    _startBuzzerTimer();
    _broadcastState();
    notifyListeners();
  }

  // 7. Admin Kararı (1 Saniye Basılı Tutarak Onaylama)
  void submitAnswerResult({required bool isCorrect}) {
    if (!isAdmin || gameState.buzzerPlayerId == null) return;
    _buzzerTimer?.cancel();

    final answeringPlayer = gameState.players.firstWhere(
      (p) => p.id == gameState.buzzerPlayerId,
    );

    if (isCorrect) {
      // Doğru bildi: +1 Puan
      answeringPlayer.score += 1;
      gameState.buzzerPlayerId = null;

      // Hedef puana ulaşıldı mı?
      if (answeringPlayer.score >= gameState.targetScore) {
        gameState.phase = GamePhase.gameOver;
      } else {
        gameState.phase = GamePhase.roundEnded;
      }
    } else {
      // Yanlış bildi: Benjamin tekrar boşa çıkar, kalan süreden devam
      gameState.buzzerPlayerId = null;
      gameState.phase = GamePhase.answering;
      _startRoundTimer();
    }

    _broadcastState();
    notifyListeners();
  }

  // 8. Diğer Tura Geç Butonu (Admin)
  void nextRound() {
    if (!isAdmin) return;

    // Eğer çift sarıdan kırmızı durumu varsa kontrol et
    for (var p in gameState.players) {
      if (p.yellowCards >= 2) {
        // 2 sarı kart = Kırmızı -> Rakibe +1 puan, kartlar sıfırlanır
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

  // Yeni bir maç serisi başlatıldığında tüm skorları, kartları ve geçmiş takımları sıfırlar
  void resetMatch() {
    if (!isAdmin) return;

    for (var p in gameState.players) {
      p.score = 0;
      p.yellowCards = 0;
      p.selectedClub = null;
      p.isLocked = false;
    }
    gameState.usedClubIds.clear();
    yellowCardWarning = null;

    startRound();
  }

  // 9. Admin Arama & Doğrulama Motoru (SQLite Milisaniye Sorgusu)
  Future<void> searchPlayerInCurrentClubs(String query) async {
    if (gameState.clubA == null || gameState.clubB == null) return;
    isSearchingPlayer = true;
    notifyListeners();

    verifiedPlayers = await DbHelper.instance.checkCommonPlayer(
      clubAId: gameState.clubA!.id,
      clubBId: gameState.clubB!.id,
      query: query,
    );

    isSearchingPlayer = false;
    notifyListeners();
  }

  // Admin İpucu: Ortak tüm oyuncuları dök
  Future<void> loadHints() async {
    if (gameState.clubA == null || gameState.clubB == null) return;
    hintPlayers = await DbHelper.instance.getAllCommonPlayers(
      clubAId: gameState.clubA!.id,
      clubBId: gameState.clubB!.id,
    );
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
        _broadcastState();
        notifyListeners();
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
