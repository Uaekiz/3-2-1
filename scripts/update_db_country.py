import os
import sqlite3
import pandas as pd

db_path = 'assets/football.db'
csv_candidates = ['scripts/players.csv', 'scripts/player.csv']

csv_path = None
for c in csv_candidates:
    if os.path.exists(c):
        csv_path = c
        break

if not csv_path:
    print("Hata: CSV dosyası bulunamadı!")
    exit(1)

print(f"CSV okunuyor: {csv_path}...")
df = pd.read_csv(csv_path)

# Kolon isimlerini eşle
country_col = None
for col in ['country_of_citizenship', 'citizenship', 'country']:
    if col in df.columns:
        country_col = col
        break

id_col = 'player_id' if 'player_id' in df.columns else 'id'

print(f"Kullanılan kolonlar -> ID: '{id_col}', Ülke: '{country_col}'")

conn = sqlite3.connect(db_path)
cur = conn.cursor()

# 1. Kolon yoksa ekle
cols = [r[1] for r in cur.execute("PRAGMA table_info(players)").fetchall()]
if 'country' not in cols:
    print("players tablosuna 'country' kolonu ekleniyor...")
    cur.execute("ALTER TABLE players ADD COLUMN country TEXT")

# 2. Güncelleme yap
print("Oyuncu vatandaşlıkları güncelleniyor (birkaç saniye sürebilir)...")
valid_df = df.dropna(subset=[country_col, id_col])
update_data = [(str(row[country_col]), int(row[id_col])) for _, row in valid_df.iterrows()]

cur.executemany("UPDATE players SET country = ? WHERE id = ?", update_data)

# 3. Hızlı sorgulama için indeks at
print("İndeks oluşturuluyor...")
cur.execute("CREATE INDEX IF NOT EXISTS idx_players_country ON players(country)")
conn.commit()

# 4. Kontrol çıktısı
count = cur.execute("SELECT COUNT(*) FROM players WHERE country IS NOT NULL").fetchone()[0]
sample = cur.execute("SELECT id, name, country FROM players WHERE country IS NOT NULL LIMIT 5").fetchall()

print("\n--- GÜNCELLEME TAMAMLANDI ---")
print(f"Ülkesi başarıyla doldurulan futbolcu sayısı: {count}")
print("Örnek kayıtlar:")
for s in sample:
    print(f"ID: {s[0]} | İsim: {s[1]} | Ülke: {s[2]}")

conn.close()