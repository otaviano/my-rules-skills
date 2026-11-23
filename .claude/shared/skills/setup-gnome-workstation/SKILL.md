---
name: setup-gnome-workstation
description: Configura os periféricos do usuário numa máquina Linux GNOME nova (Ubuntu ou Fedora) — layouts de teclado US alt-intl + ABNT2, cedilha (' + c → ç), mouse Logitech MX Master 3S com a roda do polegar controlando o volume e histórico do clipboard no Super+V. Use ao receber/reinstalar uma máquina ("máquina nova da empresa", "configurar teclado e mouse", "setup do Ubuntu").
license: MIT
---

# Setup de periféricos numa máquina GNOME nova

Orquestra quatro skills, cada uma com um script idempotente que pode rodar sozinho:

| Etapa | Skill | Script |
|-------|-------|--------|
| Layouts de teclado | [[gnome-keyboard-layout]] | `gnome-keyboard-layout/scripts/keyboard.sh` |
| Cedilha | [[fix-cedilla-keyboard]] | `fix-cedilla-keyboard/scripts/fix-cedilla.sh` |
| Mouse MX Master 3S | [[logitech-mx-master]] | `logitech-mx-master/scripts/mouse.sh` |
| Super+V (histórico do clipboard) | [[gnome-clipboard-history]] | `gnome-clipboard-history/scripts/clipboard.sh` |

Os caminhos são relativos à pasta `skills/` que contém esta skill (no plugin instalado, a pasta
irmã deste `SKILL.md`).

## Passos

### 1. Conferir o ambiente
```bash
echo "$XDG_CURRENT_DESKTOP / $XDG_SESSION_TYPE"; . /etc/os-release; echo "$PRETTY_NAME"
gsettings get org.gnome.desktop.input-sources sources
```
Se não for GNOME, **pare** e avise: os scripts usam `gsettings` do GNOME.

### 2. Simular
```bash
bash <skills>/setup-gnome-workstation/scripts/setup.sh --dry-run
```
Mostre ao usuário o que vai mudar. Os passos com `sudo` são: `localectl` (layout da tela de
login), `/etc/environment` (cedilha), instalar o Solaar e, se faltar, a regra udev do `uinput`; e as dependências do Copyous
(`libgda`, `GSound`). A extensão do clipboard é instalada por um diálogo do GNOME que o usuário
confirma.

### 3. Executar
O script pede a senha do `sudo` no terminal, então **não rode pelo Bash tool** (não há como
digitar a senha). Passe o comando para o usuário rodar no terminal dele:
```bash
bash <skills>/setup-gnome-workstation/scripts/setup.sh
```
Opções: `--no-system` (pula o que exige sudo no teclado/cedilha), `--skip-keyboard`,
`--skip-cedilla`, `--skip-mouse`, `--skip-clipboard`, `--ppa` (Solaar do PPA oficial no Ubuntu, mais novo que o
repo da distro).

Em máquina **da empresa**, confirme antes se pode instalar pacotes e adicionar PPA: a política de
TI pode bloquear. Sem `sudo`, rode com `--no-system --skip-mouse` e só o `~/.XCompose` e os
layouts da sessão são aplicados.

### 4. Validar (depois de logout/login)
- `'` + `c` → `ç` num app GTK (gedit/Text Editor), num GTK4 (Settings) e no navegador.
- `Super+Espaço` alterna **English (US, alt. intl.)** ↔ **Portuguese (Brazil)**.
- `Super+V` abre o histórico no ponteiro; `Enter` cola o item.
- Roda do polegar → volume. Se não responder: `ls -l /dev/uinput` deve mostrar ACL do usuário
  (`getfacl /dev/uinput`) e `pgrep -af solaar` deve listar o processo.

Se algo falhar, siga a seção *Gotchas* da skill específica.

## Guardrails
- Os scripts fazem backup (`*.ORIGINAL`) antes de sobrescrever `~/.XCompose` e `rules.yaml`.
- Não copie `~/.config/solaar/config.yaml` de outra máquina: ele guarda serial do dispositivo.
  As configurações do mouse são aplicadas por `solaar config`.
