#!/usr/bin/env bash
set -euo pipefail

DEFAULT_REDMINE_ROOT="/home/red2mine/20240627/red2mine"
REDMINE_ROOT="${1:-${DEFAULT_REDMINE_ROOT}}"
RAILS_ENV="${RAILS_ENV:-production}"

if [[ ! -d "${REDMINE_ROOT}" ]]; then
  echo "Redmine root does not exist: ${REDMINE_ROOT}" >&2
  exit 1
fi

cd "${REDMINE_ROOT}"
bundle exec rails redmine:plugins:migrate NAME=redmine_status_alias RAILS_ENV="${RAILS_ENV}"
