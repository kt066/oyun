// Yıldız Souls: çevrimdışı çalışma. Yalnızca oyunun kendi dosyaları önbelleğe alınır.
const SURUM = 'yildiz-souls-v4';
const DOSYALAR = ['./', './index.html', './manifest.webmanifest', './icon-180.png', './icon-192.png', './icon-512.png'];
const IZINLI = new Set(DOSYALAR.map(f => new URL(f, self.registration.scope).pathname));

self.addEventListener('install', e => {
  e.waitUntil(caches.open(SURUM).then(c => c.addAll(DOSYALAR)).then(() => self.skipWaiting()));
});
self.addEventListener('activate', e => {
  e.waitUntil(caches.keys()
    .then(ks => Promise.all(ks.filter(k => k.startsWith('yildiz-souls-') && k !== SURUM).map(k => caches.delete(k))))
    .then(() => self.clients.claim()));
});
self.addEventListener('fetch', e => {
  const r = e.request, u = new URL(r.url);
  // Başka sitelere, GET dışı isteklere ve listede olmayan dosyalara karışma.
  if (r.method !== 'GET' || u.origin !== location.origin || !IZINLI.has(u.pathname)) return;
  const anahtar = u.pathname.endsWith('/') ? './' : '.' + u.pathname.slice(u.pathname.lastIndexOf('/'));
  e.respondWith(caches.open(SURUM).then(async c => {
    const eski = await c.match(anahtar);
    const yeni = fetch(r, { cache: 'no-cache' }).then(res => {
      if (res && res.ok && res.type === 'basic') c.put(anahtar, res.clone());
      return res;
    }).catch(() => eski || new Response('Çevrimdışı', { status: 503, headers: { 'Content-Type': 'text/plain; charset=utf-8' } }));
    return eski || yeni;
  }));
});
