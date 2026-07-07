#!/bin/sh
# tau: vendored binary (fast). dream: latest from npm (@taubyte/dream).
set -e

cd post && \
sudo cp tau /bin/ && \
sudo chmod 755 /bin/tau

if ! command -v npm >/dev/null 2>&1; then
  echo "ERROR: npm not found — devcontainer must include the node feature." >&2
  exit 1
fi

echo "Installing @taubyte/dream@latest from npm..."
sudo npm install -g @taubyte/dream@latest

if ! command -v dream >/dev/null 2>&1; then
  DREAM_JS="$(npm root -g 2>/dev/null)/@taubyte/dream/index.js"
  if [ -f "$DREAM_JS" ]; then
    sudo ln -sf "$DREAM_JS" /usr/local/bin/dream
  fi
fi

command -v dream >/dev/null 2>&1 || { echo "ERROR: dream install failed" >&2; exit 1; }

grep -q 'tau autocomplete' ~/.bashrc 2>/dev/null || \
  echo 'eval "$(tau autocomplete)"' >> ~/.bashrc

echo "tau:  $(tau version 2>/dev/null || echo ok)"
echo "dream: $(dream --version 2>/dev/null || dream --help 2>&1 | head -1)"
