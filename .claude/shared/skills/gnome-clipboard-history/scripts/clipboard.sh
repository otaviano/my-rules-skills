#!/usr/bin/env bash
# Histórico de área de transferência no Super+V (como o Win+V) no GNOME.
# GNOME >= 48: Copyous (popup no ponteiro, cards com prévia). GNOME 44-47: Clipboard Indicator.
# Idempotente. Uso: clipboard.sh [--dry-run] [--no-system] [--indicator]
set -euo pipefail

DRY_RUN=0
SYSTEM=1
FORCE_INDICATOR=0

usage() {
  cat <<'EOF'
Uso: clipboard.sh [--dry-run] [--no-system] [--indicator]
  --dry-run    só mostra o que seria feito
  --no-system  não instala dependências (sudo); a extensão funciona, mas o Copyous avisa da falta do libgda
  --indicator  usa o Clipboard Indicator mesmo em GNOME >= 48
EOF
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --no-system) SYSTEM=0 ;;
    --indicator) FORCE_INDICATOR=1 ;;
    -h | --help) usage; exit 0 ;;
    *) echo "opção desconhecida: $arg" >&2; usage >&2; exit 2 ;;
  esac
done

run() {
  echo "+ $*"
  if [ "$DRY_RUN" = 0 ]; then "$@"; fi
}

command -v gnome-shell >/dev/null || { echo "gnome-shell não encontrado: isto é GNOME?" >&2; exit 1; }
[ -n "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ] || { echo "Rode dentro da sessão gráfica (a instalação abre um diálogo do GNOME)." >&2; exit 1; }

SHELL_MAJOR=$(gnome-shell --version | grep -oE '[0-9]+' | head -1)
if [ "$FORCE_INDICATOR" = 0 ] && [ "$SHELL_MAJOR" -ge 48 ]; then
  UUID=copyous@boerdereinar.dev
  SCHEMA=org.gnome.shell.extensions.copyous
else
  UUID=clipboard-indicator@tudmotu.com
  SCHEMA=org.gnome.shell.extensions.clipboard-indicator
fi
EXT_DIR="$HOME/.local/share/gnome-shell/extensions/$UUID"
echo "== GNOME $SHELL_MAJOR → $UUID"

# 1. Dependências do Copyous (histórico em SQLite via libgda; som via GSound).
if [ "$UUID" = copyous@boerdereinar.dev ] && [ "$SYSTEM" = 1 ]; then
  echo "== Dependências"
  if command -v apt-get >/dev/null; then
    PKGS=(gir1.2-gda-5.0 gir1.2-gsound-1.0)
    MISSING=()
    for p in "${PKGS[@]}"; do dpkg -s "$p" >/dev/null 2>&1 || MISSING+=("$p"); done
    if [ ${#MISSING[@]} -gt 0 ]; then run sudo apt-get install -y "${MISSING[@]}"; else echo "já instaladas."; fi
  elif command -v dnf >/dev/null; then
    PKGS=(libgda libgda-sqlite gsound)
    MISSING=()
    for p in "${PKGS[@]}"; do rpm -q "$p" >/dev/null 2>&1 || MISSING+=("$p"); done
    if [ ${#MISSING[@]} -gt 0 ]; then run sudo dnf install -y "${MISSING[@]}"; else echo "já instaladas."; fi
  else
    echo "AVISO: instale libgda (com SQLite) e GSound manualmente." >&2
  fi
fi

# 2. Instalar pela loja oficial: o próprio GNOME baixa e pede confirmação num diálogo.
#    Instalar já ativa a extensão. NÃO rode disable/enable depois na mesma sessão: o Copyous fica
#    em ERROR ("Extension point conflict") até o próximo login.
echo "== Extensão"
if [ -d "$EXT_DIR" ]; then
  echo "já instalada em $EXT_DIR"
else
  echo ">> Confirme em 'Install' no diálogo do GNOME."
  run gdbus call --session --timeout 300 --dest org.gnome.Shell --object-path /org/gnome/Shell \
    --method org.gnome.Shell.Extensions.InstallRemoteExtension "$UUID"
fi
if [ "$DRY_RUN" = 0 ] && [ ! -d "$EXT_DIR/schemas" ]; then
  echo "A extensão não foi instalada (diálogo cancelado?). Rode de novo." >&2
  exit 1
fi

# 3. Liberar o Super+V: por padrão ele abre a lista de notificações (que continua no Super+M).
echo "== Liberar Super+V"
run gsettings set org.gnome.shell.keybindings toggle-message-tray "['<Super>m']"

# 4. Configurar. O schema vive na pasta da extensão.
echo "== Configurar $SCHEMA"
export GSETTINGS_SCHEMA_DIR="$EXT_DIR/schemas"
if [ "$UUID" = copyous@boerdereinar.dev ]; then
  run gsettings set "$SCHEMA" open-clipboard-dialog-shortcut "['<Super>v']"
  run gsettings set "$SCHEMA" paste-on-copy true          # escolher um item cola no app em foco
  run gsettings set "$SCHEMA" incognito false             # anônimo ligado = histórico vazio
  run gsettings set "$SCHEMA" show-at-cursor false        # cursor de texto não é confiável no Wayland
  run gsettings set "$SCHEMA" show-at-pointer true
  run gsettings set "$SCHEMA" clipboard-orientation vertical
  run gsettings set "$SCHEMA" clipboard-size 420
  run gsettings set "$SCHEMA" clipboard-position-horizontal center
  run gsettings set "$SCHEMA" clipboard-position-vertical center
else
  run gsettings set "$SCHEMA" toggle-menu "['<Super>v']"
  run gsettings set "$SCHEMA" enable-keybindings true
  run gsettings set "$SCHEMA" paste-on-select true
fi

echo
echo "Pronto. Faça logout/login uma vez para a extensão subir limpa, depois teste:"
echo "copie 2-3 coisas, aperte Super+V num editor, escolha com Enter (cola direto)."
