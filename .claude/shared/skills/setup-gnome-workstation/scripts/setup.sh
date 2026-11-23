#!/usr/bin/env bash
# Setup de periféricos numa máquina GNOME nova (Ubuntu ou Fedora): teclado, cedilha, mouse e Super+V.
# Roda as quatro skills em sequência; cada uma é idempotente e pode ser rodada sozinha.
# Uso: setup.sh [--dry-run] [--no-system] [--skip-keyboard] [--skip-cedilla] [--skip-mouse] [--skip-clipboard] [--ppa]
set -euo pipefail

SKILLS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
COMMON=()
MOUSE_ARGS=()
DO_KEYBOARD=1
DO_CEDILLA=1
DO_MOUSE=1
DO_CLIPBOARD=1
CLIP_ARGS=()

usage() {
  cat <<'EOF'
Uso: setup.sh [opções]
  --dry-run        só mostra o que seria feito
  --no-system      pula o que exige sudo no teclado/cedilha (localectl, /etc/environment)
  --skip-keyboard  não configura os layouts
  --skip-cedilla   não configura a cedilha
  --skip-mouse     não configura o mouse Logitech
  --skip-clipboard não configura o histórico do clipboard no Super+V
  --ppa            (Ubuntu) Solaar do PPA oficial em vez do repo da distro
EOF
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) COMMON+=(--dry-run); MOUSE_ARGS+=(--dry-run); CLIP_ARGS+=(--dry-run) ;;
    --no-system) COMMON+=(--no-system); CLIP_ARGS+=(--no-system) ;;
    --skip-keyboard) DO_KEYBOARD=0 ;;
    --skip-cedilla) DO_CEDILLA=0 ;;
    --skip-mouse) DO_MOUSE=0 ;;
    --skip-clipboard) DO_CLIPBOARD=0 ;;
    --ppa) MOUSE_ARGS+=(--ppa) ;;
    -h | --help) usage; exit 0 ;;
    *) echo "opção desconhecida: $arg" >&2; usage >&2; exit 2 ;;
  esac
done

case "${XDG_CURRENT_DESKTOP:-}" in
  *GNOME*) echo "Sessão: ${XDG_CURRENT_DESKTOP} / ${XDG_SESSION_TYPE:-?} ($(. /etc/os-release && echo "$PRETTY_NAME"))" ;;
  *) echo "AVISO: não parece uma sessão GNOME (XDG_CURRENT_DESKTOP=${XDG_CURRENT_DESKTOP:-vazio})." >&2 ;;
esac

step() { printf '\n######## %s ########\n' "$1"; }

if [ "$DO_KEYBOARD" = 1 ]; then
  step "Teclado (layouts)"
  bash "$SKILLS_DIR/gnome-keyboard-layout/scripts/keyboard.sh" "${COMMON[@]}"
fi
if [ "$DO_CEDILLA" = 1 ]; then
  step "Cedilha"
  bash "$SKILLS_DIR/fix-cedilla-keyboard/scripts/fix-cedilla.sh" "${COMMON[@]}"
fi
if [ "$DO_MOUSE" = 1 ]; then
  step "Mouse (MX Master 3S / Solaar)"
  bash "$SKILLS_DIR/logitech-mx-master/scripts/mouse.sh" "${MOUSE_ARGS[@]}"
fi
if [ "$DO_CLIPBOARD" = 1 ]; then
  step "Histórico do clipboard (Super+V)"
  bash "$SKILLS_DIR/gnome-clipboard-history/scripts/clipboard.sh" "${CLIP_ARGS[@]}"
fi

step "Falta você"
cat <<'EOF'
1. Logout/login (cedilha, uinput e a extensão do clipboard só valem numa sessão nova).
2. Teste: ' + c → ç   |   Super+Espaço alterna US alt-intl ↔ ABNT2   |   roda do polegar → volume   |   Super+V → histórico.
EOF
