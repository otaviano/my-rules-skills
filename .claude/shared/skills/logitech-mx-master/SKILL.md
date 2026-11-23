---
name: logitech-mx-master
description: Configura o mouse Logitech MX Master 3S no Linux via Solaar — roda do polegar controla o volume (regras do Solaar), scroll com SmartShift, DPI 1000, inicia com a sessão e funciona no Wayland via uinput. Use ao configurar o mouse numa máquina nova ou quando a roda do polegar "parou de funcionar".
license: MIT
---

# MX Master 3S com Solaar

O Linux não tem o Logi Options+. O **Solaar** fala HID++ com o mouse (receptor Bolt/Unifying ou
Bluetooth) e executa **regras**: aqui, a roda do polegar vira controle de volume.

Configuração de referência:

| Setting do Solaar | Valor | Para quê |
|-------------------|-------|----------|
| `thumb-scroll-mode` | `true` | desvia a roda do polegar para o Solaar (obrigatório para as regras) |
| `thumb-scroll-invert` | `false` | |
| `scroll-ratchet` | `Ratcheted` | roda principal com "cliques" |
| `smart-shift` | `10` | girada rápida solta a roda (free-spin) |
| `dpi` | `1000` | |

Regras (`assets/rules.yaml` → `~/.config/solaar/rules.yaml`):
- roda do polegar para baixo (limiar 4) → `XF86_AudioLowerVolume`
- roda do polegar para cima (limiar 4) → `XF86_AudioRaiseVolume`

## Passos
```bash
bash scripts/mouse.sh --dry-run
bash scripts/mouse.sh               # Solaar do repo da distro
bash scripts/mouse.sh --ppa         # Ubuntu: Solaar do PPA oficial (versão mais nova)
```
`scripts/` e `assets/` são relativos à pasta desta skill. O script:
1. instala o Solaar (`apt`/`dnf`), que traz a regra udev do receptor e o autostart;
2. garante a regra udev do `/dev/uinput` (no Wayland o Solaar simula teclas por ele);
3. copia `rules.yaml` (com backup `.ORIGINAL`);
4. garante o autostart (`solaar --window=hide`);
5. aplica as settings com `solaar config` se o mouse estiver conectado;
6. reinicia o Solaar para recarregar as regras.

Instalação usa `sudo`: passe o comando para o usuário rodar no terminal.

### Pareamento
- **Receptor Bolt/Unifying**: plugue e ligue o mouse no canal certo (botão embaixo).
  Para parear um receptor novo: `solaar pair`.
- **Bluetooth**: Settings → Bluetooth, ou `bluetoothctl` (`scan on`, `pair <MAC>`, `trust <MAC>`).

Depois de conectar, rode o script de novo para aplicar as settings.

## Gotchas
- **Wayland**: o log avisa *"rules cannot access modifier keys in Wayland"* e que condições de
  `Process` exigem a extensão Solaar do GNOME. É esperado e não afeta estas regras.
- **Sem efeito após instalar**: a ACL do `/dev/uinput` só vale numa sessão nova. Faça
  logout/login e confira com `getfacl /dev/uinput`.
- **Ubuntu LTS** traz Solaar antigo. Se `Test: [thumb_wheel_up, 4]` não for reconhecido no
  editor de regras, use `--ppa`.
- **Nome do dispositivo**: se for outro modelo (MX Master 3, MX Anywhere), passe
  `--device "Nome"` exatamente como aparece em `solaar show`.
- Não copie `config.yaml` entre máquinas: ele tem serial e unitId do mouse.

## Reverter
```bash
mv ~/.config/solaar/rules.yaml.ORIGINAL ~/.config/solaar/rules.yaml 2>/dev/null || rm ~/.config/solaar/rules.yaml
solaar config "MX Master 3S" thumb-scroll-mode false   # roda do polegar volta a rolar na horizontal
```
