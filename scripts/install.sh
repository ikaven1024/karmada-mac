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

health() {
  "${ROOT_DIR}/health_check.sh"
}

uninstall() {
  echo ! Starting uninstall karmada

  disable

  echo !!! stop karmada
  stop

  # It's safe to unlink(delete) file while being used in unix systems.
  rm -rf "${ROOT_DIR}"
}

help() {
  echo "
Usage: $0 <COMMAND>

Commands:
enable    : Start the karmada when operating system start up.
disable   : Don't start the karmada when operating system start up.
start     : Run the karmada.
stop      : Stop the karmada.
restart   : Restart the karmada.
status    : Show the status of processes by launchctl. It's better to use \"health\" command
health    : Check health of all processes.
uninstall : Stop the karmada, and remove everything left.
help      : Print the usage of this script."
}

cmd=${1:-help}
case $cmd in
enable|disable|start|stop|restart|status|health|uninstall|help)
  $cmd
  ;;
*)
  echo unknown command "$cmd".
  help
  exit 1
esac
