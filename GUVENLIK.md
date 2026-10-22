# Yıldız Souls: Güvenlik İncelemesi

İnceleme tarihi: 22 Ekim 2026 (iki tur). Kapsam: oyun kodu (web, mobil uygulama ve ana ekran web uygulaması sürümleri), çevrimdışı önbellek dosyası, Capacitor yapılandırması, yerel Android/iOS ayarları ve bulut derleme dosyaları (GitHub Actions, Codemagic).

## Genel durum

Oyun tamamen cihazda çalışıyor. Sunucu, hesap sistemi, ödeme, reklam ya da internet bağlantısı yok. Ekrana gelen her şey `<canvas>` üzerine çiziliyor, yani sayfaya HTML enjekte edilebilecek bir yol bulunmuyor. Bu yüzden saldırı yüzeyi çok küçük. Bulunan sorunların çoğu "bozuk veya kurcalanmış kayıt dosyası oyunu kilitler" türünden.

## Kod taraması

| Kontrol | Sonuç |
|---|---|
| `innerHTML`, `outerHTML`, `insertAdjacentHTML`, `document.write` | Yok |
| `eval`, `new Function`, metin içeren `setTimeout` | Yok |
| Dış kaynaktan kod/stil/görsel yükleme | Yok |
| Ağ istekleri (`fetch`, `XMLHttpRequest`, `WebSocket`) | Yok |
| `postMessage` / pencereler arası mesaj dinleme | Yok |
| URL parametresi veya `location` okuma | Yok |
| Kayıtlı veri okuma (`JSON.parse`) | **Vardı, doğrulamasızdı → düzeltildi** |

## Bulunan ve kapatılan sorunlar

| # | Sorun | Risk | Yapılan düzeltme |
|---|---|---|---|
| 1 | **Prototip kirletme (prototype pollution).** Ayar ve istatistik kayıtları `Object.assign(hedef, JSON.parse(...))` ile yükleniyordu. Kayıtta `"__proto__"` anahtarı olursa nesnenin prototipi değişebiliyordu. | Orta | Kayıtlar artık alan alan, izin verilen anahtar listesiyle okunuyor. `Object.assign` ile ham veri birleştirme kaldırıldı. Testte `__proto__` içeren kayıt hiçbir nesneyi etkilemedi. |
| 2 | **Doğrulanmamış kayıt verisi oyunu çökertebiliyordu.** Örneğin zorluk değeri 9 olursa menü çiziminde hata oluşup oyun donuyordu; bozuk dizi verisi de haritayı kilitliyordu. | Orta (hizmet kesintisi) | Her sayı aralığa sıkıştırılıyor (zorluk 0–2, özellik 0–10, bölüm 0–12 vb.). Sonsuz/NaN değerler reddediliyor. Diziler sabit uzunlukta yeniden kuruluyor. Tılsım adları bilinen listeyle karşılaştırılıyor. 20 KB'tan büyük kayıt okunmuyor. |
| 3 | **Yükleme hatası tüm betiği durduruyordu.** Açılışta kayıt yüklenirken oluşan bir hata, sonraki tanımları da çalıştırmıyordu. | Orta | Yükleme `try/catch` içine alındı; hata olursa oyun temiz kayıtla açılıyor. |
| 4 | **İçerik Güvenlik Politikası (CSP) yoktu.** | Düşük | Uygulama paketine katı bir CSP eklendi: dış alan adlarından betik, stil, görsel ve bağlantı yasak; `object`, `frame`, `base`, `form` kapalı. |
| 5 | **Her açılışta kayıt siliniyordu** (güvenlik değil, veri kaybı). | Yüksek (kullanıcı deneyimi) | Açılıştaki sıfırlama kaldırıldı. Tüm ilerleme tek bir doğrulanmış kayıtta tutuluyor. Mobilde ayrıca yerel depoya (`Preferences`) yansıtılıyor, çünkü iOS tarayıcı depolamasını yer darlığında silebilir. |
| 6 | Kullanılmayan eski diyalog dizileri koddaydı (gerçek marka adları içeriyordu). | Düşük | Silindi. |

## İkinci tur: yeni bulunan ve kapatılan sorunlar

