// バージョンを上げるとキャッシュが更新されます（更新時は必ず数字を変える）
const CACHE = "kiss-otoshi-v14";
const ASSETS = [
  "./","./index.html","./manifest.json",
  "./kiss1.png","./kiss2.png","./kiss3.png","./kiss4.png","./kiss5.png",
  "./kiss6.png","./kiss7.png","./kiss8.png","./kiss9.png","./kiss10.png","./fever.png",
  "./icon-192.png","./icon-512.png","./apple-touch-icon.png"
];

self.addEventListener("install", e=>{
  self.skipWaiting();
  e.waitUntil(caches.open(CACHE).then(c=>c.addAll(ASSETS).catch(()=>{})));
});

self.addEventListener("activate", e=>{
  e.waitUntil(
    caches.keys().then(keys=>Promise.all(keys.filter(k=>k!==CACHE).map(k=>caches.delete(k))))
      .then(()=>self.clients.claim())
  );
});

self.addEventListener("fetch", e=>{
  const url = new URL(e.request.url);
  // 外部（CDN / Supabase / fonts）はネットワーク優先
  if(url.origin !== self.location.origin){ return; }
  e.respondWith(
    caches.match(e.request).then(r=> r || fetch(e.request))
  );
});
