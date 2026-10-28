self.addEventListener("install", () => {
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    (async () => {
      const names = await caches.keys();

      await Promise.all(
        names
          .filter((name) => name.startsWith("workbox-precache-"))
          .map((name) => caches.delete(name)),
      );
      await self.clients.claim();
      const clients = await self.clients.matchAll({ type: "window" });

      await self.registration.unregister();
      await Promise.all(clients.map((client) => client.navigate(client.url)));
    })(),
  );
});
