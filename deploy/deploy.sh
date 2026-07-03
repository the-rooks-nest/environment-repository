#!/usr/bin/env bash
set -euo pipefail

APP_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LABEL="${ENVIRONMENT_REPOSITORY_LAUNCHD_LABEL:-com.the-rooks-nest.environment-repository}"
PLIST_PATH="${HOME}/Library/LaunchAgents/${LABEL}.plist"
BREW_PREFIX="${HOMEBREW_PREFIX:-/opt/homebrew}"
export PATH="${BREW_PREFIX}/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

cd "$APP_ROOT"
mkdir -p logs

echo "==> Deploying environment-repository from $(pwd)"
git fetch origin main
git reset --hard origin/main

python3 -m venv .venv
. .venv/bin/activate
python -m pip install --upgrade pip
pip install -r requirements.txt

if [[ -f "$PLIST_PATH" ]]; then
  echo "==> Restarting launchd service $LABEL"
  if launchctl print "gui/$(id -u)/$LABEL" >/dev/null 2>&1; then
    launchctl kickstart -k "gui/$(id -u)/$LABEL"
  else
    launchctl bootstrap "gui/$(id -u)" "$PLIST_PATH"
    launchctl kickstart -k "gui/$(id -u)/$LABEL"
  fi
else
  echo "==> No launchd plist found at $PLIST_PATH"
  echo "==> Dependencies installed, but service was not restarted"
fi

echo "==> Deploy complete"
