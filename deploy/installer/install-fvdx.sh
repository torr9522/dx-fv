#!/usr/bin/env bash
set -Eeuo pipefail

readonly FLVX_RELEASE_BASE_URL="${FLVX_RELEASE_BASE_URL:-https://github.com/torr9522/dx-fv/releases/download}"
readonly FLVX_RELEASE_VERSION="${FLVX_RELEASE_VERSION:-v1.0.1}"
readonly FLVX_ALLOW_INSECURE_DOWNLOADS="${FLVX_ALLOW_INSECURE_DOWNLOADS:-0}"
readonly FLVX_INSTALL_PREFIX="${FLVX_INSTALL_PREFIX:-}"
readonly BACKEND_PORT="${FLVX_BACKEND_PORT:-6365}"

readonly OPT_ROOT="${FLVX_INSTALL_PREFIX}/opt/flvx"
readonly ETC_ROOT="${FLVX_INSTALL_PREFIX}/etc/flvx"
readonly DATA_ROOT="${FLVX_INSTALL_PREFIX}/var/lib/flvx"
readonly LOG_ROOT="${FLVX_INSTALL_PREFIX}/var/log/flvx"
readonly SYSTEMD_ROOT="${FLVX_INSTALL_PREFIX}/etc/systemd/system"
readonly CADDY_ROOT="${FLVX_INSTALL_PREFIX}/etc/caddy"
readonly STATE_FILE="$ETC_ROOT/install-state"
readonly CREDENTIAL_FILE="${FLVX_INSTALL_PREFIX}/root/flvx-install-credentials.txt"
readonly DB_PATH="$DATA_ROOT/flvx.db"

temp_dir=""
install_started=0
install_finished=0
domain="${FLVX_DOMAIN:-}"
proxy_mode="${FLVX_PROXY_MODE:-}"
credential_mode="${FLVX_CREDENTIAL_MODE:-}"
admin_username=""
admin_password=""

say() { printf '%s\n' "$*"; }
die() { printf '错误：%s\n' "$*" >&2; exit 1; }

cleanup() {
  local status=$?
  if [[ -n "$temp_dir" && -d "$temp_dir" ]]; then
    find "$temp_dir" -depth -delete 2>/dev/null || true
  fi
  if ((status != 0 && install_started == 1 && install_finished == 0)); then
    printf '安装未完成。已保留错误现场；不会自动覆盖或重置数据库。\n' >&2
  fi
}
trap cleanup EXIT

require_root() {
  [[ ${EUID:-$(id -u)} -eq 0 ]] || die "请使用 root 用户执行安装器。"
}

require_debian_12_amd64() {
  [[ -r /etc/os-release ]] || die "无法识别操作系统。"
  # shellcheck disable=SC1091
  . /etc/os-release
  [[ ${ID:-} == debian && ${VERSION_ID:-} == 12 ]] || die "仅支持 Debian 12。"
  [[ $(dpkg --print-architecture 2>/dev/null) == amd64 && $(uname -m) == x86_64 ]] ||
    die "仅支持 Debian 12 AMD64/x86_64。"
}

