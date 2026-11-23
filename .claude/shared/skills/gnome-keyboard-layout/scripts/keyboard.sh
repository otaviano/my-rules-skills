#!/usr/bin/env bash
# Layout de teclado padrão no GNOME: English (US, alt. intl.) como principal + Portuguese (Brazil, ABNT2).
# Idempotente. Uso: keyboard.sh [--dry-run] [--no-system]
set -euo pipefail

DRY_RUN=0
SYSTEM=1

usage() {
  cat <<'EOF'
Uso: keyboard.sh [--dry-run] [--no-system]
  --dry-run    só mostra o que seria feito
  --no-system  não mexe no layout do sistema (tela de login/console, exige sudo)
EOF
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --no-system) SYSTEM=0 ;;
    -h | --help) usage; exit 0 ;;
    *) echo "opção desconhecida: $arg" >&2; usage >&2; exit 2 ;;
  esac
done

run() {
  echo "+ $*"
  if [ "$DRY_RUN" = 0 ]; then "$@"; fi
}

command -v gsettings >/dev/null || { echo "gsettings não encontrado: isto é GNOME?" >&2; exit 1; }

# Ordem importa: o primeiro é o layout ativo ao logar. Super+Espaço alterna.
SOURCES="[('xkb', 'us+alt-intl'), ('xkb', 'br')]"

echo "== Sessão GNOME do usuário"
run gsettings set org.gnome.desktop.input-sources sources "$SOURCES"
run gsettings set org.gnome.desktop.input-sources per-window false
run gsettings set org.gnome.desktop.peripherals.keyboard numlock-state true
run gsettings set org.gnome.desktop.peripherals.keyboard remember-numlock-state true

if [ "$SYSTEM" = 1 ]; then
  echo "== Sistema (GDM e console)"
  # Mesmo layout na tela de login, para a senha ser digitada no layout de costume.
  run sudo localectl set-x11-keymap us,br pc105 alt-intl,
fi

if [ "$DRY_RUN" = 0 ]; then
  echo "== Resultado"
  echo "sources: $(gsettings get org.gnome.desktop.input-sources sources)"
  echo "numlock: $(gsettings get org.gnome.desktop.peripherals.keyboard numlock-state)"
  if [ "$SYSTEM" = 1 ]; then localectl status | sed -n '/X11 Layout/,/X11 Variant/p'; fi
fi
