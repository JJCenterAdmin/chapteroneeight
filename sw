const CACHE = 'c18-v2';
const ASSETS = [
  '/',
  '/index.html',
  '/c18-sword.html',
  '/c18-resources.html',
  '/c18-icon.png',
  '/manifest.json'
];

// Install — cache all assets
self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE).then(cache => cache.addAll(ASSETS))
  );
  // Take over immediately without waiting
  self.skipWaiting();
});

// Activate — delete old caches immediately
self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE).map(k => {
        console.log('C18 SW: deleting old cache', k);
        return caches.delete(k);
      }))
    )
  );
  // Take control of all open tabs immediately
  self.clients.claim();
});

// Fetch — network first, fall back to cache
// This means users always get the latest version when online
self.addEventListener('fetch', e => {
  e.respondWith(
    fetch(e.request)
      .then(response => {
        // Got fresh response from network — update the cache
        const clone = response.clone();
        caches.open(CACHE).then(cache => cache.put(e.request, clone));
        return response;
      })
      .catch(() => {
        // Network failed — serve from cache (offline mode)
        return caches.match(e.request).then(cached => {
          return cached || caches.match('/index.html');
        });
      })
  );
});

// Listen for skip waiting message from main thread
self.addEventListener('message', e => {
  if(e.data === 'skipWaiting') self.skipWaiting();
});
