import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';
import '../providers/game_provider.dart';

class AdminGameScreen extends StatefulWidget {
  const AdminGameScreen({super.key});

  @override
  State<AdminGameScreen> createState() => _AdminGameScreenState();
}

class _AdminGameScreenState extends State<AdminGameScreen> {
  static const Color neonGreen = Color(0xFF00E676);
  static const Color darkCard = Color(0xFF1E222A);
  static const Color yellow = Color(0xFFFFD600);

  final TextEditingController _playerSearchController = TextEditingController();

  @override
  void dispose() {
    _playerSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final state = provider.gameState;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'HAKEM PANELİ',
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
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: neonGreen.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: neonGreen),
                ),
                child: Text(
                  'ODA ${state.roomCode}',
                  style: const TextStyle(
                    color: neonGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
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
              // 1. Skor ve Sarı Kart Göstergesi
              _buildScoreboard(state),
              const SizedBox(height: 16),

              // 2. Oyun Yönetim Alanı (Yansıt, Benjamin Karar vs.)
              Expanded(flex: 3, child: _buildControlArea(state, provider)),
              const SizedBox(height: 16),

              // 3. Hakem Doğrulama & SQLite Arama Alanı
              Expanded(flex: 2, child: _buildVerificationArea(provider, state)),
            ],
          ),
        ),
      ),
    );
  }

  // Skor ve Kart Slotları
  Widget _buildScoreboard(GameState state) {
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
            ),
          ),
          Container(width: 1, height: 50, color: Colors.white12),
          Expanded(
            child: _buildPlayerScore(
              name: p2?.name ?? 'Oyuncu 2',
              score: p2?.score ?? 0,
              yellowCards: p2?.yellowCards ?? 0,
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
  }) {
    return Column(
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
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

  Widget _buildControlArea(GameState state, GameProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: _buildPhaseContent(state, provider),
    );
  }

  Widget _buildPhaseContent(GameState state, GameProvider provider) {
    switch (state.phase) {
      // 1. TAKIM / ÜLKE SEÇİM AŞAMASI
      case GamePhase.teamSelection:
        final p1 = state.players.isNotEmpty ? state.players[0] : null;
        final p2 = state.players.length > 1 ? state.players[1] : null;
        final bothLocked =
            state.isRandomMode ||
            ((p1?.isLocked ?? false) && (p2?.isLocked ?? false));

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'KİLİTLEME DURUMU',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _buildTeamLockStatus(p1)),
                const SizedBox(width: 12),
                Expanded(child: _buildTeamLockStatus(p2)),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: bothLocked ? neonGreen : Colors.grey.shade800,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: bothLocked ? () => provider.triggerReflect() : null,
              child: Text(
                bothLocked
                    ? 'YANSIT (3-2-1 BAŞLAT)'
                    : 'OYUNCULAR BEKLENİYOR...',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        );

      // 2. 3-2-1 GERİ SAYIM
      case GamePhase.countdown321:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bolt, color: yellow, size: 50),
              SizedBox(height: 10),
              Text(
                '3 • 2 • 1',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: neonGreen,
                ),
              ),
              Text(
                'Ekrana yansıtılıyor...',
                style: TextStyle(color: Colors.white54),
              ),
            ],
          ),
        );

      // 3. OYUNCULAR DÜŞÜNÜYOR (BENJAMİN BEKLENİYOR)
      case GamePhase.answering:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildVersusBadge(state),
            const Spacer(),
            const Icon(
              Icons.touch_app_outlined,
              size: 48,
              color: Colors.white38,
            ),
            const SizedBox(height: 10),
            const Text(
              'BENJAMİN BEKLENİYOR...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              state.roundTime == 0
                  ? 'Süre: Sınırsız'
                  : 'Kalan Tur Süresi: ${state.remainingRoundTime} sn',
              style: const TextStyle(
                color: yellow,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
          ],
        );

      // 4. BİRİ BENJAMİN'E BASTI! (HAKEM KARAR EKRANI)
      case GamePhase.buzzerActive:
        final activePlayer = state.players.firstWhere(
          (p) => p.id == state.buzzerPlayerId,
          orElse: () => PlayerState(id: '', name: 'Biri'),
        );

        return Column(
          children: [
            _buildVersusBadge(state),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withAlpha(40),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.redAccent),
              ),
              child: Text(
                '${activePlayer.name.toUpperCase()} BASTI! (Kalan: ${state.remainingBuzzerTime}s)',
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: _HoldButton(
                    label: 'YANLIŞ',
                    icon: Icons.close,
                    color: Colors.redAccent,
                    onConfirmed: () =>
                        provider.submitAnswerResult(isCorrect: false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _HoldButton(
                    label: 'DOĞRU (+1)',
                    icon: Icons.check,
                    color: neonGreen,
                    onConfirmed: () =>
                        provider.submitAnswerResult(isCorrect: true),
                  ),
                ),
              ],
            ),
          ],
        );

      // 5. TUR BİTTİ
      case GamePhase.roundEnded:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              provider.yellowCardWarning != null
                  ? Icons.warning_amber_rounded
                  : Icons.flag_rounded,
              size: 54,
              color: provider.yellowCardWarning != null ? yellow : neonGreen,
            ),
            const SizedBox(height: 12),
            Text(
              provider.yellowCardWarning != null
                  ? 'SARI KART CEZASI!'
                  : 'TUR TAMAMLANDI',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: provider.yellowCardWarning != null
                    ? yellow
                    : Colors.white,
              ),
            ),
            if (provider.yellowCardWarning != null) ...[
              const SizedBox(height: 8),
              Text(
                provider.yellowCardWarning!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: neonGreen,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => provider.nextRound(),
              child: const Text(
                'SONRAKİ TURA GEÇ',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ],
        );

      // 6. MAÇ BİTTİ
      case GamePhase.gameOver:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, size: 64, color: yellow),
            const SizedBox(height: 12),
            const Text(
              'MAÇ BİTTİ!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: neonGreen,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => provider.resetMatch(),
              child: const Text(
                'YENİ MAÇ BAŞLAT',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ],
        );

      default:
        return const SizedBox();
    }
  }

  // Takım / Ülke Kilitleme Kartı
  Widget _buildTeamLockStatus(PlayerState? player) {
    final isLocked = player?.isLocked ?? false;
    String selectionText = 'Seçiyor...';
    if (isLocked) {
      selectionText =
          player?.selectedCountry ?? player?.selectedClub?.name ?? 'Seçildi';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2F3D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isLocked ? neonGreen : Colors.white12),
      ),
      child: Column(
        children: [
          Icon(
            isLocked ? Icons.lock : Icons.lock_open,
            color: isLocked ? neonGreen : Colors.white38,
            size: 22,
          ),
          const SizedBox(height: 6),
          Text(
            player?.name ?? 'Oyuncu',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            selectionText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isLocked ? neonGreen : Colors.white38,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // Ekranda Karşılaşan Takımlar / Ülke Rozeti
  Widget _buildVersusBadge(GameState state) {
    final title = state.format == GameFormat.countryVsClub
        ? '${state.activeCountry ?? 'Ülke'}  vs  ${state.clubA?.name ?? 'Takım'}'
        : '${state.clubA?.name ?? 'Takım A'}  vs  ${state.clubB?.name ?? 'Takım B'}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2F3D),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildVerificationArea(GameProvider provider, GameState state) {
    final hasActivePair = state.format == GameFormat.countryVsClub
        ? (state.activeCountry != null && state.clubA != null)
        : (state.clubA != null && state.clubB != null);

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
          // Başlık ve İpucu Butonu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.search, size: 18, color: neonGreen),
                  SizedBox(width: 6),
                  Text(
                    'OYUNCU DOĞRULAMA (SQLITE)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              if (hasActivePair)
                IconButton(
                  tooltip: 'Tüm Ortak Oyuncuları Gör',
                  icon: const Icon(
                    Icons.lightbulb_outline,
                    color: yellow,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showHintsModal(context, provider, state),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Arama Girişi
          TextField(
            controller: _playerSearchController,
            enabled: hasActivePair,
            onChanged: (val) {
              if (val.trim().length >= 2) {
                provider.searchPlayerInCurrentClubs(val.trim());
              }
            },
            decoration: InputDecoration(
              hintText: hasActivePair
                  ? 'Söylenen futbolcuyu ara...'
                  : 'Eşleşme yansıtılınca arama açılır...',
              hintStyle: const TextStyle(fontSize: 13, color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF2A2F3D),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              suffixIcon: _playerSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        size: 18,
                        color: Colors.white38,
                      ),
                      onPressed: () {
                        _playerSearchController.clear();
                        provider.searchPlayerInCurrentClubs('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 8),

          Expanded(child: _buildVerificationResults(provider)),
        ],
      ),
    );
  }

  Widget _buildVerificationResults(GameProvider provider) {
    if (provider.isSearchingPlayer) {
      return const Center(
        child: CircularProgressIndicator(color: neonGreen, strokeWidth: 2),
      );
    }

    if (_playerSearchController.text.trim().length >= 2) {
      if (provider.verifiedPlayers.isEmpty) {
        return Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.redAccent.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.redAccent.withAlpha(100)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 16),
                SizedBox(width: 6),
                Text(
                  'Bu eşleşmede ortak oynamamış!',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return ListView.builder(
        itemCount: provider.verifiedPlayers.length,
        itemBuilder: (context, index) {
          final player = provider.verifiedPlayers[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: neonGreen.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: neonGreen),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: neonGreen, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    player.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
                const Text(
                  'DOĞRULANDI',
                  style: TextStyle(
                    color: neonGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return const Center(
      child: Text(
        'Oyuncunun söylediği ismi yazarak kontrol et',
        style: TextStyle(color: Colors.white24, fontSize: 12),
      ),
    );
  }

  // Hakem İpucu Alt Paneli (Bottom Sheet)
  void _showHintsModal(
    BuildContext context,
    GameProvider provider,
    GameState state,
  ) async {
    await provider.loadHints();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E222A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ORTAK TÜM OYUNCULAR',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: yellow,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                Text(
                  state.format == GameFormat.countryVsClub
                      ? '${state.activeCountry} & ${state.clubA?.name}'
                      : '${state.clubA?.name} & ${state.clubB?.name}',
                  style: const TextStyle(fontSize: 12, color: Colors.white38),
                ),
                const Divider(color: Colors.white12, height: 20),
                Expanded(
                  child: provider.hintPlayers.isEmpty
                      ? const Center(
                          child: Text(
                            'Veritabanında ortak oyuncu bulunamadı.',
                            style: TextStyle(color: Colors.white38),
                          ),
                        )
                      : ListView.separated(
                          itemCount: provider.hintPlayers.length,
                          separatorBuilder: (_, __) =>
                              const Divider(color: Colors.white10, height: 1),
                          itemBuilder: (context, index) {
                            return ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.person,
                                color: neonGreen,
                                size: 20,
                              ),
                              title: Text(
                                provider.hintPlayers[index].name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// 1 Saniye Basılı Tutunca Tetiklenen Özel Hakem Butonu
class _HoldButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onConfirmed;

  const _HoldButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onConfirmed,
  });

  @override
  State<_HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<_HoldButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1000),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            widget.onConfirmed();
            _controller.reset();
          }
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2F3D),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.color.withAlpha(120),
                width: 1.5,
              ),
            ),
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: _controller.value,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.color.withAlpha(180),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.icon, color: Colors.white, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        _controller.value > 0 ? 'BASILI TUT...' : widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
