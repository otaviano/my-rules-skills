#!/usr/bin/env bash
# Logitech MX Master 3S no Linux via Solaar: roda do polegar controla o volume, scroll com SmartShift.
# Idempotente. Uso: mouse.sh [--dry-run] [--ppa] [--device NOME]
set -euo pipefail

DRY_RUN=0
USE_PPA=0
DEVICE="MX Master 3S"
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
RULES_SRC="$SCRIPT_DIR/../assets/rules.yaml"
RULES_DST="$HOME/.config/solaar/rules.yaml"
UINPUT_RULE=/etc/udev/rules.d/42-solaar-uinput.rules

usage() {
  cat <<'EOF'
Uso: mouse.sh [--dry-run] [--ppa] [--device NOME]
  --dry-run      só mostra o que seria feito
  --ppa          (Ubuntu) instala o Solaar do PPA oficial solaar-unifying/stable em vez do repo da distro
  --device NOME  nome do mouse como o Solaar mostra (padrão: "MX Master 3S")
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --ppa) USE_PPA=1 ;;
    --device) DEVICE="${2:?--device exige um nome}"; shift ;;
    -h | --help) usage; exit 0 ;;
    *) echo "opção desconhecida: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

run() {
  echo "+ $*"
  if [ "$DRY_RUN" = 0 ]; then "$@"; fi
}

# 1. Instalar o Solaar (traz a regra udev de acesso ao receptor e o autostart em /etc/xdg/autostart).
echo "== Solaar"
if command -v solaar >/dev/null; then
  echo "já instalado: $(solaar --version 2>/dev/null | tail -1)"
elif command -v apt-get >/dev/null; then
  if [ "$USE_PPA" = 1 ]; then
    run sudo add-apt-repository -y ppa:solaar-unifying/stable
  fi
  run sudo apt-get update
  run sudo apt-get install -y solaar
elif command -v dnf >/dev/null; then
  run sudo dnf install -y solaar
else
  echo "Gerenciador de pacotes não suportado: instale o Solaar manualmente." >&2
  exit 1
fi

# 2. uinput: no Wayland as regras do Solaar simulam teclas via /dev/uinput.
#    Versões novas do pacote já trazem a regra; as antigas não.
echo "== Acesso a /dev/uinput"
if grep -qs 'KERNEL=="uinput"' /usr/lib/udev/rules.d/*.rules /lib/udev/rules.d/*.rules /etc/udev/rules.d/*.rules; then
  echo "regra udev para uinput já existe."
else
  echo "+ escrever $UINPUT_RULE"
  if [ "$DRY_RUN" = 0 ]; then
    echo 'KERNEL=="uinput", SUBSYSTEM=="misc", TAG+="uaccess", OPTIONS+="static_node=uinput"' |
      sudo tee "$UINPUT_RULE" >/dev/null
  fi
  run sudo udevadm control --reload-rules
  run sudo udevadm trigger --subsystem-match=misc --sysname-match=uinput
fi

# 3. Regras: roda do polegar para baixo/cima = volume -/+.
echo "== Regras ($RULES_DST)"
if [ -f "$RULES_DST" ] && cmp -s "$RULES_SRC" "$RULES_DST"; then
  echo "rules.yaml já está correto."
else
  run mkdir -p "$(dirname "$RULES_DST")"
  if [ -s "$RULES_DST" ] && [ ! -e "$RULES_DST.ORIGINAL" ]; then
    run cp -f "$RULES_DST" "$RULES_DST.ORIGINAL"
  fi
  run cp -f "$RULES_SRC" "$RULES_DST"
fi

# 4. Autostart: o pacote instala /etc/xdg/autostart/solaar.desktop; sem ele, cria um por usuário.
echo "== Autostart"
if [ -f /etc/xdg/autostart/solaar.desktop ] || [ -f "$HOME/.config/autostart/solaar.desktop" ]; then
  echo "Solaar já inicia com a sessão."
else
  run mkdir -p "$HOME/.config/autostart"
  echo "+ escrever ~/.config/autostart/solaar.desktop"
  if [ "$DRY_RUN" = 0 ]; then
    printf '[Desktop Entry]\nType=Application\nName=Solaar\nExec=solaar --window=hide\nIcon=solaar\nTerminal=false\n' \
      >"$HOME/.config/autostart/solaar.desktop"
  fi
fi

# 5. Configurações do mouse (precisa estar conectado: Bolt/Unifying ou Bluetooth pareado).
echo "== Configurações do $DEVICE"
apply_device_settings() {
  # thumb-scroll-mode=true desvia a roda do polegar para o Solaar (senão as regras não disparam).
  run solaar config "$DEVICE" thumb-scroll-mode true
  run solaar config "$DEVICE" thumb-scroll-invert false
  run solaar config "$DEVICE" scroll-ratchet Ratcheted
  run solaar config "$DEVICE" smart-shift 10
  run solaar config "$DEVICE" dpi 1000
}
if [ "$DRY_RUN" = 1 ]; then
  apply_device_settings
elif solaar show "$DEVICE" >/dev/null 2>&1; then
  apply_device_settings
else
  echo "AVISO: '$DEVICE' não encontrado pelo Solaar (desligado, sem receptor ou não pareado)."
  echo "       Conecte o mouse e rode este script de novo para aplicar as configurações."
fi

# 6. Reiniciar o Solaar para recarregar rules.yaml.
echo "== Recarregar Solaar"
if pgrep -f 'bin/solaar' >/dev/null; then
  run pkill -f 'bin/solaar'
  sleep 1
fi
echo "+ solaar --window=hide (em segundo plano)"
if [ "$DRY_RUN" = 0 ]; then
  if [ -n "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ]; then
    setsid solaar --window=hide >/dev/null 2>&1 </dev/null &
  else
    echo "sem sessão gráfica neste shell: o Solaar sobe no próximo login."
  fi
fi

echo
echo "Pronto. Se o volume não responder à roda do polegar, faça logout/login (permissão do uinput)."
