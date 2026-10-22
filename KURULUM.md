# Yıldız Souls: iOS ve Android'e Çıkış Rehberi

Bu klasör, oyunu App Store ve Google Play'e çıkarmak için hazırlanmış bir **Capacitor 8** projesidir. Oyunun kendisi `www/index.html` dosyasında. Capacitor bu sayfayı gerçek bir iOS ve Android uygulamasının içine yerleştirir.

## 1. Neler gerekiyor

| | Android | iOS |
|---|---|---|
| Bilgisayar | Windows, Mac veya Linux | **Mac zorunlu** |
| Yazılım | Node.js 22+, Android Studio Otter (2025.2.1) veya üstü | Node.js 22+, Xcode 26 veya üstü |
| Hesap | Google Play Console (tek seferlik kayıt ücreti) | Apple Developer Program (yıllık 99 USD) |
| Test cihazı | Herhangi bir Android telefon | iPhone (TestFlight ile) |

## 2. Projeyi kur (tek komut)

Klasörü aç ve terminalde şunu çalıştır:

```bash
npm run kurulum
```

Bu komut sırasıyla şunları yapar:

1. Paketleri indirir.
2. `android/` ve `ios/` klasörlerini oluşturur.
3. `scripts/native-ayarlar.js` ile yerel ayarları uygular: yatay ekran kilidi, tam ekran, durum çubuğu gizleme, düz HTTP kapalı, yedekleme kapalı, şifreleme beyanı.
4. `assets/` klasöründeki görsellerden bütün ikon ve açılış ekranı boyutlarını üretir.
5. Oyunu iki platforma kopyalar.

iOS klasörü yalnızca Mac'te tam çalışır. Windows'ta komut iOS adımında hata verirse sorun değil; Android tarafı yine hazır olur.

> **Önemli:** `capacitor.config.json` içindeki `appId` değeri (`com.yildizsouls.oyun`) mağazaya ilk yüklemeden sonra **bir daha değiştirilemez**. Kendine ait bir alan adın varsa (`com.seninadin.yildizsouls` gibi), `npm run kurulum` çalıştırmadan önce burayı değiştir.

## 3. Android: Google Play

1. `npm run android` komutuyla Android Studio'yu aç.
2. Telefonu USB ile bağla (Geliştirici seçenekleri → USB hata ayıklama açık) ve ▶ ile çalıştırıp oyunu dene.
3. **Build → Generate Signed App Bundle** menüsünden `.aab` dosyası üret.
   - İlk seferde yeni bir anahtar deposu (keystore) oluşturulacak. **Bu dosyayı ve şifresini kaybetme**; güncellemeleri imzalamak için her zaman lazım. Bulut yedeğine koy, projeye ve Git'e koyma.
   - Play Console'da "Play Uygulama İmzalama" açık kalsın; anahtarın bir kopyasını Google da saklar.
4. Play Console'da yeni uygulama oluştur ve `magaza/MAGAZA.md` dosyasındaki metinleri, `magaza/` klasöründeki görselleri yükle.
5. **Yeni kişisel hesaplar için kural:** Üretim yayınına geçmeden önce kapalı test yapılması zorunlu. En az **12 test kullanıcısı**, **14 gün boyunca kesintisiz** teste kayıtlı kalmalı. Arkadaş ve aileden 12 kişilik bir liste hazırla. Şirket hesabıyla açarsan bu kural uygulanmaz.
6. Google Play Ağustos 2026'dan beri yeni uygulamalarda **API 36 (Android 16)** hedefini zorunlu tutuyor. Capacitor 8 bunu varsayılan olarak karşılıyor, ek bir şey yapman gerekmiyor.

## 4. iOS: App Store (Mac'te)

1. `npm run ios` komutuyla Xcode'u aç.
2. **App** hedefi → **Signing & Capabilities** bölümünde Apple Developer hesabını (Team) seç. Bundle Identifier, `appId` ile aynı olmalı.
3. Bir iPhone bağlayıp ▶ ile dene.
4. **Product → Archive**, ardından **Distribute App → App Store Connect** ile yükle.
5. App Store Connect'te TestFlight ile birkaç kişiye denet, sonra `magaza/MAGAZA.md` dosyasındaki bilgileri doldurup incelemeye gönder.

## 5. Oyunu güncellemek

1. `www/index.html` dosyasını yeni sürümle değiştir.
2. `npm run esitle` komutunu çalıştır.
3. Sürüm numarasını artır:
   - **Android:** `android/app/build.gradle` → `versionCode` (her yüklemede +1) ve `versionName`.
   - **iOS:** Xcode → App → General → Version ve Build.
4. Yeniden imzalayıp yükle.

## 6. Kayıtlar nasıl saklanıyor

İlerleme, telefonun kendi deposunda tutuluyor (`@capacitor/preferences` eklentisi ve WebView depolaması birlikte). İnternet bağlantısı, hesap ya da sunucu yok. Uygulama silinirse kayıt da silinir; Android'de yedekleme bilinçli olarak kapalı (bkz. `GUVENLIK.md`).

## 7. Mağazaya çıkmadan önce kontrol listesi

- [ ] İsim kontrolü: "Souls" kelimesi için `MAGAZA.md` içindeki marka notunu oku.
- [ ] `magaza/gizlilik.html` dosyasına iletişim e-postanı yaz ve herkese açık bir adreste yayınla (GitHub Pages, kendi siten vb.). Her iki mağaza da gizlilik politikası adresi istiyor.
- [ ] Gerçek bir telefonda en az bir bölümü baştan sona oyna; dokunmatik kontrolleri ve ses seviyesini dene.
- [ ] Keystore'u yedekle.
- [ ] Android'de 12 kişilik kapalı test listesini hazırla.
