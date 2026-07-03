#!/usr/bin/env bash
set -euo pipefail

APP_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LABEL="${ENVIRONMENT_REPOSITORY_LAUNCHD_LABEL:-com.the-rooks-nest.environment-repository}"
PLIST_PATH="${HOME}/Library/LaunchAgents/${LABEL}.plist"
BREW_PREFIX="${HOMEBREW_PREFIX:-/opt/homebrew}"
export PATH="${BREW_PREFIX}/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

cd "$APP_ROOT"
mkdir -p logs

TEMPLATE_PATH="$APP_ROOT/deploy/com.the-rooks-nest.environment-repository.plist.example"
TMP_PLIST="$(mktemp)"
trap 'rm -f "$TMP_PLIST"' EXIT

echo "==> Deploying environment-repository from $(pwd)"
git fetch origin main
git reset --hard origin/main

python3 -m venv .venv
. .venv/bin/activate
python -m pip install --upgrade pip
pip install -r requirements.txt

echo "==> Installing launchd plist"
sed \
  -e "s#__APP_ROOT__#$APP_ROOT#g" \
  -e "s#__HOME__#$HOME#g" \
  "$TEMPLATE_PATH" > "$TMP_PLIST"
mkdir -p "$(dirname "$PLIST_PATH")"
cp "$TMP_PLIST" "$PLIST_PATH"
chmod 644 "$PLIST_PATH"

echo "==> Restarting launchd service $LABEL"
if launchctl print "gui/$(id -u)/$LABEL" >/dev/null 2>&1; then
  launchctl bootout "gui/$(id -u)" "$PLIST_PATH" >/dev/null 2>&1 || true
fi
launchctl bootstrap "gui/$(id -u)" "$PLIST_PATH"
launchctl kickstart -k "gui/$(id -u)/$LABEL"

PUBLIC_HEALTH_URL="${PUBLIC_HEALTH_URL:-https://environments.the-rooks-nest.com/health}"
echo "==> Checking public health at $PUBLIC_HEALTH_URL"
for i in $(seq 1 20); do
  if curl --fail --silent --show-error "$PUBLIC_HEALTH_URL"; then
    echo
    break
  fi
  if [[ "$i" = "20" ]]; then
    exit 1
  fi
  sleep 2
 done

echo "==> Deploy complete"
