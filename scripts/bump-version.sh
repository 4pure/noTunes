#!/usr/bin/env bash
# 修改本仓库版本号（只改唯一源）。
# 用法：
#   ./scripts/bump-version.sh           # 最小段 +1，例如 1.6.4 -> 1.6.5
#   ./scripts/bump-version.sh 1.7.0     # 设为指定版本
# Swift：写 Config/Version.xcconfig，并令 CURRENT_PROJECT_VERSION +1
# Rust：写根 Cargo.toml 的 [workspace.package] version（或 [package] version）
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARG_VERSION="${1:-}"

die() { echo "error: $*" >&2; exit 1; }
info() { echo "$*"; }

is_version() {
  [[ "$1" =~ ^[0-9]+(\.[0-9]+)+$ ]] || [[ "$1" =~ ^[0-9]+$ ]]
}

# 最小版本段 +1：1.6.4 -> 1.6.5；1.0 -> 1.1；3.5 -> 3.6
bump_min_segment() {
  local ver="$1"
  local prefix last
  if [[ "$ver" == *.* ]]; then
    prefix="${ver%.*}"
    last="${ver##*.}"
    [[ "$last" =~ ^[0-9]+$ ]] || die "无法递增版本段: $ver"
    echo "${prefix}.$((last + 1))"
  else
    [[ "$ver" =~ ^[0-9]+$ ]] || die "无法递增版本: $ver"
    echo "$((ver + 1))"
  fi
}

resolve_next_version() {
  local current="$1"
  if [[ -n "$ARG_VERSION" ]]; then
    is_version "$ARG_VERSION" || die "版本号格式无效: $ARG_VERSION (示例: 1.6.5)"
    echo "$ARG_VERSION"
  else
    bump_min_segment "$current"
  fi
}

# ---------- Swift: Config/Version.xcconfig ----------
bump_swift() {
  local cfg="$ROOT/Config/Version.xcconfig"
  [[ -f "$cfg" ]] || return 1

  local marketing build next next_build
  marketing="$(sed -nE 's/^MARKETING_VERSION *= *([^[:space:]]+).*/\1/p' "$cfg" | head -1)"
  build="$(sed -nE 's/^CURRENT_PROJECT_VERSION *= *([^[:space:]]+).*/\1/p' "$cfg" | head -1)"
  [[ -n "$marketing" ]] || die "未在 $cfg 找到 MARKETING_VERSION"
  [[ -n "$build" ]] || build=1

  next="$(resolve_next_version "$marketing")"
  next_build=$((build + 1))

  cat >"$cfg" <<EOF
// 营销版本与构建号只改这一处；Debug / Release 共用。
MARKETING_VERSION = ${next}
CURRENT_PROJECT_VERSION = ${next_build}
EOF

  info "Swift  $marketing ($build) -> $next ($next_build)"
  info "wrote $cfg"
  return 0
}

# ---------- Rust: Cargo workspace / package ----------
find_rust_cargo() {
  if [[ -f "$ROOT/Cargo.toml" ]]; then
    echo "$ROOT/Cargo.toml"
    return 0
  fi
  if [[ -f "$ROOT/src-tauri/Cargo.toml" ]]; then
    echo "$ROOT/src-tauri/Cargo.toml"
    return 0
  fi
  return 1
}

read_cargo_package_version() {
  local cargo="$1"
  perl -0777 -ne '
    if (/\[workspace\.package\](.*?)(?=\n\[|\z)/s) {
      if ($1 =~ /^\s*version\s*=\s*"([^"]+)"/m) { print $1; exit }
    }
    if (/\[package\](.*?)(?=\n\[|\z)/s) {
      if ($1 =~ /^\s*version\s*=\s*"([^"]+)"/m) { print $1; exit }
    }
  ' "$cargo"
}

set_cargo_canonical_version() {
  local cargo="$1" next="$2"
  if grep -q '^\[workspace\.package\]' "$cargo"; then
    perl -i -0pe 's/(\[workspace\.package\][^\[]*?^\s*version\s*=\s*")[^"]+(")/${1}'"$next"'${2}/ms' "$cargo"
  elif grep -q '^\[package\]' "$cargo"; then
    perl -i -0pe 's/(\[package\][^\[]*?^\s*version\s*=\s*")[^"]+(")/${1}'"$next"'${2}/ms' "$cargo"
  else
    die "无法在 $cargo 定位 version 字段"
  fi
}

bump_rust() {
  local cargo current next
  cargo="$(find_rust_cargo)" || return 1

  current="$(read_cargo_package_version "$cargo")"
  [[ -n "$current" ]] || die "未在 $cargo 找到 version"

  next="$(resolve_next_version "$current")"
  set_cargo_canonical_version "$cargo" "$next"

  info "Rust  $current -> $next"
  info "wrote $cargo"
  return 0
}

# ---------- main ----------
if [[ -n "$ARG_VERSION" ]]; then
  is_version "$ARG_VERSION" || die "版本号格式无效: $ARG_VERSION (示例: 1.6.5)"
fi

ok=0
if bump_swift; then ok=1; fi
if bump_rust; then ok=1; fi
[[ "$ok" -eq 1 ]] || die "未识别到 Swift(Config/Version.xcconfig) 或 Rust(Cargo.toml) 版本源 ($ROOT)"
