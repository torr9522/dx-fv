import ReactDOM from "react-dom/client";
import { BrowserRouter } from "react-router-dom";

import App from "./App.tsx";
import { Provider } from "./provider.tsx";
import "@/styles/globals.css";

window.__DX_FV_BUILD__ = __DX_FV_BUILD__;
console.info(`DX-FV build: ${__DX_FV_BUILD__}`);

const removeLegacyPwaState = async () => {
  if ("serviceWorker" in navigator) {
    const registrations = await navigator.serviceWorker.getRegistrations();

    await Promise.all(
      registrations
        .filter((registration) => registration.scope === `${location.origin}/`)
        .map((registration) => registration.unregister()),
    );
  }

  if ("caches" in window) {
    const names = await caches.keys();

    await Promise.all(
      names
        .filter((name) => name.startsWith("workbox-precache-"))
        .map((name) => caches.delete(name)),
    );
  }
};

void removeLegacyPwaState().catch((error: unknown) => {
  console.warn("Legacy PWA cleanup failed", error);
});

ReactDOM.createRoot(document.getElementById("root")!).render(
  <BrowserRouter>
    <Provider>
      <App />
    </Provider>
  </BrowserRouter>,
);
