import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/database/db_helper.dart';
import '../models/club.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';

class PlayerGameScreen extends StatefulWidget {
  const PlayerGameScreen({super.key});

  @override
  State<PlayerGameScreen> createState() => _PlayerGameScreenState();
}

class _PlayerGameScreenState extends State<PlayerGameScreen> {
  static const Color neonGreen = Color(0xFF00E676);
  static const Color darkCard = Color(0xFF1E222A);
  static const Color yellow = Color(0xFFFFD600);

  Club? _selectedClub;
  List<Club> _searchResults = [];
  bool _isSearching = false;
  final TextEditingController _teamSearchController = TextEditingController();

  @override
  void dispose() {
    _teamSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final state = provider.gameState;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FUTBOL 3-2-1',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'ODA ${state.roomCode}',
                style: const TextStyle(
                  color: neonGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildScoreboard(state, provider),
              const SizedBox(height: 24),

              Expanded(child: _buildGameArea(state, provider)),

              const SizedBox(height: 16),

              _buildBottomStatus(state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreboard(GameState state, GameProvider provider) {
    final p1 = state.players.isNotEmpty ? state.players[0] : null;
    final p2 = state.players.length > 1 ? state.players[1] : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildPlayerScore(
              name: p1?.name ?? 'Oyuncu 1',
              score: p1?.score ?? 0,
              yellowCards: p1?.yellowCards ?? 0,
              isMe: p1?.id == provider.myPlayerId,
            ),
          ),
          Container(width: 1, height: 50, color: Colors.white12),
          Expanded(
            child: _buildPlayerScore(
              name: p2?.name ?? 'Oyuncu 2',
              score: p2?.score ?? 0,
              yellowCards: p2?.yellowCards ?? 0,
              isMe: p2?.id == provider.myPlayerId,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerScore({
    required String name,
    required int score,
    required int yellowCards,
    required bool isMe,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isMe ? neonGreen : Colors.white70,
                  fontSize: 14,
                  fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isMe) ...[
              const SizedBox(width: 4),
              const Text(
                '(Sen)',
                style: TextStyle(color: neonGreen, fontSize: 11),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$score',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        // 2 Adet Sarı Kart Slotu
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCardSlot(filled: yellowCards >= 1),
            const SizedBox(width: 4),
            _buildCardSlot(filled: yellowCards >= 2),
          ],
        ),
      ],
    );
  }

  Widget _buildCardSlot({required bool filled}) {
    return Container(
      width: 12,
      height: 18,
      decoration: BoxDecoration(
        color: filled ? yellow : Colors.transparent,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: filled ? yellow : Colors.white24, width: 1.5),
      ),
    );
  }

  // Şimdilik oyun aşamasına göre temel içerik.
  // Sonraki parçalarda takım seçimi ve Benjamin burada
  // gerçek işlevleriyle yer alacak.
  Widget _buildGameArea(GameState state, GameProvider provider) {
    switch (state.phase) {
      case GamePhase.lobby:
        return _buildMessage(
          icon: Icons.hourglass_top_rounded,
          title: 'Oda bekleniyor',
          subtitle: 'Admin oyunu başlattığında burada olacaksın.',
        );

      case GamePhase.teamSelection:
        return state.isRandomMode
            ? _buildMessage(
                icon: Icons.casino_outlined,
                title: 'Rastgele Mod',
                subtitle: 'Admin takımları yansıtana kadar bekle.',
              )
            : _buildTeamSelection(state, provider);

      case GamePhase.countdown321:
        return _build321Countdown();

      case GamePhase.answering:
      case GamePhase.buzzerActive:
        return _buildBuzzerArea(state, provider);

      case GamePhase.roundEnded:
        return _buildRoundEndedArea(provider);

      case GamePhase.gameOver:
        return _buildGameOverArea(state);
    }
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: neonGreen),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // Alt durum göstergesi.
  Widget _buildBottomStatus(GameState state) {
    final isUnlimited = state.roundTime == 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer_outlined, color: yellow, size: 20),
          const SizedBox(width: 8),
          Text(
            isUnlimited
                ? 'Tur süresi: Sınırsız'
                : 'Tur süresi: ${state.remainingRoundTime} sn',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSelection(GameState state, GameProvider provider) {
    // Oyuncunun kendi durumunu bul
    final myPlayer = state.players.firstWhere(
      (p) => p.id == provider.myPlayerId,
      orElse: () => PlayerState(id: '', name: ''),
    );

    // Takımı zaten kilitlediyse bekleme kartı göster
    if (myPlayer.isLocked) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: darkCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: neonGreen.withAlpha(76)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_rounded, size: 64, color: neonGreen),
            const SizedBox(height: 20),
            Text(
              myPlayer.selectedClub?.name ?? 'Takım Kilitlendi',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            const Text(
              'Rakibin seçimini yapması ve Adminin yansıtması bekleniyor...',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      );
    }

    // Henüz kilitlemediyse arama ve seçim ekranı
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'AKLINDAKİ TAKIMI SEÇ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _teamSearchController,
            onChanged: (val) async {
              if (val.trim().length >= 2) {
                setState(() => _isSearching = true);
                final results = await DbHelper.instance.searchClubs(val.trim());
                setState(() {
                  _searchResults = results;
                  _isSearching = false;
                });
              } else {
                setState(() => _searchResults = []);
              }
            },
            decoration: InputDecoration(
              hintText: 'Takım ara (örn: Ajax, Porto, Trabzon)...',
              prefixIcon: const Icon(Icons.search, color: neonGreen),
              filled: true,
              fillColor: const Color(0xFF2A2F3D),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Seçilen Takım Göstergesi
          if (_selectedClub != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: neonGreen.withAlpha(38),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: neonGreen),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: neonGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedClub!.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Arama Sonuçları Listesi
          Expanded(
            child: _isSearching
                ? const Center(
                    child: CircularProgressIndicator(color: neonGreen),
                  )
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final club = _searchResults[index];
                      final isCurrent = _selectedClub?.id == club.id;
                      return ListTile(
                        dense: true,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        tileColor: isCurrent
                            ? const Color(0xFF2A2F3D)
                            : Colors.transparent,
                        title: Text(
                          club.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          club.country,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedClub = club;
                            _searchResults = [];
                            _teamSearchController.text = club.name;
                          });
                        },
                      );
                    },
                  ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedClub != null
                  ? neonGreen
                  : Colors.grey.shade800,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _selectedClub != null
                ? () {
                    provider.lockSelectedClub(_selectedClub!);
                  }
                : null,
            child: const Text(
              'TAKIMI KİLİTLE',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _build321Countdown() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: neonGreen.withAlpha(100), width: 2),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bolt, size: 72, color: yellow),
          SizedBox(height: 20),
          Text(
            '3 • 2 • 1',
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w900,
              letterSpacing: 6,
              color: neonGreen,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'TAKIMLAR YANSIYOR!',
            style: TextStyle(
              fontSize: 16,
              letterSpacing: 3,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuzzerArea(GameState state, GameProvider provider) {
    final isBuzzerActive = state.phase == GamePhase.buzzerActive;
    final isMyTurn = state.buzzerPlayerId == provider.myPlayerId;
    final someoneElseTurn = isBuzzerActive && !isMyTurn;

    // Basan oyuncunun adını bul
    final activePlayerName = state.players
        .firstWhere(
          (p) => p.id == state.buzzerPlayerId,
          orElse: () => PlayerState(id: '', name: 'Biri'),
        )
        .name;

    // Ters progress bar oranı (kalan süre / toplam süre)
    final progress = state.buzzerTime > 0
        ? (state.remainingBuzzerTime / state.buzzerTime).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      children: [
        // 1. Karşılaşan İki Takım Paneli
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: darkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  state.clubA?.name ?? 'Takım A',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'VS',
                  style: TextStyle(
                    color: yellow,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  state.clubB?.name ?? 'Takım B',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),

        // 2. Benjamin (Buzzer) Butonu
        GestureDetector(
          onTap: (!isBuzzerActive)
              ? () {
                  provider.pressBuzzer();
                }
              : null,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ters Progress Bar (Dairesel)
              if (isBuzzerActive)
                SizedBox(
                  width: 220,
                  height: 220,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isMyTurn ? neonGreen : Colors.redAccent,
                    ),
                  ),
                ),
              // Buton Gövdesi
              Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: someoneElseTurn
                      ? const Color(0xFF2A2F3D)
                      : (isMyTurn ? neonGreen : const Color(0xFF00C853)),
                  boxShadow: [
                    BoxShadow(
                      color: (someoneElseTurn ? Colors.black : neonGreen)
                          .withAlpha(120),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          someoneElseTurn ? Icons.lock : Icons.touch_app,
                          size: 44,
                          color: someoneElseTurn
                              ? Colors.white38
                              : Colors.black,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          someoneElseTurn
                              ? '$activePlayerName\nCEVAPLIYOR'
                              : (isMyTurn
                                    ? 'SÖYLE!\n${state.remainingBuzzerTime}s'
                                    : 'BENJAMİN!\n(BAS)'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            color: someoneElseTurn
                                ? Colors.white54
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildRoundEndedArea(GameProvider provider) {
    final warning = provider.yellowCardWarning;

    // Eğer sarı kart kuralı tetiklendiyse dev sarı kart bas
    if (warning != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: darkCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: yellow, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 100,
              decoration: BoxDecoration(
                color: yellow,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: yellow.withAlpha(120),
                    blurRadius: 25,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'SARI KART!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: yellow,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              warning,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Adminin diğer tura geçmesi bekleniyor...',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      );
    }

    // Normal tur sonu (Biri bildi veya süre bitti)
    return _buildMessage(
      icon: Icons.flag_rounded,
      title: 'TUR SONA ERDİ',
      subtitle: 'Admin diğer tura geçene kadar bekle.',
    );
  }

  Widget _buildGameOverArea(GameState state) {
    // En yüksek puanı alanı bul
    PlayerState? winner;
    if (state.players.isNotEmpty) {
      winner = state.players.reduce(
        (curr, next) => curr.score > next.score ? curr : next,
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: neonGreen, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, size: 84, color: yellow),
          const SizedBox(height: 20),
          const Text(
            'MAÇ BİTTİ!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            winner?.name ?? 'KAZANAN',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: neonGreen,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Skor: ${winner?.score} Puan',
            style: const TextStyle(fontSize: 16, color: Colors.white60),
          ),
        ],
      ),
    );
  }
}
