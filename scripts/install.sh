#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

ROOT_DIR=$(dirname "${BASH_SOURCE[0]}")

enable() {
  (
    cd "${ROOT_DIR}"/LaunchAgents
    dir=$(pwd)
    for file in *plist; do
      echo ln -s "${dir}/${file}" ~/Library/LaunchAgents/"${file}"
      ln -s "${dir}/${file}" ~/Library/LaunchAgents/"${file}" || true
    done
  )
}

disable() {
  rm -rf ~/Library/LaunchAgents/com.github.karmada-io.*.plist
}

start() {
  (
    cd "${ROOT_DIR}"/LaunchAgents
    launchctl load com.github.karmada-io.*.plist
  )
}

stop() {
  (
    cd "${ROOT_DIR}"/LaunchAgents
    launchctl unload com.github.karmada-io.*.plist
  )
}

restart() {
  stop
  sleep 2
  start
}

status() {
  echo 'NOTE: It is reported by "launchctl list". See more about it by "man launchctl"'
  launchctl list | grep -E "PID|com.github.karmada-io.*"
}

uninstall() {
  echo ! Starting uninstall karmada

  echo !!! stop karmad
  stop

  rm -rf "${ROOT_DIR}"/LaunchAgents/com.github.karmada-io.*.plist

  # clean dir
  echo !!! clean dir
  echo clean these dir manually:
  echo "        rm -rf $ROOT_DIR"
}

help() {
  cat HELP
}

cmd=${1:-help}
case $cmd in
enable|disable|start|stop|restart|status|uninstall|help)
  $cmd
  ;;
*)
  echo unknown command "$cmd".
  help
  exit 1
esac
