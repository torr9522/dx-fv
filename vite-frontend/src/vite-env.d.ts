/// <reference types="vite/client" />

declare const __DX_FV_BUILD__: string;

interface Window {
  __DX_FV_BUILD__?: string;
}

interface ImportMetaEnv {
  readonly VITE_API_BASE?: string;
  readonly VITE_APP_VERSION?: string;
  readonly VITE_GITHUB_REPO?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
