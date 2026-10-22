# Mac olmadan iPhone'a gerçek uygulama olarak yükleme (TestFlight)

Uygulamayı Apple'ın bulutundaki bir Mac derler, TestFlight'a yükler; sen de iPhone'daki TestFlight uygulamasından kurarsın. Oyun ana ekranda normal bir uygulama gibi durur. Mağazada herkese açık yayınlanmaz.

## Gerekenler
- **Apple Developer Program** üyeliği: yıllık 99 USD. Mac olmadan iPhone'a uygulama yüklemenin resmi yolu bu.
- **GitHub** hesabı (ücretsiz): Codemagic projeyi buradan alıyor.
- **Codemagic** hesabı (ücretsiz plan: ayda 500 dakika macOS derleme).
- iPhone'da **TestFlight** uygulaması (App Store'dan ücretsiz).

## Adımlar

1. **Apple Developer'a kaydol.** developer.apple.com/programs adresinden iPhone'unla kaydolabilirsin. Onay birkaç saat ile 2 gün sürebilir.

2. **App Store Connect'te uygulama kaydı oluştur.** appstoreconnect.apple.com → Uygulamalar → **+** → Yeni Uygulama.
   - Platform: iOS. Ad: Yıldız Souls. Dil: Türkçe.
   - Paket Kimliği (Bundle ID): `com.yildizsouls.oyun`. Listede yoksa önce developer.apple.com → Identifiers bölümünden ekle.
   - Oluşunca **Genel Bilgiler** sayfasındaki 10 haneli **Apple ID** numarasını not al.

3. **API anahtarı oluştur.** App Store Connect → Kullanıcılar ve Erişim → **Entegrasyonlar** → App Store Connect API → Anahtar oluştur, rol: **App Manager**. `.p8` dosyasını indir (tek seferlik indirilebilir), Issuer ID ve Key ID'yi not al.

4. **Projeyi GitHub'a koy.** Bu klasörün tamamını yeni bir GitHub deposuna yükle (`node_modules` hariç).

5. **Codemagic'i ayarla.** codemagic.io → GitHub ile giriş → **Add application** → depoyu seç.
   - Team/Personal settings → **Integrations → Developer Portal** → Manage keys → API anahtarını ekle. Adı: `YildizSoulsKey`, ardından Issuer ID, Key ID ve `.p8` dosyası.
   - `codemagic.yaml` içindeki `APP_STORE_APPLE_ID` değerini 2. adımdaki numarayla değiştir.

6. **Derlemeyi başlat.** Codemagic → **Start new build** → `ios-testflight`. Yaklaşık 15–25 dakika sürer. Bittiğinde uygulama App Store Connect'e yüklenir; Apple'ın işlemesi 10–30 dakika daha alabilir.

7. **iPhone'a kur.** App Store Connect → Uygulama → **TestFlight** → Dahili Test → kendini test kullanıcısı olarak ekle. Telefona gelen davetten TestFlight'ı aç → **Yükle**.

## Bilmen gerekenler
- Dahili testte Apple incelemesi yok. 100 kişiye kadar ekip üyesi ekleyebilirsin.
- Her TestFlight derlemesi **90 gün** çalışır. Sonra yeni derleme başlatman gerekir (6. adım).
- Oyunu güncellemek için `www/index.html` dosyasını değiştirip GitHub'a yükle ve 6. adımı tekrarla.

---

# Android telefona APK olarak yükleme (ücretsiz, Apple/Google hesabı gerekmez)

APK yalnızca **Android** telefonlarda çalışır; iPhone'a kurulamaz.

1. Projeyi GitHub'a koy ve Codemagic'e GitHub ile gir (yukarıdaki 4. ve 5. adımın ilk kısmı; Apple anahtarı gerekmez).
2. Codemagic → **Start new build** → `android-apk`. Yaklaşık 10 dakika sürer.
3. Bittiğinde **Artifacts** bölümünden `app-debug.apk` dosyasını Android telefona indir.
4. Dosyaya dokun. "Bilinmeyen kaynaklardan yüklemeye izin ver" uyarısı çıkarsa izin ver → **Yükle**.

Bu sürüm test amaçlıdır ve hata ayıklama anahtarıyla imzalanır. Google Play'e yüklemek için `KURULUM.md` içindeki imzalı `.aab` adımlarını izle.
