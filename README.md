# Futbol 3-2-1

> **Transfermarkt veritabanı destekli, yerel ağ üzerinden sıfır gecikmeyle (WebSocket & UDP) oynanan çevrimdışı futbol trivia ve ortak oyuncu düellosu.**

---

## Proje Hakkında

**Futbol 3-2-1**, iki oyuncunun seçtiği veya sistemin rastgele belirlediği iki farklı kulüpte forma giymiş ortak futbolcuları en hızlı şekilde bulmaya dayalı bir bilgi yarışması oyunudur. Yurt ortamında veya arkadaş gruplarında harici internet bağlantısına ihtiyaç duymadan, mobil erişim noktası (Hotspot) üzerinden ultra düşük gecikmeyle çalışmak üzere tasarlanmıştır.

Oyun; tarafsız bir **Hakem (Admin)** kontrol paneli, milisaniyeler içinde sonuç veren **yerel SQLite veritabanı**, ses süresini kontrol eden **Benjamin (Buzzer)** butonu ve stratejik **Sarı Kart** kuralları ile eksiksiz bir stadyum rekabeti sunar.

---

## Öne Çıkan Özellikler

* Tamamen Çevrimdışı & Sıfır Gecikme: Mobil veri veya internet bağlantısı gerektirmez. PC/Telefon Hotspot'u üzerinden saf `dart:io` WebSockets ile çalışır.
* Otomatik Yerel Ağ Keşfi (UDP Beacon): IP adresi girmeye gerek kalmadan, arka plandaki UDP yayını sayesinde oyuncular yalnızca **4 haneli oda kodunu** girerek saniyeler içinde lobiye bağlanır.
* Optimize SQLite Veritabanı (~5.2 MB): Transfermarkt açık veri setinden filtrelenmiş 750+ kulüp, 50.000+ oyuncu ve 60.000+ kariyer eşleşmesi cihaz üzerinde yerel olarak saklanır.
* "Benjamin" Buzzer & Ters Progress Bar: Cevap hakkını ilk kapan oyuncu için geri sayan dairesel süre göstergesi.
* Hakem (Admin) Kontrol İstasyonu:
  * **Kaza Önleyici Onay:** Yanlışlıkla dokunmaları önlemek için 1 saniye basılı tutarak dolan "Doğru (+1)" ve "Yanlış" butonları.
  * **Milisaniyelik Canlı Doğrulama:** Hakem oyuncunun söylediği ismi yazdığı anda SQLite üzerinden anlık ortaklık sorgusu.
  * **Gizli İpucu Paneli:** Tıkanılan turlarda iki kulübün geçmişteki tüm ortak futbolcularını listeleyen hakem konsolu.
* Sarı / Kırmızı Kart Kuralı: Bir maç serisinde daha önce kullanılmış bir kulübü tekrar seçen oyuncu doğrudan sarı kart görür ve turu kaybeder. 2 sarı kart alan oyuncu kırmızı kartla cezalandırılır ve rakibe +1 puan yazılır.

---

## Oyun Kuralları

1. **Takım Belirleme:** 
   * **Seçmeli Mod:** Oyuncular veritabanından akıllarındaki takımları aratarak gizlice kilitler.
   * **Rastgele Mod:** Sistem, ortak oyuncusu bulunduğu kesin olan 2 kulübü rastgele eşleştirir.
2. **3 • 2 • 1 Yansıtma:** Hakem "Yansıt" dediğinde her iki oyuncunun ekranında 3 saniyelik geri sayım başlar ve takımlar aynı anda açıklanır.
3. **Benjamin (Buzzer):** Takımları gören oyunculardan ortak ismi ilk hatırlayan butona basar. Konuşma süresi içinde ismi söyler.
4. **Puanlama:** Hakem cevabı onaylarsa basan oyuncu +1 puan alır; yanlışsa Benjamin tekrar boşa çıkar ve kalan süreden devam edilir.
5. **Şampiyonluk:** Belirlenen hedef skora (örn: 5 puan) ilk ulaşan maçı kazanır.

---

## Teknoloji Yığını

* **Frontend:** Flutter & Dart
* **State Management:** Provider
* **Yerel İletişim:** `dart:io` WebSocket & UDP Multicast Sockets
* **Veritabanı:** SQLite (`sqflite`), SQL İndeksleri
* **Veri Hazırlama:** Python (Pandas, SQLite3)

---

## Proje Mimarisi

```text
futbol_321/
├── assets/
│   └── football.db               # Üretilen hafif SQLite veritabanı (~5.2 MB)
├── scripts/
│   ├── build_db.py               # Transfermarkt CSV'lerini işleyip DB oluşturan script
│   └── (clubs.csv, players.csv, appearances.csv - .gitignore ile hariç tutulur)
└── lib/
    ├── core/
    │   ├── database/
    │   │   └── db_helper.dart    # SQLite bağlantısı ve kesişim/arama sorguları
    │   └── network/
    │       ├── socket_server.dart# Admin WebSocket sunucusu & UDP Beacon
    │       └── socket_client.dart# Oyuncu istemcisi & otomatik keşif dinleyicisi
    ├── models/
    │   ├── club.dart             # Kulüp modeli
    │   ├── player.dart           # Futbolcu modeli
    │   ├── game_event.dart       # Ağ iletişim protokolü paketleri
    │   └── game_state.dart       # Skor, lobi, kart ve tur durumu modeli
    ├── providers/
    │   └── game_provider.dart    # Oyun motoru, sayaçlar ve kural denetimi
    ├── screens/
    │   ├── home_screen.dart      # Giriş ve mod seçim ekranı
    │   ├── admin_setup_screen.dart # Oda kurma, süre ayarları ve lobi
    │   ├── admin_game_screen.dart# Hakem onay ve canlı doğrulama paneli
    │   └── player_game_screen.dart# Skor tablosu, 3-2-1, buzzer ve takım seçimi
    └── main.dart                 # Uygulama başlangıcı ve tema ayarları