| # | Sorun | Risk | Yapılan düzeltme |
|---|---|---|---|
| 7 | **Eski kayıt okuyucusu hâlâ koddaydı.** Açılışta eski `ys`/`ysv` kayıtları doğrulamasız okunuyordu. Değerler hemen üzerine yazıldığı için etkisi yoktu ama gereksiz bir giriş noktasıydı. | Düşük | Tamamen kaldırıldı. Tek giriş noktası artık doğrulamalı `zLoad`. |
| 8 | **Çevrimdışı önbellek her isteği saklıyordu.** Web uygulamasının önbellek dosyası (`sw.js`), aynı sitedeki herhangi bir adresi sınırsız biçimde önbelleğe alabiliyordu. Bu da depolama şişirmeye ve önbellek zehirlenmesine açıktı. | Orta | Yalnızca oyunun kendi 6 dosyası önbelleğe alınıyor. Hata ya da başka kaynaklı yanıtlar saklanmıyor. Eski önbellek sürümleri otomatik siliniyor. |
| 9 | **Web uygulamasında `'unsafe-inline'`.** | Orta | Web uygulaması sürümünde satır içi betik ve stil izni kaldırıldı; yalnızca SHA-256 parmak izi eşleşen kod çalışabiliyor (`default-src 'none'`). Mobil sürümde Capacitor köprüsü gerektirdiği için kaldı. |
| 10 | **Web uygulaması başka bir sitenin içine gömülebiliyordu** (tıklama hilesi / clickjacking). | Düşük | Çerçeve içinde açılırsa sayfa kendini gizliyor. |
| 11 | **GitHub derlemesinde yazma anahtarı paketlere açıktı.** `checkout` adımı GitHub anahtarını diskte bırakıyordu; `npm install` sırasında çalışan herhangi bir paket betiği bu anahtarla depoya yazabilirdi. | Yüksek | Anahtar diske yazılmıyor (`persist-credentials: false`). Derleme işi salt okunur. Yazma izni yalnızca derlemeden sonra çalışan, hiçbir paket kurmayan ayrı "yayınla" işinde. |
| 12 | **Hata ayıklama (debug) APK dağıtılacaktı.** Debug APK'lar USB ile bağlanan herkesin uygulama verisine erişmesine izin verir ve herkesin bildiği bir anahtarla imzalıdır. | Orta | Artık `release` derleniyor, `zipalign` + `apksigner` ile imzalanıyor. Kalıcı imza anahtarı GitHub gizli değişkeninde (secret) tutulacak. APK'nın SHA-256 özeti indirme sayfasında yayımlanıyor. |
| 13 | **Android FileProvider harici depolamanın tamamını kapsıyordu** (Capacitor şablon varsayılanı). | Düşük | `external-path` kaldırıldı; yalnızca uygulamanın geçici klasörü paylaşılabilir. |

## Test özeti

- **Bulanık test (fuzzing):** Üç sürüm × 60 tur. Rastgele bozuk JSON, `__proto__`/`constructor` anahtarları, NaN/sonsuz sayılar, 5000 karakterlik metinler, yanlış tipler. **0 hata**, prototip kirlenmesi yok, bütün değerler sınır içinde.
- **İçerik Güvenlik Politikası:** Katı politikada konsolda ihlal yok. Oyun, dokunmatik ve çevrimdışı mod çalışıyor.
- **Önbellek:** Gelişigüzel adres istendiğinde önbellek büyümüyor (6 dosya sabit).
- **Çerçeve içinde açma:** Sayfa gizleniyor.
- **Dokunmatik kontroller:** Çoklu dokunuş, butonlar, yanlışlıkla tetiklenme ve sol el modu test edildi.

## Yerel uygulama sertleştirmesi

`capacitor.config.json` ve `scripts/native-ayarlar.js` ile uygulanır:

- WebView hata ayıklama kapalı (`webContentsDebuggingEnabled: false`, iOS ve Android).
- Karışık içerik (`allowMixedContent`) ve düz HTTP (`usesCleartextTraffic`, `cleartext`) kapalı.
- Android `allowBackup="false"`. Kayıt bulut yedeğinden çekilip değiştirilemez; bunun karşılığında telefon değişince ilerleme taşınmaz. İstersen ileride açılabilir.
- iOS `ITSAppUsesNonExemptEncryption = false`. Uygulama kendi şifrelemesini kullanmıyor; ihracat beyanı sorusu otomatik geçer.
- Konsol kaydı kapalı (`loggingBehavior: none`).
- Kamera, mikrofon, konum gibi hiçbir izin istenmiyor.
- `.gitignore`, keystore dosyalarının yanlışlıkla depoya gönderilmesini engelliyor.

## Bilinçli olarak açık bırakılanlar

- **Kayıt düzenleme (hile):** Telefonuna erişimi olan biri kendi kaydını değiştirebilir. Tek oyunculu ve çevrimdışı bir oyunda bu bir güvenlik açığı değil, başkasına zarar vermiyor. İleride **çevrimiçi skor tablosu veya uygulama içi satın alma** eklenirse, skorlar ve satın almalar mutlaka sunucu tarafında doğrulanmalı.
- **Mobil sürümde `'unsafe-inline'` betik izni:** Capacitor köprüsü Android'de sayfaya satır içi betik eklediği için gerekli. Sayfada HTML enjeksiyonu yapılabilecek bir yer olmadığından risk düşük.
- **npm paket sürümleri kilitli değil:** Bu ortamdan paket deposuna erişilemediği için kilit dosyası (`package-lock.json`) üretilemedi. İlk `npm install` sonrasında oluşan kilit dosyasını depoya ekle; derleme o andan itibaren hep aynı sürümleri kullanır.
- **GitHub Actions sürümleri etiketle sabitli (`@v4`):** Daha sıkı güvenlik için ileride commit SHA'sına sabitlenebilir.
- **Android INTERNET izni:** Capacitor şablonunda varsayılan olarak var. Oyun internete çıkmıyor; kaldırmak bazı cihazlarda WebView'ın yerel dosyaları yüklemesini bozabildiği için bırakıldı.

## Doğrulama

- Bozuk ve kötü niyetli kayıtlarla açılış testi yapıldı (`__proto__`, NaN, sonsuz sayı, yanlış tipler, aşırı büyük değerler, bozuk JSON). Oyun her durumda açıldı, prototipler temiz kaldı.
- Kayıt kalıcılığı, dokunmatik kontroller, arka plana alınınca duraklama ve dikey ekran uyarısı tarayıcıda telefon boyutunda test edildi.
- CSP altında konsol hatası yok.
