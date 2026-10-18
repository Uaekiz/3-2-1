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

  // Takım arama durumu
  Club? _selectedClub;
  List<Club> _searchResults = [];
  bool _isSearchingClub = false;
  final TextEditingController _teamSearchController = TextEditingController();

  // Ülke arama durumu (Ülke - Takım modu için)
  String? _selectedCountry;
  List<String> _countrySearchResults = [];
  bool _isSearchingCountry = false;
  final TextEditingController _countrySearchController =
      TextEditingController();

  @override
  void dispose() {
    _teamSearchController.dispose();
    _countrySearchController.dispose();
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

  Widget _buildGameArea(GameState state, GameProvider provider) {
    switch (state.phase) {
      case GamePhase.lobby:
        return _buildMessage(
          icon: Icons.hourglass_top_rounded,
          title: 'Oda Bekleniyor',
          subtitle: 'Admin oyunu başlattığında burada olacaksın.',
        );

      case GamePhase.teamSelection:
        return state.isRandomMode
            ? _buildMessage(
                icon: Icons.casino_outlined,
                title: 'Rastgele Mod',
                subtitle: 'Admin eşleşmeyi yansıtana kadar bekle.',
              )
            : _buildSelectionArea(state, provider);

      case GamePhase.countdown321:
        return _build321Countdown(state);

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

  // Takım veya Ülke Seçim Ekranı
  Widget _buildSelectionArea(GameState state, GameProvider provider) {
    final myPlayer = state.players.firstWhere(
      (p) => p.id == provider.myPlayerId,
      orElse: () => PlayerState(id: '', name: ''),
    );

    // Kilitlendiyse bekleme kartı göster
    if (myPlayer.isLocked) {
      final lockedTitle =
          myPlayer.selectedCountry ??
          myPlayer.selectedClub?.name ??
          'Seçim Kilitlendi';
      final isCountry = myPlayer.selectedCountry != null;

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
            Icon(
              isCountry ? Icons.flag_circle_rounded : Icons.lock_rounded,
              size: 64,
              color: neonGreen,
            ),
            const SizedBox(height: 20),
            Text(
              lockedTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
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

    // Ülke - Kulüp modunda bu oyuncu ülke mi takım mı seçecek?
    final bool isCountryPicker =
        state.format == GameFormat.countryVsClub &&
        state.countryPickerPlayerId == provider.myPlayerId;

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
          // Rol Bildirim Rozeti (Ülke - Kulüp modu ise)
          if (state.format == GameFormat.countryVsClub)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: neonGreen.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: neonGreen.withAlpha(80)),
              ),
              child: Row(
                children: [
                  Icon(
                    isCountryPicker ? Icons.flag_rounded : Icons.shield_rounded,
                    color: neonGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isCountryPicker
                          ? 'Bu tur ÜLKE seçme sırası sende!'
                          : 'Bu tur TAKIM seçme sırası sende!',
                      style: const TextStyle(
                        color: neonGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Text(
            isCountryPicker ? 'BİR ÜLKE SEÇ' : 'AKLINDAKİ TAKIMI SEÇ',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),

          // Arama Girişi (Ülke veya Takım)
          TextField(
            controller: isCountryPicker
                ? _countrySearchController
                : _teamSearchController,
            onChanged: (val) async {
              final query = val.trim();
              if (query.length >= 2) {
                if (isCountryPicker) {
                  setState(() => _isSearchingCountry = true);
                  final results = await DbHelper.instance.searchCountries(
                    query,
                  );
                  setState(() {
                    _countrySearchResults = results;
                    _isSearchingCountry = false;
                  });
                } else {
                  setState(() => _isSearchingClub = true);
                  final results = await DbHelper.instance.searchClubs(query);
                  setState(() {
                    _searchResults = results;
                    _isSearchingClub = false;
                  });
                }
              } else {
                setState(() {
                  _searchResults = [];
                  _countrySearchResults = [];
                });
              }
            },
            decoration: InputDecoration(
              hintText: isCountryPicker
                  ? 'Ülke ara (örn: Nigeria, Brazil, Turkey)...'
                  : 'Takım ara (örn: Ajax, Porto, Trabzon)...',
              prefixIcon: Icon(
                isCountryPicker ? Icons.public : Icons.search,
                color: neonGreen,
              ),
              filled: true,
              fillColor: const Color(0xFF2A2F3D),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Seçim Göstergesi
          if (isCountryPicker && _selectedCountry != null)
            _buildSelectedBadge(_selectedCountry!),
          if (!isCountryPicker && _selectedClub != null)
            _buildSelectedBadge(_selectedClub!.name),

          // Arama Sonuçları
          Expanded(
            child: isCountryPicker
                ? _buildCountrySearchResults()
                : _buildClubSearchResults(),
          ),
          const SizedBox(height: 8),

          // Kilitle Butonu
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  (isCountryPicker
                      ? _selectedCountry != null
                      : _selectedClub != null)
                  ? neonGreen
                  : Colors.grey.shade800,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              if (isCountryPicker) {
                if (_selectedCountry != null) {
                  provider.lockSelectedCountry(_selectedCountry!);
                  setState(() {
                    _selectedCountry = null;
                    _countrySearchResults = [];
                    _countrySearchController.clear();
                  });
                }
              } else {
                if (_selectedClub != null) {
                  provider.lockSelectedClub(_selectedClub!);
                  setState(() {
                    _selectedClub = null;
                    _searchResults = [];
                    _teamSearchController.clear();
                  });
                }
              }
            },
            child: Text(
              isCountryPicker ? 'ÜLKEYİ KİLİTLE' : 'TAKIMI KİLİTLE',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: neonGreen.withAlpha(38),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: neonGreen),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: neonGreen, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClubSearchResults() {
    if (_isSearchingClub) {
      return const Center(child: CircularProgressIndicator(color: neonGreen));
    }
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final club = _searchResults[index];
        final isCurrent = _selectedClub?.id == club.id;
        return ListTile(
          dense: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          tileColor: isCurrent ? const Color(0xFF2A2F3D) : Colors.transparent,
          title: Text(
            club.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            club.country,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
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
    );
  }

  Widget _buildCountrySearchResults() {
    if (_isSearchingCountry) {
      return const Center(child: CircularProgressIndicator(color: neonGreen));
    }
    return ListView.builder(
      itemCount: _countrySearchResults.length,
      itemBuilder: (context, index) {
        final country = _countrySearchResults[index];
        final isCurrent = _selectedCountry == country;
        return ListTile(
          dense: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          tileColor: isCurrent ? const Color(0xFF2A2F3D) : Colors.transparent,
          leading: const Icon(Icons.public, color: Colors.white54, size: 18),
          title: Text(
            country,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          onTap: () {
            setState(() {
              _selectedCountry = country;
              _countrySearchResults = [];
              _countrySearchController.text = country;
            });
          },
        );
      },
    );
  }

  Widget _build321Countdown(GameState state) {
    final isCountryMod = state.format == GameFormat.countryVsClub;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: neonGreen.withAlpha(100), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bolt, size: 72, color: yellow),
          const SizedBox(height: 20),
          const Text(
            '3 • 2 • 1',
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w900,
              letterSpacing: 6,
              color: neonGreen,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isCountryMod ? 'ÜLKE & TAKIM YANSIYOR!' : 'TAKIMLAR YANSIYOR!',
            style: const TextStyle(
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

    final activePlayerName = state.players
        .firstWhere(
          (p) => p.id == state.buzzerPlayerId,
          orElse: () => PlayerState(id: '', name: 'Biri'),
        )
        .name;

    final progress = state.buzzerTime > 0
        ? (state.remainingBuzzerTime / state.buzzerTime).clamp(0.0, 1.0)
        : 0.0;

    // Karşılaşma Başlığı
    final String leftTitle = state.format == GameFormat.countryVsClub
        ? (state.activeCountry ?? 'Ülke')
        : (state.clubA?.name ?? 'Takım A');

    final String rightTitle = state.format == GameFormat.countryVsClub
        ? (state.clubA?.name ?? 'Takım')
        : (state.clubB?.name ?? 'Takım B');

    return Column(
      children: [
        // 1. Karşılaşma Paneli
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
                  leftTitle,
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
                  rightTitle,
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

    return _buildMessage(
      icon: Icons.flag_rounded,
      title: 'TUR SONA ERDİ',
      subtitle: 'Admin diğer tura geçene kadar bekle.',
    );
  }

  Widget _buildGameOverArea(GameState state) {
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
