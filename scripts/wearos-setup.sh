#!/usr/bin/env bash

# Wear OS Emulator Setup Helper (macOS)
# - Interactive, error-tolerant, and reusable
# - Guides installation of SDK components, creates AVDs, and launches emulators

set -u

SCRIPT_NAME="wearos-setup.sh"

COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
COLOR_RESET='\033[0m'

log_info()  { echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $*"; }
log_ok()    { echo -e "${COLOR_GREEN}[OK]  ${COLOR_RESET} $*"; }
log_warn()  { echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} $*"; }
log_err()   { echo -e "${COLOR_RED}[ERR] ${COLOR_RESET} $*"; }

prompt_yn() {
  local prompt="$1" default=${2:-Y}
  local yn
  if [[ "$default" =~ ^[Yy]$ ]]; then
    read -r -p "$prompt [Y/n]: " yn || yn=""
    yn=${yn:-Y}
  else
    read -r -p "$prompt [y/N]: " yn || yn=""
    yn=${yn:-N}
  fi
  [[ "$yn" =~ ^[Yy]$ ]]
}

# Detect CPU arch to choose proper system image
detect_arch() {
  local arch
  arch=$(uname -m)
  case "$arch" in
    arm64) echo "arm64-v8a" ;;
    x86_64) echo "x86_64" ;;
    *) echo "$arch" ;;
  esac
}

ensure_android_home() {
  if [[ -n "${ANDROID_HOME:-}" && -d "$ANDROID_HOME" ]]; then
    log_ok "Using ANDROID_HOME=$ANDROID_HOME"
    return 0
  fi

  # Common default path on macOS
  local default_sdk="$HOME/Library/Android/sdk"
  if [[ -d "$default_sdk" ]]; then
    export ANDROID_HOME="$default_sdk"
    log_ok "Detected Android SDK at $ANDROID_HOME"
    return 0
  fi

  log_warn "Android SDK not found. You'll need Android Studio or cmdline-tools."
  if prompt_yn "Open Android Studio download page in browser?" Y; then
    open "https://developer.android.com/studio"
  fi
  log_info "After installing, re-run: export ANDROID_HOME=\"$default_sdk\""
  return 1
}

ensure_tools_in_path() {
  # Add common tool dirs to PATH if not present
  local add_paths=(
    "$ANDROID_HOME/emulator"
    "$ANDROID_HOME/platform-tools"
    "$ANDROID_HOME/tools"
    "$ANDROID_HOME/tools/bin"
    "$ANDROID_HOME/cmdline-tools/latest/bin"
  )
  local p
  for p in "${add_paths[@]}"; do
    if [[ -d "$p" ]] && [[ ":$PATH:" != *":$p:"* ]]; then
      PATH="$PATH:$p"
    fi
  done
}

ensure_cmdline_tools() {
  if command -v sdkmanager >/dev/null 2>&1 && command -v avdmanager >/dev/null 2>&1; then
    log_ok "cmdline-tools present (sdkmanager/avdmanager)"
    return 0
  fi
  log_warn "Android cmdline-tools not found."
  log_info "You can install via Android Studio (SDK Manager → SDK Tools → Android SDK Command-line Tools)."
  if prompt_yn "Open SDK Manager instructions in browser?" N; then
    open "https://developer.android.com/tools"
  fi
  return 1
}

list_wear_images() {
  log_info "Querying available Wear OS system images..."
  sdkmanager --list | grep -i "system-images;android-.*;wearos" || true
}

install_wear_image() {
  local api="$1" abi="$2" channel="$3"
  local pkg="system-images;android-${api};wearos;${channel};${abi}"
  log_info "Installing system image: $pkg"
  yes | sdkmanager "$pkg" || {
    log_err "Failed to install $pkg"
    return 1
  }
  log_ok "Installed $pkg"
}

create_avd() {
  local name="$1" api="$2" abi="$3" channel="$4" device_id="$5"
  local pkg="system-images;android-${api};wearos;${channel};${abi}"

  if avdmanager list avd | grep -q "Name: $name"; then
    log_warn "AVD '$name' already exists."
    if prompt_yn "Delete and recreate AVD '$name'?" N; then
      avdmanager delete avd -n "$name" || true
    else
      return 0
    fi
  fi

  log_info "Creating AVD: $name (device=$device_id, api=$api, abi=$abi, channel=$channel)"
  echo "no" | avdmanager create avd -n "$name" -k "$pkg" -d "$device_id" || {
    log_err "Failed to create AVD $name"
    return 1
  }
  log_ok "Created AVD $name"
}

launch_emulator() {
  local name="$1"
  log_info "Launching emulator: $name"
  # Start in background so the script can continue
  ( emulator -avd "$name" >/dev/null 2>&1 & )
  sleep 3
  log_info "Checking ADB connectivity..."
  adb devices || true
  log_ok "If the emulator window didn't appear, try: emulator -avd $name -verbose"
}

choose_value() {
  local prompt="$1" default="$2"
  local val
  read -r -p "$prompt [$default]: " val || val=""
  echo "${val:-$default}"
}

main() {
  log_info "${SCRIPT_NAME} starting..."

  ensure_android_home || exit 1
  ensure_tools_in_path
  ensure_cmdline_tools || exit 1

  local arch channel api device_id avd_name abi
  arch=$(detect_arch)
  channel_default="google_apis"   # or google_apis_playstore if available
  api_default="33"                # Wear OS 4
  device_default="pixel_watch"    # common Wear device id
  name_default="WearOS_${api_default}_${arch}"

  log_info "Detected CPU architecture: $arch"
  log_info "Listing available Wear OS images (for reference):"
  list_wear_images

  channel=$(choose_value "Channel (google_apis or google_apis_playstore)" "$channel_default")
  api=$(choose_value "Android API level for Wear (e.g., 33 for Wear OS 4)" "$api_default")
  device_id=$(choose_value "Device ID (e.g., pixel_watch, wearos_large_round)" "$device_default")
  avd_name=$(choose_value "AVD name" "$name_default")

  abi="$arch"
  log_info "Preparing to install image for: api=$api channel=$channel abi=$abi"
  if prompt_yn "Install required Wear OS system image now?" Y; then
    install_wear_image "$api" "$abi" "$channel" || exit 1
  else
    log_warn "Skipping image install; assuming it's already installed."
  fi

  if prompt_yn "Create (or recreate) AVD '$avd_name'?" Y; then
    create_avd "$avd_name" "$api" "$abi" "$channel" "$device_id" || exit 1
  fi

  if prompt_yn "Launch emulator '$avd_name' now?" Y; then
    launch_emulator "$avd_name"
  else
    log_info "You can launch later with: emulator -avd $avd_name"
  fi

  log_ok "All done. Happy hacking!"
}

main "$@"


