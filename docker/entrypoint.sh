#!/usr/bin/env bash
set -Eeuo pipefail

log() {
  printf '[%s] %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$*"
}

is_true() {
  case "${1,,}" in
    1|true|yes|on) return 0 ;;
    *) return 1 ;;
  esac
}

: "${ETS2_APP_ID:=1948160}"
: "${ETS2_AUTO_UPDATE:=true}"
: "${ETS2_VALIDATE_ON_UPDATE:=false}"
: "${ETS2_BRANCH:=public}"
: "${ETS2_BETA_PASSWORD:=}"
: "${ETS2_INSTALL_DIR:=/data/server}"
: "${ETS2_DATA_HOME:=}"
: "${ETS2_XDG_DATA_HOME:=}"
: "${ETS2_FIX_PERMISSIONS:=true}"
: "${ETS2_REQUIRE_SERVER_PACKAGES:=true}"

STEAMCMD_PATH="${STEAMCMD_PATH:-/home/steam/steamcmd/steamcmd.sh}"
DEFAULT_CONFIG="/home/steam/defaults/server_config.sii"

if [[ "$(id -u)" -eq 0 ]]; then
  if is_true "${ETS2_FIX_PERMISSIONS}"; then
    mkdir -p /data || true
    if chown -R steam:steam /data 2>/dev/null; then
      log "Adjusted permissions for /data."
    else
      log "Could not fully adjust /data permissions (possibly root_squash)."
      log "You may still need host-side chown for bind mount."
    fi
  fi

  exec gosu steam /home/steam/entrypoint.sh "$@"
fi

if [[ -n "${ETS2_DATA_HOME}" ]]; then
  export XDG_DATA_HOME="${ETS2_DATA_HOME}"
elif [[ -n "${ETS2_XDG_DATA_HOME}" ]]; then
  # Backward compatibility for previous env name.
  export XDG_DATA_HOME="${ETS2_XDG_DATA_HOME}"
else
  export XDG_DATA_HOME="/data/ets2data"
fi
SERVER_HOME="${XDG_DATA_HOME}/Euro Truck Simulator 2"

if ! mkdir -p "${ETS2_INSTALL_DIR}" "${SERVER_HOME}"; then
  log "Cannot write runtime directories under /data."
  log "Container user is uid:gid $(id -u):$(id -g)."
  log "Fix host permissions for bind mount ./data, then restart."
  log "Example on host: sudo chown -R 1000:1000 ./data"
  exit 10
fi

if [[ ! -f "${SERVER_HOME}/server_config.sii" ]]; then
  cp "${DEFAULT_CONFIG}" "${SERVER_HOME}/server_config.sii"
  log "Created default config at ${SERVER_HOME}/server_config.sii"
fi

missing_files=()
if is_true "${ETS2_REQUIRE_SERVER_PACKAGES}"; then
  for required_file in server_packages.sii server_packages.dat; do
    if [[ ! -f "${SERVER_HOME}/${required_file}" ]]; then
      missing_files+=("${required_file}")
    fi
  done

  if [[ ${#missing_files[@]} -gt 0 ]]; then
    log "Missing required file(s): ${missing_files[*]}"
    log "Put files in: ${SERVER_HOME}"
    log "Generate in ETS2/ATS client console with: export_server_packages"
    exit 20
  fi
fi

needs_install=false
if [[ ! -x "${ETS2_INSTALL_DIR}/bin/linux_x64/eurotrucks2_server" ]]; then
  needs_install=true
fi

if is_true "${ETS2_AUTO_UPDATE}" || [[ "${needs_install}" == "true" ]]; then
  log "Running SteamCMD update for app ${ETS2_APP_ID}"

  steamcmd_script="$(mktemp)"
  {
    echo "@ShutdownOnFailedCommand 1"
    echo "@NoPromptForPassword 1"
    echo "force_install_dir ${ETS2_INSTALL_DIR}"
    echo "login anonymous"

    app_update_cmd="app_update ${ETS2_APP_ID}"
    if [[ "${ETS2_BRANCH}" != "public" ]]; then
      app_update_cmd="${app_update_cmd} -beta ${ETS2_BRANCH}"
      if [[ -n "${ETS2_BETA_PASSWORD}" ]]; then
        app_update_cmd="${app_update_cmd} -betapassword ${ETS2_BETA_PASSWORD}"
      fi
    fi
    if is_true "${ETS2_VALIDATE_ON_UPDATE}"; then
      app_update_cmd="${app_update_cmd} validate"
    fi
    echo "${app_update_cmd}"
    echo "quit"
  } > "${steamcmd_script}"

  "${STEAMCMD_PATH}" +runscript "${steamcmd_script}"
  rm -f "${steamcmd_script}"
fi

launch_script=""
if [[ -f "${ETS2_INSTALL_DIR}/bin/linux_x64/server_launch.sh" ]]; then
  launch_script="${ETS2_INSTALL_DIR}/bin/linux_x64/server_launch.sh"
elif [[ -f "${ETS2_INSTALL_DIR}/server_launch.sh" ]]; then
  launch_script="${ETS2_INSTALL_DIR}/server_launch.sh"
fi

if [[ -z "${launch_script}" ]]; then
  log "Cannot find launch script under ${ETS2_INSTALL_DIR}"
  log "Expected one of:"
  log " - ${ETS2_INSTALL_DIR}/bin/linux_x64/server_launch.sh"
  log " - ${ETS2_INSTALL_DIR}/server_launch.sh"
  exit 30
fi

log "Starting ETS2 dedicated server"
log "Server home: ${SERVER_HOME}"

extra_args=()
if [[ -n "${ETS2_SERVER_ARGS:-}" ]]; then
  log "Extra args: ${ETS2_SERVER_ARGS}"
  read -r -a extra_args <<< "${ETS2_SERVER_ARGS}"
fi

cd "$(dirname "${launch_script}")"
exec bash "$(basename "${launch_script}")" "${extra_args[@]}"
