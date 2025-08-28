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

list_existing_avds() {
  log_info "Existing AVDs:"
  if command -v emulator >/dev/null 2>&1; then
    emulator -list-avds || true
  else
    avdmanager list avd || true
  fi
}

action_create_single() {
  local arch channel api device_id avd_name abi
  arch=$(detect_arch)
  local channel_default="google_apis"
  local api_default="33"   # Wear OS 4
  local device_default="pixel_watch"
  local name_default="WearOS_${api_default}_${arch}"

  log_info "Detected CPU architecture: $arch"
  log_info "Listing available Wear OS images (for reference):"
  list_wear_images

  channel=$(choose_value "Channel (google_apis or google_apis_playstore)" "$channel_default")
  api=$(choose_value "Android API level for Wear (e.g., 33 for Wear OS 4)" "$api_default")
  device_id=$(choose_value "Device ID (e.g., pixel_watch, wearos_large_round)" "$device_default")
  avd_name=$(choose_value "AVD name" "$name_default")
  abi="$arch"

  if prompt_yn "Install Wear OS image api=$api channel=$channel abi=$abi?" Y; then
    install_wear_image "$api" "$abi" "$channel" || return 1
  fi
  create_avd "$avd_name" "$api" "$abi" "$channel" "$device_id" || return 1
  if prompt_yn "Launch '$avd_name' now?" Y; then
    launch_emulator "$avd_name"
  fi
}

action_create_presets() {
  local arch=$(detect_arch)
  log_info "Detected CPU architecture: $arch"
  echo "Preset options:"
  echo "  1) Wear OS 4 (API 33) Pixel Watch (round)"
  echo "  2) Wear OS 4 (API 33) Large Round"
  echo "  3) Wear OS 4 (API 33) Small Round"
  echo "  4) Wear OS 5 (API 34) Pixel Watch (round)"
  echo "  5) Wear OS 5 (API 34) Large Round"
  echo "  6) Wear OS 5 (API 34) Small Round"
  read -r -p "Choose preset [1-6]: " p || p=1
  local device_id name_suffix api
  case "$p" in
    2) device_id="wearos_large_round"; name_suffix="LargeRound"; api="33" ;;
    3) device_id="wearos_small_round"; name_suffix="SmallRound"; api="33" ;;
    4) device_id="pixel_watch"; name_suffix="PixelWatch"; api="34" ;;
    5) device_id="wearos_large_round"; name_suffix="LargeRound"; api="34" ;;
    6) device_id="wearos_small_round"; name_suffix="SmallRound"; api="34" ;;
    *) device_id="pixel_watch"; name_suffix="PixelWatch"; api="33" ;;
  esac
  local channel="google_apis" abi="$arch" avd_name="WearOS_${name_suffix}_API${api}_${abi}"
  if prompt_yn "Install Wear OS image api=$api channel=$channel abi=$abi?" Y; then
    install_wear_image "$api" "$abi" "$channel" || return 1
  fi
  create_avd "$avd_name" "$api" "$abi" "$channel" "$device_id" || return 1
  if prompt_yn "Launch '$avd_name' now?" Y; then
    launch_emulator "$avd_name"
  fi
}

action_show_details() {
  list_existing_avds
  local name
  read -r -p "Enter AVD name to show details: " name || return 0
  if [[ -z "$name" ]]; then return 0; fi
  local dir="$HOME/.android/avd/${name}.avd"
  if [[ -d "$dir" ]]; then
    log_info "Config: $dir/config.ini"
    sed -n '1,200p' "$dir/config.ini" | sed 's/^/  /'
  else
    log_warn "AVD directory not found: $dir"
  fi
}

action_delete_avd() {
  list_existing_avds
  local name
  read -r -p "Enter AVD name to delete: " name || return 0
  if [[ -z "$name" ]]; then return 0; fi
  if prompt_yn "Really delete AVD '$name'?" N; then
    avdmanager delete avd -n "$name" && log_ok "Deleted $name" || log_err "Failed to delete $name"
  fi
}

action_rename_avd() {
  list_existing_avds
  local old new
  read -r -p "Old AVD name: " old || return 0
  [[ -z "$old" ]] && return 0
  read -r -p "New AVD name: " new || return 0
  [[ -z "$new" ]] && return 0
  local base="$HOME/.android/avd"
  local old_ini="$base/${old}.ini" new_ini="$base/${new}.ini"
  local old_dir="$base/${old}.avd" new_dir="$base/${new}.avd"
  if [[ ! -f "$old_ini" || ! -d "$old_dir" ]]; then
    log_err "AVD '$old' not found"
    return 1
  fi
  if [[ -e "$new_ini" || -e "$new_dir" ]]; then
    log_err "Target name '$new' already exists"
    return 1
  fi
  mv "$old_ini" "$new_ini" && mv "$old_dir" "$new_dir" || { log_err "Rename failed"; return 1; }
  # Update paths inside ini
  sed -i '' "s/${old}.avd/${new}.avd/g" "$new_ini" 2>/dev/null || true
  log_ok "Renamed '$old' to '$new'"
}