require_version_and_source() {
  [[ $FLVX_RELEASE_VERSION =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$ ]] ||
    die "请设置合法的 FLVX_RELEASE_VERSION。"
  [[ $FLVX_RELEASE_BASE_URL == https://* || $FLVX_RELEASE_BASE_URL == http://* ]] ||
    die "FLVX_RELEASE_BASE_URL 必须是 HTTP(S) 地址。"
  if [[ $FLVX_RELEASE_BASE_URL == http://* && $FLVX_ALLOW_INSECURE_DOWNLOADS != 1 ]]; then
    die "HTTP 下载源仅允许在显式设置 FLVX_ALLOW_INSECURE_DOWNLOADS=1 的 staging 测试中使用。"
  fi
}

require_runtime_tools() {
  local tool
  for tool in bash curl awk sed grep getent sha256sum tar ss df findmnt install mktemp; do
    command -v "$tool" >/dev/null 2>&1 || die "系统缺少必要命令：$tool"
  done
}

check_disk_space() {
  local available_kib
  available_kib=$(df -Pk / | awk 'NR==2 {print $4}')
  [[ $available_kib =~ ^[0-9]+$ && $available_kib -ge 1048576 ]] ||
    die "根分区至少需要 1 GiB 可用空间。"
}

check_existing_install() {
  local path
  for path in "$STATE_FILE" "$DB_PATH" "$OPT_ROOT/current" "$SYSTEMD_ROOT/flvx.service"; do
    [[ ! -e "$path" && ! -L "$path" ]] ||
      die "检测到已有 FV 安装（$path）。本安装器不会覆盖，请使用升级或修复流程。"
  done
}

port_is_listening() {
  local port=$1
  ss -H -ltn "sport = :$port" 2>/dev/null | grep -q .
}

validate_domain() {
  local value=$1
  [[ ${#value} -le 253 ]] || return 1
  [[ $value =~ ^([A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?\.)+[A-Za-z]{2,63}$ ]] || return 1
  [[ $value != *..* ]]
}

open_tty() {
  [[ -r /dev/tty && -w /dev/tty ]] ||
    die "需要交互式终端。请在 SSH/控制台中执行 curl ... | bash。"
  exec 3<>/dev/tty
}

prompt_value() {
  local prompt=$1 result
  printf '%s' "$prompt" >&3
  IFS= read -r result <&3 || die "无法从交互式终端读取输入。"
  printf '%s' "$result"
}

collect_choices() {
  if [[ -z "$domain" || -z "$proxy_mode" || -z "$credential_mode" ]]; then
    open_tty
  fi

  while [[ -z "$domain" ]]; do
    domain=$(prompt_value "面板域名（例如 fv.example.com）：")
    validate_domain "$domain" || { say "域名格式无效，请重新输入。"; domain=""; }
  done
  validate_domain "$domain" || die "域名格式无效：$domain"

  if [[ -z "$proxy_mode" ]]; then
    say "反向代理方式："
    say "  1. FV 自动管理 Caddy（推荐）"
    say "  2. 使用已有反向代理（不修改现有站点）"
    case $(prompt_value "请选择 [1/2]：") in
      1) proxy_mode=caddy ;;
      2) proxy_mode=external ;;
      *) die "无效的反向代理选项。" ;;
    esac
  fi
  [[ $proxy_mode == caddy || $proxy_mode == external ]] || die "FLVX_PROXY_MODE 必须是 caddy 或 external。"

  if [[ -z "$credential_mode" ]]; then
    say "管理员初始化方式："
    say "  1. 随机生成并保存到 root 专用文件（推荐）"
    say "  2. 随机生成且仅在安装完成时显示一次"
    case $(prompt_value "请选择 [1/2]：") in
      1) credential_mode=save ;;
      2) credential_mode=display ;;
      *) die "无效的管理员初始化选项。" ;;
    esac
  fi
  [[ $credential_mode == save || $credential_mode == display ]] ||
    die "FLVX_CREDENTIAL_MODE 必须是 save 或 display。"
}

check_dns() {
  local resolved local_ips ip matched=0
  resolved=$(getent ahostsv4 "$domain" | awk '{print $1}' | sort -u)
  [[ -n "$resolved" ]] || die "域名 $domain 没有 A 记录。"
  local_ips=$(hostname -I 2>/dev/null || true)
  for ip in $resolved; do
    if [[ " $local_ips " == *" $ip "* ]]; then
      matched=1
      break
    fi
  done
  ((matched == 1)) || die "域名 $domain 的 A 记录未指向本机地址。"
}

check_ports() {
  port_is_listening "$BACKEND_PORT" && die "Backend 端口 $BACKEND_PORT 已被占用。"
  if [[ $proxy_mode == caddy ]]; then
    if port_is_listening 80 || port_is_listening 443; then
      if ! command -v caddy >/dev/null 2>&1 || ! systemctl is-active --quiet caddy; then
        die "80/443 端口已被非 Caddy 服务占用。"
      fi
      say "检测到运行中的 Caddy；安装器只会增加独立 FV 站点，不覆盖现有 Caddyfile。"
    fi
  fi
  if command -v nginx >/dev/null 2>&1; then
    say "检测到 Nginx。选择已有反向代理模式时，安装器不会修改其配置。"
  fi
}

download_artifacts() {
  local release_url manifest filename
  temp_dir=$(mktemp -d /tmp/flvx-installer.XXXXXX)
  chmod 700 "$temp_dir"
  release_url="${FLVX_RELEASE_BASE_URL%/}/$FLVX_RELEASE_VERSION"
  manifest="$temp_dir/manifest.sha256"

  say "下载并校验 FV-DX $FLVX_RELEASE_VERSION ..."
  curl -fsSL --retry 3 --connect-timeout 10 "$release_url/manifest.sha256" -o "$manifest" ||
    die "下载 SHA256 manifest 失败。"
  [[ -s "$manifest" ]] || die "SHA256 manifest 为空。"

  local required=(flvx-paneld-linux-amd64 flvx-init-linux-amd64 frontend.tar.gz release-metadata.json)
  local listed
  listed=$(awk 'NF != 2 || length($1) != 64 || $1 !~ /^[0-9a-f]+$/ || $2 !~ /^[A-Za-z0-9._-]+$/ {bad=1} {print $2} END {if (bad) exit 1}' "$manifest") ||
    die "SHA256 manifest 格式无效。"
  for filename in "${required[@]}"; do
    grep -Fxq "$filename" <<<"$listed" || die "manifest 缺少 $filename。"
  done
  [[ $(wc -l < "$manifest") -eq ${#required[@]} ]] || die "manifest 包含非预期文件。"

  for filename in "${required[@]}"; do
    curl -fsSL --retry 3 --connect-timeout 10 "$release_url/$filename" -o "$temp_dir/$filename" ||
      die "下载 $filename 失败。"
  done
  (cd "$temp_dir" && sha256sum --strict -c manifest.sha256) >/dev/null ||
    die "构建产物 SHA256 校验失败。"

  tar -tzf "$temp_dir/frontend.tar.gz" | awk '
    /^\// || /(^|\/)\.\.($|\/)/ {bad=1}
    END {exit bad ? 1 : 0}
  ' || die "Frontend 压缩包包含不安全路径。"
  tar -tzf "$temp_dir/frontend.tar.gz" | awk '$0 == "./index.html" {found=1} END {exit found ? 0 : 1}' ||
    die "Frontend 压缩包缺少 index.html。"
}

install_dependencies() {
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
  apt-get install -y -qq ca-certificates curl openssl sqlite3 tar gzip
  if [[ $proxy_mode == caddy ]]; then
    apt-get install -y -qq caddy
  fi
}

generate_credentials() {
  admin_username="Admin_$(openssl rand -hex 5)"
  admin_password=$(openssl rand -base64 36 | tr -d '\n')
  [[ ${#admin_password} -ge 40 ]] || die "安全随机密码生成失败。"
}

install_files() {
  local release_dir frontend_dir
  release_dir="$OPT_ROOT/releases/$FLVX_RELEASE_VERSION"
  frontend_dir="$OPT_ROOT/frontend-releases/$FLVX_RELEASE_VERSION"
  [[ ! -e "$release_dir" && ! -e "$frontend_dir" ]] || die "版本目录已经存在。"

  getent group flvx >/dev/null 2>&1 || groupadd --system flvx
  id -u flvx >/dev/null 2>&1 || useradd --system --gid flvx --home-dir "$DATA_ROOT" --shell /usr/sbin/nologin flvx

  install -d -m 0755 "$OPT_ROOT/releases" "$OPT_ROOT/frontend-releases"
  install -d -m 0750 -o root -g flvx "$release_dir"
  install -m 0750 -o root -g flvx "$temp_dir/flvx-paneld-linux-amd64" "$release_dir/flvx-paneld"
  install -m 0750 -o root -g flvx "$temp_dir/flvx-init-linux-amd64" "$release_dir/flvx-init"
  install -m 0644 -o root -g root "$temp_dir/release-metadata.json" "$release_dir/release-metadata.json"

  install -d -m 0755 "$frontend_dir"
  tar -xzf "$temp_dir/frontend.tar.gz" -C "$frontend_dir" --strip-components=1
  [[ -s "$frontend_dir/index.html" ]] || die "Frontend 安装后缺少 index.html。"
  find "$frontend_dir" -type d -exec chmod 0755 {} +
  find "$frontend_dir" -type f -exec chmod 0644 {} +

  ln -sfn "$release_dir" "$OPT_ROOT/current.next"
  mv -Tf "$OPT_ROOT/current.next" "$OPT_ROOT/current"
  ln -sfn "$frontend_dir" "$OPT_ROOT/frontend-current.next"
  mv -Tf "$OPT_ROOT/frontend-current.next" "$OPT_ROOT/frontend-current"
}

initialize_database() {
  install -d -m 0750 -o flvx -g flvx "$DATA_ROOT" "$LOG_ROOT"
  runuser -u flvx -- env \
    FLVX_INIT_DB_PATH="$DB_PATH" \
    FLVX_INITIAL_ADMIN_USERNAME="$admin_username" \
    FLVX_INITIAL_ADMIN_PASSWORD="$admin_password" \
    "$OPT_ROOT/current/flvx-init" >/dev/null
  [[ $(stat -c '%a:%U:%G' "$DB_PATH") == 600:flvx:flvx ]] || die "数据库权限不安全。"
  [[ $(sqlite3 "$DB_PATH" 'PRAGMA integrity_check;') == ok ]] || die "SQLite integrity_check 失败。"
  [[ $(sqlite3 "$DB_PATH" 'SELECT version FROM schema_version LIMIT 1;') == 8 ]] || die "数据库未初始化到 schema 8。"
}

write_backend_config() {
  local jwt_secret
  jwt_secret=$(openssl rand -hex 48)
  install -d -m 0750 -o root -g flvx "$ETC_ROOT"
  umask 077
  {
    printf 'SERVER_ADDR=127.0.0.1:%s\n' "$BACKEND_PORT"
    printf 'DB_TYPE=sqlite\n'
    printf 'DB_PATH=%s\n' "$DB_PATH"
    printf 'JWT_SECRET=%s\n' "$jwt_secret"
    printf 'LOG_DIR=%s\n' "$LOG_ROOT"
    printf 'FLUX_VERSION=%s\n' "$FLVX_RELEASE_VERSION"
    printf 'FLVX_WEBAUTHN_ORIGIN=https://%s\n' "$domain"
  } > "$ETC_ROOT/panel.env"
  chown root:flvx "$ETC_ROOT/panel.env"
  chmod 0640 "$ETC_ROOT/panel.env"
}

write_systemd_unit() {
  install -d -m 0755 "$SYSTEMD_ROOT"
  cat > "$SYSTEMD_ROOT/flvx.service" <<EOF
[Unit]
Description=FV-DX panel backend
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=flvx
Group=flvx
EnvironmentFile=$ETC_ROOT/panel.env
ExecStart=$OPT_ROOT/current/flvx-paneld
WorkingDirectory=$OPT_ROOT/current
Restart=on-failure
RestartSec=3
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$DATA_ROOT $LOG_ROOT

[Install]
WantedBy=multi-user.target
EOF
  chmod 0644 "$SYSTEMD_ROOT/flvx.service"
  systemctl daemon-reload
  systemctl enable --now flvx.service
}

write_reverse_proxy_example() {
  cat > "$ETC_ROOT/reverse-proxy-example.caddy" <<EOF
$domain {
    handle /api/* {
        reverse_proxy 127.0.0.1:$BACKEND_PORT
    }
    handle /system-info {
        reverse_proxy 127.0.0.1:$BACKEND_PORT
    }
    handle /assets/* {
        root * $OPT_ROOT/frontend-current
        header Cache-Control "public, max-age=31536000, immutable"
        file_server
    }
    handle /sw.js {
        root * $OPT_ROOT/frontend-current
        header Cache-Control "no-store, no-cache, must-revalidate"
        file_server
    }
    handle {
        root * $OPT_ROOT/frontend-current
        try_files {path} /index.html
        header Cache-Control "no-cache, max-age=0, must-revalidate"
        file_server
    }
}
EOF
  chmod 0644 "$ETC_ROOT/reverse-proxy-example.caddy"
}

configure_caddy() {
  local import_line='import /etc/caddy/sites-enabled/*.caddy'
  write_reverse_proxy_example
  [[ $proxy_mode == caddy ]] || return 0

  install -d -m 0755 "$CADDY_ROOT/sites-enabled"
  install -m 0644 "$ETC_ROOT/reverse-proxy-example.caddy" "$CADDY_ROOT/sites-enabled/flvx.caddy"
  touch "$CADDY_ROOT/Caddyfile"
  grep -Fxq "$import_line" "$CADDY_ROOT/Caddyfile" || printf '\n%s\n' "$import_line" >> "$CADDY_ROOT/Caddyfile"
  caddy validate --config "$CADDY_ROOT/Caddyfile" --adapter caddyfile
  systemctl enable caddy.service
  systemctl reload caddy.service || systemctl restart caddy.service
}

wait_for_backend() {
  local i
  for ((i = 1; i <= 30; i++)); do
    if curl -fsS -H 'Content-Type: application/json' \
      --data '{"name":"app_name"}' \
      "http://127.0.0.1:$BACKEND_PORT/api/v1/public/config/get" | grep '"code":0' >/dev/null; then
      return 0
    fi
    sleep 1
  done
  return 1
}

verify_login() {
  local request response
  request="$temp_dir/login-request.json"
  response="$temp_dir/login-response.json"
  chmod 0600 "$temp_dir"
  printf '{"username":"%s","password":"%s"}\n' "$admin_username" "$admin_password" > "$request"
  chmod 0600 "$request"
  curl -fsS -H 'Content-Type: application/json' --data-binary "@$request" \
    "http://127.0.0.1:$BACKEND_PORT/api/v1/user/login" > "$response"
  grep -q '"code":0' "$response" || die "随机管理员凭据登录验证失败。"
}

verify_https() {
  [[ $proxy_mode == caddy ]] || return 0
  local attempt
  for ((attempt = 1; attempt <= 60; attempt++)); do
    if curl -fsS --connect-timeout 5 "https://$domain/" | grep -i '<html' >/dev/null; then
      curl -fsS --connect-timeout 5 "https://$domain/business-line" | grep -i '<html' >/dev/null || return 1
      return 0
    fi
    sleep 2
  done
  return 1
}

write_state_and_credentials() {
  local build_commit
  build_commit=$(sed -n 's/.*"build_commit"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$temp_dir/release-metadata.json" | head -1)
  umask 077
  {
    printf 'version=%s\n' "$FLVX_RELEASE_VERSION"
    printf 'build_commit=%s\n' "$build_commit"
    printf 'domain=%s\n' "$domain"
    printf 'proxy_mode=%s\n' "$proxy_mode"
    printf 'installed_at=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  } > "$STATE_FILE"
  chown root:flvx "$STATE_FILE"
  chmod 0640 "$STATE_FILE"

  if [[ $credential_mode == save ]]; then
    install -d -m 0700 "$(dirname "$CREDENTIAL_FILE")"
    {
      printf 'FV-DX: https://%s\n' "$domain"
      printf '管理员用户名: %s\n' "$admin_username"
      printf '管理员密码: %s\n' "$admin_password"
    } > "$CREDENTIAL_FILE"
    chmod 0600 "$CREDENTIAL_FILE"
  fi
}

print_result() {
  say ""
  say "FV-DX 安装完成。"
  say "面板地址：https://$domain"
  say "管理员用户名：$admin_username"
  say "管理员密码：$admin_password"
  [[ $credential_mode == save ]] && say "凭据已保存到 $CREDENTIAL_FILE（权限 0600）。"
  if [[ $proxy_mode == external ]]; then
    say "Backend upstream：http://127.0.0.1:$BACKEND_PORT"
    say "反向代理示例：$ETC_ROOT/reverse-proxy-example.caddy"
    say "请由现有反向代理为 $domain 配置 HTTPS。"
  fi
  say "维护命令：systemctl status flvx"
  say "重启命令：systemctl restart flvx"
  say "日志命令：journalctl -u flvx -f"
  say "请立即安全保存管理员凭据。"
}

main() {
  require_root
  require_debian_12_amd64
  require_version_and_source
  require_runtime_tools
  check_disk_space
  check_existing_install
  collect_choices
  check_dns
  check_ports
  download_artifacts

  if [[ ${FLVX_VERIFY_ONLY:-0} == 1 ]]; then
    say "安装包下载与 SHA256 校验通过。"
    return 0
  fi

  install_started=1
  install_dependencies
  generate_credentials
  install_files
  initialize_database
  write_backend_config
  write_systemd_unit
  wait_for_backend || die "Backend 健康检查失败。"
  verify_login
  configure_caddy
  verify_https || die "HTTPS 或 SPA 路由健康检查失败。"
  write_state_and_credentials
  install_finished=1
  print_result
}

main "$@"
