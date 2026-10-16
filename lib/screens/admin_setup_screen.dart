import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';
import '../providers/game_provider.dart';
import 'admin_game_screen.dart';

class AdminSetupScreen extends StatefulWidget {
  const AdminSetupScreen({super.key});

  @override
  State<AdminSetupScreen> createState() => _AdminSetupScreenState();
}

class _AdminSetupScreenState extends State<AdminSetupScreen> {
  int targetScore = 5;
  int roundTime = 30; // 0 = Sınırsız
  int buzzerTime = 5;
  bool isRandomMode = false;
  bool isRoomCreated = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final gameState = provider.gameState;

    return Scaffold(
      appBar: AppBar(
        title: Text(isRoomCreated ? 'Lobi Bekleme Odası' : 'Oda Ayarları'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: isRoomCreated
            ? _buildLobbyView(provider, gameState)
            : _buildSetupForm(provider),
      ),
    );
  }

  // 1. AŞAMA: ODA OLUŞTURMA FORMU
  Widget _buildSetupForm(GameProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Oyun Modu'),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('Takım Seçmeli')),
                selected: !isRandomMode,
                onSelected: (val) => setState(() => isRandomMode = !val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('Rastgele Takımlar')),
                selected: isRandomMode,
                onSelected: (val) => setState(() => isRandomMode = val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('Hedef Skor: $targetScore Puan'),
        Slider(
          value: targetScore.toDouble(),
          min: 1,
          max: 15,
          divisions: 14,
          label: '$targetScore',
          onChanged: (val) => setState(() => targetScore = val.round()),
        ),
        const SizedBox(height: 16),
        _buildSectionTitle(
          roundTime == 0
              ? 'Tur Süresi: Sınırsız'
              : 'Tur Süresi: $roundTime Saniye',
        ),
        Slider(
          value: roundTime.toDouble(),
          min: 0,
          max: 120,
          divisions: 24,
          label: roundTime == 0 ? 'Sınırsız' : '$roundTime sn',
          onChanged: (val) => setState(() => roundTime = val.round()),
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('Buzzer Konuşma Süresi: $buzzerTime Saniye'),
        Slider(
          value: buzzerTime.toDouble(),
          min: 1,
          max: 30,
          divisions: 29,
          label: '$buzzerTime sn',
          onChanged: (val) => setState(() => buzzerTime = val.round()),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00E676),
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () async {
            await provider.createRoom(
              targetScore: targetScore,
              roundTime: roundTime,
              buzzerTime: buzzerTime,
              isRandomMode: isRandomMode,
            );
            setState(() => isRoomCreated = true);
          },
          child: const Text(
            'ODAYI KUR',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // 2. AŞAMA: LOBİ VE CANLI AYAR GÜNCELLEME EKRANI
  Widget _buildLobbyView(GameProvider provider, GameState state) {
    final readyCount = state.players.length;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E222A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF00E676), width: 1.5),
          ),
          child: Column(
            children: [
              const Text(
                'ODA KODU',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white54,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                state.roomCode,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 8,
                  color: Color(0xFF00E676),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Arkadaşlarına bu kodu söyle (aynı Hotspot ağında olmalısınız)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.white38),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildPlayerSlot(
                1,
                state.players.isNotEmpty ? state.players[0].name : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPlayerSlot(
                2,
                state.players.length > 1 ? state.players[1].name : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Lobi Dağılmadan Ayarları Güncelleme Alanı
        ExpansionTile(
          collapsedBackgroundColor: const Color(0xFF1E222A),
          backgroundColor: const Color(0xFF1E222A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Kuralları / Süreleri Değiştir',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Hedef Skor: ${state.targetScore}'),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle,
                          color: Color(0xFF00E676),
                        ),
                        onPressed: () => provider.updateSettings(
                          targetScore: state.targetScore + 1,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle,
                          color: Colors.redAccent,
                        ),
                        onPressed: () => provider.updateSettings(
                          targetScore: (state.targetScore > 1)
                              ? state.targetScore - 1
                              : 1,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Buzzer Süresi: ${state.buzzerTime} sn'),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle,
                          color: Color(0xFF00E676),
                        ),
                        onPressed: () => provider.updateSettings(
                          buzzerTime: state.buzzerTime + 1,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle,
                          color: Colors.redAccent,
                        ),
                        onPressed: () => provider.updateSettings(
                          buzzerTime: (state.buzzerTime > 1)
                              ? state.buzzerTime - 1
                              : 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: readyCount == 2
                ? const Color(0xFF00E676)
                : Colors.grey.shade800,
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: readyCount == 2
              ? () {
                  provider.startRound();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminGameScreen()),
                  );
                }
              : null,
          child: Text(
            readyCount == 2
                ? 'OYUNU BAŞLAT'
                : 'OYUNCULAR BEKLENİYOR ($readyCount/2)',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerSlot(int slotNumber, String? name) {
    final isFilled = name != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E222A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFilled ? const Color(0xFF00E676) : Colors.white10,
        ),
      ),
      child: Column(
        children: [
          Icon(
            isFilled ? Icons.check_circle : Icons.hourglass_top,
            color: isFilled ? const Color(0xFF00E676) : Colors.white24,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            isFilled ? name : 'Oyuncu $slotNumber',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isFilled ? Colors.white : Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white70,
      ),
    );
  }
}