need_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    log_warn "jq not found. Needed for JSON export/import."
    if prompt_yn "Install jq via Homebrew now?" Y; then
      if command -v brew >/dev/null 2>&1; then
        brew install jq || { log_err "Failed to install jq"; return 1; }
      else
        log_err "Homebrew not found. Install jq manually: https://stedolan.github.io/jq/"
        return 1
      fi
    else
      return 1
    fi
  fi
  return 0
}

action_export_json() {
  need_jq || { log_warn "Skipping export."; return 0; }
  list_existing_avds
  local name out
  read -r -p "AVD name to export: " name || return 0
  [[ -z "$name" ]] && return 0
  read -r -p "Output JSON path [${name}.json]: " out || out=""
  out=${out:-"${name}.json"}
  local dir="$HOME/.android/avd/${name}.avd" ini="$HOME/.android/avd/${name}.ini"
  if [[ ! -d "$dir" || ! -f "$ini" ]]; then
    log_err "AVD '$name' not found"
    return 1
  fi
  # Extract a few key fields
  local target device path_pkg abi
  target=$(grep -E '^target=' "$ini" | cut -d'=' -f2-)
  device=$(grep -E '^hw.device.name=' "$dir/config.ini" | cut -d'=' -f2-)
  path_pkg=$(grep -E '^image.sysdir.1=' "$dir/config.ini" | cut -d'=' -f2-)
  abi=$(grep -E '^abi.type=' "$dir/config.ini" | cut -d'=' -f2-)
  jq -n --arg name "$name" --arg device "$device" --arg sysdir "$path_pkg" --arg abi "$abi" --arg target "$target" '{name:$name, device:$device, systemImage:$sysdir, abi:$abi, target:$target}' > "$out"
  log_ok "Exported to $out"
}

action_import_json() {
  need_jq || { log_warn "Skipping import."; return 0; }
  local json
  read -r -p "Path to preset JSON: " json || return 0
  [[ -z "$json" || ! -f "$json" ]] && { log_err "File not found"; return 1; }
  local name device sysdir abi target api channel
  name=$(jq -r '.name' "$json")
  device=$(jq -r '.device' "$json")
  sysdir=$(jq -r '.systemImage' "$json")
  abi=$(jq -r '.abi' "$json")
  target=$(jq -r '.target' "$json")
  # Parse system image path to get api + channel
  # e.g., system-images/android-33/wearos/google_apis/arm64-v8a/
  api=$(echo "$sysdir" | sed -n 's#.*/android-\([0-9][0-9]*\)/.*#\1#p')
  channel=$(echo "$sysdir" | sed -n 's#.*/wearos/\([^/]*\)/.*#\1#p')
  if [[ -z "$api" || -z "$channel" ]]; then
    log_warn "Could not infer API/channel from systemImage path; falling back to API 33, google_apis"
    api="33"; channel="google_apis"
  fi
  if prompt_yn "Install system image api=$api channel=$channel abi=$abi?" Y; then
    install_wear_image "$api" "$abi" "$channel" || return 1
  fi
  create_avd "$name" "$api" "$abi" "$channel" "$device" || return 1
  if prompt_yn "Launch '$name' now?" Y; then
    launch_emulator "$name"
  fi
}

action_launch_avd() {
  list_existing_avds
  local name
  read -r -p "AVD name to launch: " name || return 0
  [[ -z "$name" ]] && return 0
  launch_emulator "$name"
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

  while true; do
    echo
    echo "Select an action:"
    echo "  1) Create a Wear OS AVD"
    echo "  2) Create multiple AVDs from quick presets"
    echo "  3) List existing AVDs"
    echo "  4) Show AVD details"
    echo "  5) Delete an AVD"
    echo "  6) Rename an AVD (safe)"
    echo "  7) Export AVD definition to JSON"
    echo "  8) Import and create AVD from JSON"
    echo "  9) Launch an AVD"
    echo "  q) Quit"
    read -r -p "Choice: " choice || choice="q"

    case "$choice" in
      1)
        action_create_single || true
        ;;
      2)
        action_create_presets || true
        ;;
      3)
        list_existing_avds || true
        ;;
      4)
        action_show_details || true
        ;;
      5)
        action_delete_avd || true
        ;;
      6)
        action_rename_avd || true
        ;;
      7)
        action_export_json || true
        ;;
      8)
        action_import_json || true
        ;;
      9)
        action_launch_avd || true
        ;;
      q|Q)
        log_ok "Done."
        break
        ;;
      *)
        log_warn "Unknown choice."
        ;;
    esac
  done
}

main "$@"


