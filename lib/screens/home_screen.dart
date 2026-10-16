import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import 'admin_setup_screen.dart';
import 'player_game_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showJoinDialog(BuildContext context) {
    final nameController = TextEditingController();
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E222A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Odaya Katıl',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Adın / Lakabın',
                filled: true,
                fillColor: const Color(0xFF2A2F3D),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: InputDecoration(
                labelText: '4 Haneli Oda Kodu',
                counterText: '',
                filled: true,
                fillColor: const Color(0xFF2A2F3D),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              final name = nameController.text.trim();
              final code = codeController.text.trim();
              if (name.isEmpty || code.length != 4) return;

              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Oda aranıyor ve bağlanılıyor...'),
                ),
              );

              final success = await context.read<GameProvider>().joinRoom(
                roomCode: code,
                playerName: name,
              );

              if (context.mounted) {
                if (success) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PlayerGameScreen()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Oda bulunamadı! Hotspot bağlı mı ve kod doğru mu?',
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            child: const Text('Bağlan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const Text(
                '3 - 2 - 1',
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  color: Color(0xFF00E676),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'FUTBOL ORTAK OYUNCU DÜELLOSU',
                style: TextStyle(
                  fontSize: 13,
                  letterSpacing: 2,
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminSetupScreen()),
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sports, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'ADMIN OLARAK BAŞLAT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24, width: 2),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => _showJoinDialog(context),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_add_alt_1, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'OYUNCU OLARAK KATIL',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
