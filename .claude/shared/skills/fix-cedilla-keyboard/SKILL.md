---
name: fix-cedilla-keyboard
description: Configura o teclado Linux para que ' + c produza ç (cedilha) em vez de ć, via ~/.XCompose. Use quando o usuário reclama que "a cedilha não funciona", digita ć sem querer, ou está preparando uma máquina nova com layout US-International para escrever em português.
license: MIT
---

# Cedilha no Linux (US-International / GTK)

No layout **US-International**, `'` + `c` produz `ć` (c-acute) em vez de `ç`. O Compose do
sistema é que define isso; a correção é gerar um `~/.XCompose` pessoal que herda o do sistema
com as duas sequências trocadas.

Baseado em [gnome-cedilla-fix](https://github.com/marcopaganini/gnome-cedilla-fix)
(Marco Paganini) — a skill reimplementa o procedimento; não copie o script para o repo.

## Passos

### 1. Localizar o Compose do sistema para o locale atual
```bash
LANG=${LANG:-en_US.UTF-8}
COMPOSE_DIR=/usr/share/X11/locale
SYSTEM_COMPOSE="$COMPOSE_DIR/$(sed -ne "s/^\([^:]*\):[ \t]*$LANG/\1/p" \
  "$COMPOSE_DIR/compose.dir" | head -1)"
```
Se `$SYSTEM_COMPOSE` sair vazio ou o arquivo não existir, **pare**: o locale não tem Compose
instalado (não improvise um caminho). Verifique `locale` e o pacote `xorg-x11-xkb-utils`/
`libx11-locales` da distro.

### 2. Preservar um `.XCompose` existente
```bash
[ -s ~/.XCompose ] && cp -f ~/.XCompose ~/.XCompose.ORIGINAL
```

### 3. Gerar o `~/.XCompose` com ć→ç e Ć→Ç
```bash
sed -e 's/\xc4\x87/\xc3\xa7/g' -e 's/\xc4\x86/\xc3\x87/g' "$SYSTEM_COMPOSE" > ~/.XCompose
```
Os escapes são os bytes UTF-8 de `ć` (C4 87), `ç` (C3 A7), `Ć` (C4 86) e `Ç` (C3 87) — o `sed`
opera em bytes, então não dependem do locale do shell.

### 4. Aplicar
Logout/login da sessão gráfica (às vezes reinício do servidor X/Wayland). Só então teste
`'` + `c`.

## Gotchas

- **GTK4/GNOME recente** ignora `~/.XCompose` quando o input method é `ibus`. Se após o
  relogin a cedilha continuar errada, force o método simples para o app/sessão:
  ```bash
  GTK_IM_MODULE=xim   # ou "simple", conforme a distro
  ```
  Em GNOME, confira também Input Method = **Auto** nas Settings.
- **Flatpak/sandbox** não enxerga o `~/.XCompose` do host — o fix não vale para apps flatpak;
  configure o override do runtime ou aceite a limitação.
- **Wayland**: o Compose ainda é lido por GTK/Qt via libX11, mas compositores variam. Se
  falhar em Wayland e funcionar em Xorg, é isso.

## Reverter
```bash
rm ~/.XCompose && mv ~/.XCompose.ORIGINAL ~/.XCompose 2>/dev/null
```

## Relacionado
Passo de teclado do [[bootstrap-claude-machine]] — rode ao preparar uma máquina nova.
