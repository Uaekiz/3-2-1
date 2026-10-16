import sqlite3
import pandas as pd
import os

# scripts klasörünün ve assets hedefinin tam yolunu al
current_dir = os.path.dirname(os.path.abspath(__file__))
assets_dir = os.path.join(current_dir, "..", "assets")
os.makedirs(assets_dir, exist_ok=True)
db_path = os.path.join(assets_dir, "football.db")

clubs_file = os.path.join(current_dir, "clubs.csv")
players_file = os.path.join(current_dir, "players.csv")
app_file = os.path.join(current_dir, "appearances.csv")

# Dosyaların varlığını kontrol et
for f in [clubs_file, players_file, app_file]:
    if not os.path.exists(f):
        print(f"HATA: {os.path.basename(f)} dosyası scripts klasöründe bulunamadı!")
        print("Lütfen dosyayı indirip scripts/ klasörüne attığından emin ol.")
        exit(1)

print("İşlem başlatılıyor...\n")

# 1. Kulüpleri Hazırla
print("1/4: Kulüpler işleniyor...")
df_clubs = pd.read_csv(clubs_file, usecols=['club_id', 'name', 'domestic_competition_id'])
df_clubs.rename(columns={'club_id': 'id', 'domestic_competition_id': 'country'}, inplace=True)
df_clubs.dropna(subset=['name'], inplace=True)
print(f"-> Toplam {len(df_clubs)} kulüp hazırlandı.")

# 2. Oyuncuları Hazırla
print("2/4: Oyuncular işleniyor...")
df_players = pd.read_csv(players_file, usecols=['player_id', 'name'])
df_players.rename(columns={'player_id': 'id'}, inplace=True)
df_players.dropna(subset=['name'], inplace=True)
print(f"-> Toplam {len(df_players)} oyuncu hazırlandı.")

# 3. Oyuncu - Kulüp Kesişimlerini Hazırla (Appearances)
print("3/4: Kariyer eşleşmeleri taranıyor (mükerrer kayıtlar eleniyor)...")
# Belleği yormamak için veri tiplerini int32 olarak okuyoruz
df_app = pd.read_csv(
    app_file, 
    usecols=['player_id', 'player_club_id'],
    dtype={'player_id': 'int32', 'player_club_id': 'int32'}
)
df_app.rename(columns={'player_club_id': 'club_id'}, inplace=True)

# Aynı oyuncunun aynı kulüpteki yüzlerce maç kaydını tek bir satıra indir
df_club_players = df_app.drop_duplicates(subset=['player_id', 'club_id'])
print(f"-> Toplam {len(df_club_players)} tekil kulüp-oyuncu eşleşmesi çıkarıldı.")

# 4. SQLite Dosyasına Yaz ve İndeksle
print(f"\n4/4: {db_path} oluşturuluyor...")
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

df_clubs.to_sql('clubs', conn, if_exists='replace', index=False)
df_players.to_sql('players', conn, if_exists='replace', index=False)
df_club_players.to_sql('club_players', conn, if_exists='replace', index=False)

print("Milisaniyelik sorgular için indeksler basılıyor...")
cursor.execute("CREATE INDEX IF NOT EXISTS idx_clubs_name ON clubs(name);")
cursor.execute("CREATE INDEX IF NOT EXISTS idx_players_name ON players(name);")
cursor.execute("CREATE INDEX IF NOT EXISTS idx_cp_player ON club_players(player_id);")
cursor.execute("CREATE INDEX IF NOT EXISTS idx_cp_club ON club_players(club_id);")
cursor.execute("CREATE INDEX IF NOT EXISTS idx_cp_both ON club_players(club_id, player_id);")

conn.commit()
conn.close()

db_size_mb = os.path.getsize(db_path) / (1024 * 1024)
print(f"\nİşlem tamam! football.db başarıyla oluşturuldu.")
print(f"Dosya Boyutu: {db_size_mb:.2f} MB")