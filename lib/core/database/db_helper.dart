import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/club.dart';
import '../../models/player.dart';

class DbHelper {
  static final DbHelper instance = DbHelper._init();
  static Database? _database;

  DbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('football.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Uygulama ilk açıldığında assets altındaki DB'yi cihazın kendi diskine kopyalar
    final exists = await databaseExists(path);
    if (!exists) {
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      ByteData data = await rootBundle.load(join('assets', 'football.db'));
      List<int> bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await File(path).writeAsBytes(bytes, flush: true);
    }

    return await openDatabase(path, readOnly: true);
  }

  // 1. Takım arama (Autocomplete için)
  Future<List<Club>> searchClubs(String query) async {
    if (query.trim().isEmpty) return [];
    final db = await database;
    final result = await db.rawQuery(
      'SELECT * FROM clubs WHERE name LIKE ? ORDER BY name ASC LIMIT 15',
      ['%$query%'],
    );
    return result.map((e) => Club.fromMap(e)).toList();
  }

  // 2. Admin arama kutusu: İki takımda ortak oynamış mı doğrulaması
  Future<List<Player>> checkCommonPlayer({
    required int clubAId,
    required int clubBId,
    required String query,
  }) async {
    if (query.trim().isEmpty) return [];
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT p.id, p.name 
      FROM players p
      JOIN club_players cp1 ON p.id = cp1.player_id AND cp1.club_id = ?
      JOIN club_players cp2 ON p.id = cp2.player_id AND cp2.club_id = ?
      WHERE p.name LIKE ?
      LIMIT 10
      ''',
      [clubAId, clubBId, '%$query%'],
    );
    return result.map((e) => Player.fromMap(e)).toList();
  }

  // 3. Admin İpucu/Kopya: Bu iki takımın ortak TÜM oyuncularını getirir
  Future<List<Player>> getAllCommonPlayers({
    required int clubAId,
    required int clubBId,
  }) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT DISTINCT p.id, p.name 
      FROM players p
      JOIN club_players cp1 ON p.id = cp1.player_id AND cp1.club_id = ?
      JOIN club_players cp2 ON p.id = cp2.player_id AND cp2.club_id = ?
      ORDER BY p.name ASC
      ''',
      [clubAId, clubBId],
    );
    return result.map((e) => Player.fromMap(e)).toList();
  }

  // 4. Rastgele Mod için: Kesin ortak oyuncusu olan rastgele iki kulüp çifti seçer
  Future<List<Club>?> getRandomPairWithCommonPlayers() async {
    final db = await database;
    // Ortak oyuncusu olan rastgele bir oyuncu seçip onun oynadığı 2 farklı takımı çekiyoruz
    final result = await db.rawQuery('''
      SELECT c1.id AS id1, c1.name AS name1, c1.country AS country1,
             c2.id AS id2, c2.name AS name2, c2.country AS country2
      FROM club_players cp1
      JOIN club_players cp2 ON cp1.player_id = cp2.player_id AND cp1.club_id != cp2.club_id
      JOIN clubs c1 ON cp1.club_id = c1.id
      JOIN clubs c2 ON cp2.club_id = c2.id
      ORDER BY RANDOM()
      LIMIT 1
      ''');

    if (result.isNotEmpty) {
      final row = result.first;
      return [
        Club(
          id: row['id1'] as int,
          name: row['name1'] as String,
          country: (row['country1'] ?? '') as String,
        ),
        Club(
          id: row['id2'] as int,
          name: row['name2'] as String,
          country: (row['country2'] ?? '') as String,
        ),
      ];
    }
    return null;
  }

  // Ülke arama (Autocomplete için en çok 20 sonuç döndürür)
  Future<List<String>> searchCountries(String query) async {
    final db = await database;
    final results = await db.rawQuery(
      '''
      SELECT DISTINCT country 
      FROM players 
      WHERE country IS NOT NULL 
        AND country != '' 
        AND country LIKE ? 
      ORDER BY country ASC 
      LIMIT 20
    ''',
      ['%$query%'],
    );

    return results.map((row) => row['country'] as String).toList();
  }

  // Kulüp ve Ülke kesişimindeki futbolcuları getirir (Doğrulama ve İpucu için)
  Future<List<Player>> getPlayersByClubAndCountry(
    int clubId,
    String country,
  ) async {
    final db = await database;
    final results = await db.rawQuery(
      '''
      SELECT DISTINCT p.id, p.name
      FROM players p
      JOIN appearances a ON p.id = a.player_id
      WHERE a.club_id = ? AND LOWER(p.country) = LOWER(?)
      ORDER BY p.name ASC
    ''',
      [clubId, country],
    );

    return results.map((row) => Player.fromMap(row)).toList();
  }

  // Rastgele mod için en az 1 ortak oyuncusu garanti olan kulüp ve ülke çifti seçer
  Future<Map<String, dynamic>?> getRandomClubAndCountry() async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT c.id AS club_id, c.name AS club_name, c.country AS club_country, p.country AS player_country
      FROM appearances a
      JOIN clubs c ON a.club_id = c.id
      JOIN players p ON a.player_id = p.id
      WHERE p.country IS NOT NULL AND p.country != ''
      ORDER BY RANDOM()
      LIMIT 1
    ''');

    if (results.isEmpty) return null;
    return results.first;
  }
}
