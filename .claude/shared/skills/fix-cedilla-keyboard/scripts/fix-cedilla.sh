#!/usr/bin/env bash
# Faz ' + c produzir ç (e não ć) no layout US-International, em GTK3, GTK4/ibus e Qt.
# Idempotente. Uso: fix-cedilla.sh [--dry-run] [--no-system]
# Baseado no procedimento de https://github.com/marcopaganini/gnome-cedilla-fix
set -euo pipefail

DRY_RUN=0
SYSTEM=1

usage() {
  cat <<'EOF'
Uso: fix-cedilla.sh [--dry-run] [--no-system]
  --dry-run    só mostra o que seria feito
  --no-system  não altera /etc/environment (exige sudo); só gera ~/.XCompose
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

COMPOSE_DIR=/usr/share/X11/locale
TARGET="$HOME/.XCompose"

# 1. Compose do sistema para o locale atual (fallback: en_US.UTF-8).
find_compose() {
  local loc="$1" rel
  rel=$(sed -ne "s/^\([^:]*\):[ \t]*${loc}\$/\1/p" "$COMPOSE_DIR/compose.dir" | head -1)
  [ -n "$rel" ] && [ -f "$COMPOSE_DIR/$rel" ] && echo "$COMPOSE_DIR/$rel"
}

[ -f "$COMPOSE_DIR/compose.dir" ] || {
  echo "Não achei $COMPOSE_DIR/compose.dir. Instale libx11-data (Ubuntu) ou libX11-common (Fedora)." >&2
  exit 1
}
SYSTEM_COMPOSE=$(find_compose "${LANG:-en_US.UTF-8}" || true)
[ -n "$SYSTEM_COMPOSE" ] || SYSTEM_COMPOSE=$(find_compose en_US.UTF-8 || true)
[ -n "$SYSTEM_COMPOSE" ] || { echo "Não achei um Compose para ${LANG:-?} nem en_US.UTF-8." >&2; exit 1; }
echo "== Compose do sistema: $SYSTEM_COMPOSE"

# 2. Gerar ~/.XCompose = Compose do sistema com ć→ç e Ć→Ç (bytes UTF-8, independe do locale do shell).
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT
sed -e 's/\xc4\x87/\xc3\xa7/g' -e 's/\xc4\x86/\xc3\x87/g' "$SYSTEM_COMPOSE" >"$TMP"

if [ -f "$TARGET" ] && cmp -s "$TMP" "$TARGET"; then
  echo "~/.XCompose já está correto."
else
  if [ -s "$TARGET" ] && [ ! -e "$TARGET.ORIGINAL" ]; then
    run cp -f "$TARGET" "$TARGET.ORIGINAL"
  fi
  run cp -f "$TMP" "$TARGET"
fi

# 3. /etc/environment: força o IM "cedilla" no GTK3 e Qt. Onde o módulo não existe (GTK4, Fedora),
#    o toolkit cai no IM simples/ibus, que também lê ~/.XCompose. É a combinação que funciona hoje.
set_env_var() {
  local key="$1" value="$2" file=/etc/environment
  if grep -qx "${key}=${value}" "$file" 2>/dev/null; then
    echo "$file já tem ${key}=${value}"
  elif grep -q "^${key}=" "$file" 2>/dev/null; then
    run sudo sed -i "s|^${key}=.*|${key}=${value}|" "$file"
  else
    echo "+ echo '${key}=${value}' | sudo tee -a $file"
    if [ "$DRY_RUN" = 0 ]; then echo "${key}=${value}" | sudo tee -a "$file" >/dev/null; fi
  fi
}

if [ "$SYSTEM" = 1 ]; then
  echo "== /etc/environment"
  set_env_var GTK_IM_MODULE cedilla
  set_env_var QT_IM_MODULE cedilla
fi

echo
echo "Pronto. Faça logout/login (ou reinicie) e teste ' + c → ç e ' + C → Ç."
