// Yıldız Souls — "npx cap add android/ios" sonrasında yerel ayarları uygular.
// Tekrar çalıştırmak güvenlidir. Ek paket gerektirmez.
const fs = require('fs');
const path = require('path');
const kok = path.join(__dirname, '..');
let degisti = 0;
const yaz = (f, s) => { fs.writeFileSync(f, s); degisti++; console.log('  güncellendi:', path.relative(kok, f)); };

// ---------- ANDROID ----------
const manifest = path.join(kok, 'android/app/src/main/AndroidManifest.xml');
if (fs.existsSync(manifest)) {
  console.log('Android:');
  let m = fs.readFileSync(manifest, 'utf8');
  const once = m;
  // Yatay ekran kilidi
  m = m.replace(/(<activity\b[^>]*?android:name="\.?MainActivity"[^>]*?)(\s*>)/s, (all, a, b) =>
    /screenOrientation/.test(a) ? all : `${a}\n            android:screenOrientation="sensorLandscape"${b}`);
  // Yedekleme kapalı, düz HTTP kapalı
  m = m.replace(/android:allowBackup="true"/, 'android:allowBackup="false"');
  if (!/usesCleartextTraffic/.test(m)) m = m.replace(/<application\b/, '<application\n        android:usesCleartextTraffic="false"');
  if (m !== once) yaz(manifest, m);

  // FileProvider: yalnızca uygulamanın geçici klasörü paylaşılabilsin (harici depolamanın tamamı değil)
  const fp = path.join(kok, 'android/app/src/main/res/xml/file_paths.xml');
  if (fs.existsSync(fp)) {
    const f = fs.readFileSync(fp, 'utf8');
    const g = f.replace(/\s*<external-path\b[^>]*\/>/g, '');
    if (g !== f) yaz(fp, g);
  }

  // Tam ekran (durum ve gezinme çubukları gizli)
  const javaKok = path.join(kok, 'android/app/src/main/java');
  const bul = d => fs.readdirSync(d, { withFileTypes: true }).flatMap(e => e.isDirectory() ? bul(path.join(d, e.name)) : [path.join(d, e.name)]);
  const ma = fs.existsSync(javaKok) && bul(javaKok).find(f => /MainActivity\.(java|kt)$/.test(f));
  if (ma && ma.endsWith('.java')) {
    const s = fs.readFileSync(ma, 'utf8');
    if (!/WindowInsetsControllerCompat/.test(s)) {
      const pkg = (s.match(/^package\s+([\w.]+);/m) || [])[1];
      yaz(ma, `package ${pkg};

import androidx.core.view.WindowCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.core.view.WindowInsetsControllerCompat;
import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {
    @Override
    public void onResume() {
        super.onResume();
        tamEkran();
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        if (hasFocus) tamEkran();
    }

    private void tamEkran() {
        WindowCompat.setDecorFitsSystemWindows(getWindow(), false);
        WindowInsetsControllerCompat c = WindowCompat.getInsetsController(getWindow(), getWindow().getDecorView());
        c.hide(WindowInsetsCompat.Type.systemBars());
        c.setSystemBarsBehavior(WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE);
    }
}
`);
    }
  }
} else console.log('Android klasörü yok, atlandı (önce: npx cap add android)');

// ---------- iOS ----------
const plist = path.join(kok, 'ios/App/App/Info.plist');
if (fs.existsSync(plist)) {
  console.log('iOS:');
  let p = fs.readFileSync(plist, 'utf8');
  const once = p;
  const yatay = '<array>\n\t\t<string>UIInterfaceOrientationLandscapeLeft</string>\n\t\t<string>UIInterfaceOrientationLandscapeRight</string>\n\t</array>';
  for (const k of ['UISupportedInterfaceOrientations', 'UISupportedInterfaceOrientations~ipad']) {
    const re = new RegExp(`(<key>${k.replace('~', '\\~')}</key>\\s*)<array>[\\s\\S]*?</array>`);
    if (re.test(p)) p = p.replace(re, `$1${yatay}`);
    else p = p.replace(/<\/dict>\s*<\/plist>\s*$/, `\t<key>${k}</key>\n\t${yatay}\n</dict>\n</plist>\n`);
  }
  const ekle = (k, v) => {
    const re = new RegExp(`<key>${k}</key>\\s*<(true|false)\\s*/>`);
    if (re.test(p)) p = p.replace(re, `<key>${k}</key>\n\t<${v}/>`);
    else p = p.replace(/<\/dict>\s*<\/plist>\s*$/, `\t<key>${k}</key>\n\t<${v}/>\n</dict>\n</plist>\n`);
  };
  ekle('UIRequiresFullScreen', 'true');
  ekle('UIStatusBarHidden', 'true');
  ekle('UIViewControllerBasedStatusBarAppearance', 'false');
  ekle('ITSAppUsesNonExemptEncryption', 'false');
  if (p !== once) yaz(plist, p);
} else console.log('iOS klasörü yok, atlandı (önce: npx cap add ios)');

console.log(degisti ? `Tamam: ${degisti} dosya güncellendi.` : 'Değişiklik gerekmedi.');
