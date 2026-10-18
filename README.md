# Futbol 3-2-1

> **Transfermarkt veritabanı destekli, yerel ağ üzerinden sıfır gecikmeyle (WebSocket ve UDP) oynanan çevrimdışı futbol trivia, ortak oyuncu ve vatandaşlık düellosu.**

---

## Proje Hakkında

**Futbol 3-2-1**, oyuncuların belirlediği veya sistemin rastgele seçtiği takımlar ve ülkeler üzerinden ortak futbolcuları en hızlı şekilde bulmaya dayalı bir bilgi yarışması oyunudur. Harici internet bağlantısına veya mobil veriye ihtiyaç duymadan, aynı yerel ağ veya mobil erişim noktası (Hotspot) üzerinden ultra düşük gecikmeyle çalışır.

Oyun; tarafsız bir **Hakem (Admin)** paneli, milisaniyeler içinde sonuç veren **yerel SQLite veritabanı**, cevap hakkı tanıyan **Benjamin (Buzzer)** butonu, stratejik **Sarı ve Kırmızı Kart** kuralları ve iki farklı rekabetçi format sunar.

---

## Oyun Formatları

* **Kulüp - Kulüp Modu (Klasik Düello):** İki farklı kulüpte (örneğin Milan ve PSG) kariyeri boyunca forma giymiş ortak futbolcuları bulma modu.
* **Ülke - Kulüp Modu (Vatandaşlık Düellosu):** Bir oyuncunun ülke (örneğin Nijerya), diğer oyuncunun kulüp (örneğin Milan) seçtiği; o ülkenin vatandaşı olup seçilen kulüpte oynamış futbolcuları bulma modu.

---

## Öne Çıkan Özellikler

* **Tamamen Çevrimdışı ve Sıfır Gecikme:** Mobil veri veya harici internet gerektirmez. Cihazlar arası saf `dart:io` WebSocket mimarisi ile çalışır.
* **Otomatik Yerel Ağ Keşfi (UDP Beacon):** IP adresi girmeye gerek kalmadan, UDP yayını sayesinde oyuncular yalnızca 4 haneli oda kodunu girerek lobiye otomatik bağlanır.
* **Gelişmiş SQLite Veritabanı:** Transfermarkt verilerinden optimize edilmiş 750+ kulüp, 50.000'e yakın detaylı oyuncu ve vatandaşlık verisi cihazda yerel olarak saklanır.
* **Garantili Rastgele Mod:** Rastgele modda veritabanında en az bir ortak oyuncusu bulunduğu kesin olan kulüp-kulüp veya ülke-kulüp eşleşmeleri getirilir; imkansız senaryolar engellenir.
* **Dinamik Autocomplete Arama:** Seçmeli modda oyuncular takımları ve ülkeleri harf hatası riski olmadan yerel SQLite üzerinden arayarak kilitler.
* **Benjamin (Buzzer) ve Dairesel Geri Sayım:** Cevap hakkını ilk kapan oyuncu için geri sayan dairesel süre göstergesi.
* **Hakem (Admin) Kontrol İstasyonu:**
  * **Kaza Önleyici Onay:** Yanlışlıkla dokunmaları önlemek için 1 saniye basılı tutularak onaylanan "Doğru (+1)" ve "Yanlış" butonları.
  * **Milisaniyelik Canlı Doğrulama:** Hakem oyuncunun söylediği ismi yazdığı anda SQLite üzerinden anlık ortaklık ve vatandaşlık sorgusu.
  * **Gizli İpucu Paneli:** Tıkanılan turlarda eşleşmeye ait tüm geçerli futbolcuları listeleyen hakem konsolu.
* **Sarı ve Kırmızı Kart Kuralı:** Bir maç serisinde daha önce kullanılmış bir kulübü veya ülkeyi tekrar seçen oyuncu doğrudan sarı kart görür ve turu kaybeder. 2 sarı kart alan oyuncu kırmızı kartla cezalandırılır ve rakibe +1 puan yazılır.

---

## Oyun Kuralları ve Mekanikleri

