#!/usr/bin/env bash
set -euo pipefail

DEFAULT_REDMINE_ROOT="/home/red2mine/20240627/red2mine"
PLUGIN_NAME="redmine_status_alias"

usage() {
  echo "Usage: $0 [/path/to/redmine]"
  echo
  echo "Default Redmine root: ${DEFAULT_REDMINE_ROOT}"
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

REDMINE_ROOT="${1:-${DEFAULT_REDMINE_ROOT}}"
PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLUGINS_DIR="${REDMINE_ROOT}/plugins"
TARGET_PATH="${PLUGINS_DIR}/${PLUGIN_NAME}"

if [[ ! -d "${REDMINE_ROOT}" ]]; then
  echo "Redmine root does not exist: ${REDMINE_ROOT}" >&2
  exit 1
fi

if [[ ! -d "${PLUGINS_DIR}" ]]; then
  echo "Plugins directory does not exist: ${PLUGINS_DIR}" >&2
  exit 1
fi

if [[ -e "${TARGET_PATH}" && ! -L "${TARGET_PATH}" ]]; then
  echo "Target path already exists and is not a symlink: ${TARGET_PATH}" >&2
  echo "Move or remove it manually before linking the plugin." >&2
  exit 1
fi

ln -sfn "${PLUGIN_ROOT}" "${TARGET_PATH}"

echo "Linked plugin:"
echo "  source: ${PLUGIN_ROOT}"
echo "  target: ${TARGET_PATH}"
