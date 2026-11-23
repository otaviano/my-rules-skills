---
name: gnome-keyboard-layout
description: Aplica o layout de teclado padrão do usuário no GNOME — English (US, alt. intl.) como principal e Portuguese (Brazil, ABNT2) como segundo, NumLock ligado, mesmo layout na tela de login. Use ao configurar teclado numa máquina nova ou quando o layout "voltou para o padrão".
license: MIT
---

# Layout de teclado no GNOME

Padrão do usuário:

| Chave | Valor |
|-------|-------|
| `org.gnome.desktop.input-sources sources` | `[('xkb', 'us+alt-intl'), ('xkb', 'br')]` |
| `org.gnome.desktop.input-sources per-window` | `false` (layout global, não por janela) |
| `org.gnome.desktop.peripherals.keyboard numlock-state` | `true` |
| `localectl` (GDM/console) | `X11 Layout: us,br` / `X11 Variant: alt-intl,` |

`us+alt-intl` é o **English (US, alt. intl.)**: acentos com dead keys (`'`, `` ` ``, `~`, `^`,
`"`). A cedilha precisa de ajuste à parte: [[fix-cedilla-keyboard]].

## Passos
```bash
bash scripts/keyboard.sh --dry-run   # revisar
bash scripts/keyboard.sh             # aplicar (sudo só no localectl)
bash scripts/keyboard.sh --no-system # só a sessão do usuário, sem sudo
```
`scripts/` é relativo à pasta desta skill. A parte de sessão vale na hora; a de sistema
(`localectl`) vale na próxima tela de login.

Se o comando precisar de `sudo`, passe-o para o usuário rodar no terminal: o Bash tool não
consegue digitar a senha.

## Gotchas
- **A ordem importa**: o primeiro layout é o ativo ao logar. Não inverta sem perguntar, mesmo
  que o teclado físico seja ABNT2.
- `xkb-options` não é tocado: se a empresa definiu opções (ex.: Caps→Ctrl), elas ficam.
- Em GNOME com **ibus**, as fontes de entrada continuam sendo as do `gsettings`; não configure
  layout pelo `ibus-setup`.

## Reverter
```bash
gsettings reset org.gnome.desktop.input-sources sources
gsettings reset org.gnome.desktop.peripherals.keyboard numlock-state
```
