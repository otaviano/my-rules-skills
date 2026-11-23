---
name: fix-cedilla-keyboard
description: Configura o teclado Linux (GNOME, Ubuntu ou Fedora) para que ' + c produza ç (cedilha) em vez de ć, via ~/.XCompose e GTK_IM_MODULE=cedilla. Use quando o usuário reclama que "a cedilha não funciona", digita ć sem querer, ou está preparando uma máquina nova com layout US-International para escrever em português.
license: MIT
---

# Cedilha no Linux (US-International / GNOME)

No layout **US-International** (`us+intl` ou `us+alt-intl`), `'` + `c` produz `ć` (c-acute) em
vez de `ç`. A correção tem duas partes, e é a combinação que funciona hoje no GNOME/Wayland:

1. **`~/.XCompose`**: cópia do Compose do sistema com `ć→ç` e `Ć→Ç`. Lido pelo IM simples do
   GTK3/GTK4, pelo ibus (que o GNOME usa no Wayland) e pelo Qt.
2. **`/etc/environment`**: `GTK_IM_MODULE=cedilla` e `QT_IM_MODULE=cedilla`. No Ubuntu, o GTK3
   tem o módulo `cedilla`; onde ele não existe (GTK4, Fedora), o toolkit cai no IM padrão, que
   lê o `~/.XCompose` do passo 1.

Baseado em [gnome-cedilla-fix](https://github.com/marcopaganini/gnome-cedilla-fix)
(Marco Paganini): a skill reimplementa o procedimento, não copia o script.

## Passos

```bash
bash scripts/fix-cedilla.sh --dry-run    # revisar
bash scripts/fix-cedilla.sh              # aplicar (sudo só no /etc/environment)
bash scripts/fix-cedilla.sh --no-system  # só ~/.XCompose, sem sudo
```
`scripts/` é relativo à pasta desta skill. Se precisar de `sudo`, passe o comando para o usuário
rodar no terminal. Depois: **logout/login** e teste `'` + `c` → `ç` e `'` + `C` → `Ç`.

O que o script faz, caso precise fazer à mão:

### 1. Localizar o Compose do sistema para o locale atual
```bash
COMPOSE_DIR=/usr/share/X11/locale
SYSTEM_COMPOSE="$COMPOSE_DIR/$(sed -ne "s/^\([^:]*\):[ \t]*${LANG:-en_US.UTF-8}\$/\1/p" \
  "$COMPOSE_DIR/compose.dir" | head -1)"
```
Se sair vazio, use o de `en_US.UTF-8`. Se nem ele existir, **pare**: falta o pacote
`libx11-data` (Ubuntu) ou `libX11-common` (Fedora). Não improvise caminho.

### 2. Gerar o `~/.XCompose` com ć→ç e Ć→Ç (backup antes)
```bash
[ -s ~/.XCompose ] && cp -n ~/.XCompose ~/.XCompose.ORIGINAL
sed -e 's/\xc4\x87/\xc3\xa7/g' -e 's/\xc4\x86/\xc3\x87/g' "$SYSTEM_COMPOSE" > ~/.XCompose
```
Os escapes são os bytes UTF-8 de `ć` (C4 87), `ç` (C3 A7), `Ć` (C4 86) e `Ç` (C3 87): o `sed`
opera em bytes, então não depende do locale do shell.

### 3. Forçar o IM cedilla
```bash
echo 'GTK_IM_MODULE=cedilla' | sudo tee -a /etc/environment
echo 'QT_IM_MODULE=cedilla'  | sudo tee -a /etc/environment
```
Se já houver uma linha `GTK_IM_MODULE=` (ex.: `ibus`), substitua em vez de duplicar.

## Gotchas
- **Continua saindo ć depois do relogin**: confira `echo $GTK_IM_MODULE` (tem que ser
  `cedilla`) e `grep -c 'ć' ~/.XCompose` (tem que ser 0). No Ubuntu, confira também se
  `im-config` não força outro método (`im-config -m`).
- **Flatpak/sandbox** não enxerga o `~/.XCompose` do host: o fix não vale para apps flatpak.
- **Atualização do libX11** pode mudar o Compose do sistema; rodar o script de novo regenera.

## Reverter
```bash
mv ~/.XCompose.ORIGINAL ~/.XCompose 2>/dev/null || rm ~/.XCompose
sudo sed -i '/^GTK_IM_MODULE=cedilla$/d; /^QT_IM_MODULE=cedilla$/d' /etc/environment
```

## Relacionado
Parte do [[setup-gnome-workstation]] e do passo de teclado do [[bootstrap-claude-machine]].