1. **Format ve Kural Ayarları (Admin):**
   * Hakem oda kurulumunda oyun formatını (Kulüp - Kulüp veya Ülke - Kulüp), hedef skoru, tur süresini, buzzer süresini ve seçim modunu belirler.
   * Ülke - Kulüp modu için "Bilemezse Ülke Seçimi Aynı Kişide Kalsın" kuralı açılıp kapatılabilir.
2. **Rol Dağılımı ve Seçim Aşaması:**
   * **Kulüp - Kulüp:** Her iki oyuncu da akıllarındaki kulüpleri aratarak kilitler.
   * **Ülke - Kulüp:** Sistem bir oyuncuya ülke, diğerine kulüp seçme rolü atar. Oyuncular kendi kutularından seçimlerini kilitler.
3. **3 - 2 - 1 Yansıtma:** Hakem "Yansıt" butonuna bastığında kural denetimi (sarı kart kontrolü) yapılır; ihlal yoksa 3 saniyelik geri sayımın ardından eşleşme her iki ekrana yansır.
4. **Benjamin (Buzzer) ve Cevaplama:** Eşleşmeyi gören oyunculardan cevabı ilk hatırlayan butona basar. Konuşma süresi içinde ismi söyler.
5. **Sıra Devir Mantığı (Ülke - Kulüp Modu):**
   * Cevap doğru bilinirse ülke seçme sırası kesin olarak el değiştirir.
   * Pas geçilirse veya süre biterse; admin ayarındaki kural açıksa ülke seçme hakkı aynı oyuncuda kalır, kapalıysa diğer oyuncuya devreder.
6. **Şampiyonluk ve Maç Sıfırlama:** Hedef skora ilk ulaşan maçı kazanır. Hakem "Yeni Maç Başlat" dediğinde skorlar, kartlar, kulüp hafızası ve ülke hafızası tamamen sıfırlanarak lobi dağılmadan yeni seri başlar.

---

## Teknoloji Yığını

* **Frontend:** Flutter & Dart
* **State Management:** Provider
* **Yerel İletişim:** `dart:io` WebSocket & UDP Multicast Sockets
* **Veritabanı:** SQLite (`sqflite`), SQL İndeksleri
* **Veri Hazırlama & Güncelleme:** Python (Pandas, SQLite3)

---

## Proje Mimarisi

```text
futbol_321/
├── assets/
│   ├── football.db               # Kulüp, oyuncu ve vatandaşlık SQLite veritabanı
│   └── icon/
│       └── app_icon.png          # Uygulama simgesi
├── scripts/
│   ├── build_db.py               # Transfermarkt CSV'lerini SQLite DB'ye dönüştüren script
│   ├── update_db_country.py      # Oyuncu vatandaşlıklarını DB'ye ekleyen güncelleme scripti
│   └── (players.csv, clubs.csv   # Ham veri setleri - .gitignore ile hariç tutulur)
└── lib/
    ├── core/
    │   ├── database/
    │   │   └── db_helper.dart    # Kesişim, vatandaşlık, arama ve rastgele mod sorguları
    │   └── network/
    │       ├── socket_server.dart# Admin WebSocket sunucusu ve UDP Beacon yayını
    │       └── socket_client.dart# Oyuncu istemcisi ve otomatik oda keşif dinleyicisi
    ├── models/
    │   ├── club.dart             # Kulüp veri modeli
    │   ├── player.dart           # Futbolcu veri modeli
    │   ├── game_event.dart       # Ağ iletişim protokolü ve mesaj tipleri
    │   └── game_state.dart       # Lobi, format, roller, kartlar ve tur durumu modeli
    ├── providers/
    │   └── game_provider.dart    # Oyun motoru, sayaçlar, kart ve rol geçiş kuralları
    ├── screens/
    │   ├── home_screen.dart      # Giriş ve mod seçim ekranı
    │   ├── admin_setup_screen.dart # Format seçimi, süre/kural ayarları ve lobi
    │   ├── admin_game_screen.dart# Hakem onay, canlı doğrulama ve ipucu paneli
    │   └── player_game_screen.dart# Skor paneli, ülke/takım seçimi ve buzzer ekranı
    └── main.dart                 # Uygulama başlangıç yapılandırması