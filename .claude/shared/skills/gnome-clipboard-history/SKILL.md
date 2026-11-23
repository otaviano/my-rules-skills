---
name: gnome-clipboard-history
description: Configura histórico de área de transferência no Super+V no GNOME (Ubuntu ou Fedora), como o Win+V do Windows — popup no ponteiro, prévia de texto/imagem/link e colar ao escolher. Usa a extensão Copyous (GNOME 48+) ou Clipboard Indicator (GNOME 44–47). Use quando o usuário quer "Win+V no Linux", "histórico do clipboard", "copiar/colar empilhado" ou ao preparar uma máquina nova.
license: MIT
---

# Super+V com histórico do clipboard no GNOME

O GNOME não tem histórico de clipboard nativo, e por padrão o `Super+V` abre a lista de
notificações. Apps externos (CopyQ etc.) funcionam mal no Wayland: não têm atalho global nem
acesso confiável ao clipboard. Uma **extensão do GNOME Shell** roda dentro do compositor e não
tem esses problemas.

| GNOME | Extensão | Experiência |
|-------|----------|-------------|
| 48+ (Fedora 42+, Ubuntu 25.04+) | [Copyous](https://github.com/boerdereinar/copyous) | popup no ponteiro, cards com prévia de imagem/link/código, cola ao escolher |
| 44–47 (Ubuntu 24.04) | [Clipboard Indicator](https://github.com/Tudmotu/gnome-shell-extension-clipboard-indicator) | menu na barra do topo, cola ao escolher |

Descartadas: Clipboard History (alexsaveau) está em modo manutenção; Pano parou no GNOME 45.

## Passos
```bash
bash scripts/clipboard.sh --dry-run
bash scripts/clipboard.sh                # instala deps (sudo), extensão e configura
bash scripts/clipboard.sh --indicator    # força o Clipboard Indicator
```
`scripts/` é relativo à pasta desta skill. O script:
1. instala as dependências do Copyous (`libgda` com SQLite e `GSound`); usa `sudo`;
2. instala a extensão por `InstallRemoteExtension` no D-Bus do **GNOME Shell**
   (`--dest org.gnome.Shell`, e não `org.gnome.Shell.Extensions`, que é o app Extensões).
   O GNOME baixa a extensão do extensions.gnome.org e mostra um diálogo: o usuário clica em
   **Install**;
3. tira o `<Super>v` de `org.gnome.shell.keybindings toggle-message-tray` (fica só `<Super>m`);
4. configura a extensão via `GSETTINGS_SCHEMA_DIR=<pasta da extensão>/schemas`.

O script pede senha do `sudo` e depende de um clique no diálogo, então **o usuário roda no
terminal dele**, não pelo Bash tool. Antes, diga que o download é de ~370 KB, vem do
extensions.gnome.org e precisa de confirmação.

Depois: **logout/login uma vez**. Então copie 2–3 coisas e teste `Super+V` → `Enter`.

### Configuração do Copyous
| Chave | Valor | Por quê |
|-------|-------|---------|
| `open-clipboard-dialog-shortcut` | `['<Super>v']` | atalho do Windows |
| `paste-on-copy` | `true` | escolher cola no app em foco |
| `incognito` | `false` | anônimo ligado = nada é gravado ("Clipboard is Empty") |
| `show-at-pointer` / `show-at-cursor` | `true` / `false` | no Wayland muitos apps não informam o cursor de texto; aí o popup cai numa faixa de tela inteira no topo |
| `clipboard-orientation`, `clipboard-size` | `vertical`, `420` | lista estreita, como o Win+V |
| `clipboard-position-*` | `center` | fallback quando não há ponteiro |

## Gotchas
- **"Clipboard is Empty" mesmo copiando**: modo anônimo ligado. É o botão com chapéu/óculos
  no popup ou o atalho `Super+Ctrl+Shift+V`.
- **Extensão em `ERROR` com "Extension point conflict: there is already a status indicator"**:
  aconteceu depois de ativar/reativar na mesma sessão em que foi instalada. A instância antiga
  continua rodando e o GNOME não reativa uma extensão em `ERROR`. Não insista em
  `disable`/`enable`: faça logout/login. Para recuperar o ícone sem relogar, rode no Looking
  Glass (`Alt+F2` → `lg`): `Main.panel.statusArea['copyous@boerdereinar.dev']?.destroy()`.
  O histórico funciona mesmo nesse estado.
- **No Wayland não dá para reiniciar o GNOME Shell** (`Alt+F2 r` só existe no X11): reiniciar
  derruba a sessão inteira.
- **`JS ERROR … highlight.min.js`** no log: o highlight.js (cores em trechos de código) é
  baixado sob demanda pelo próprio Copyous. Sem ele, o código só aparece sem cor.
- **Senhas**: exclua o gerenciador de senhas do histórico (`wmclass-exclusions`, ex.:
  `['KeePassXC', 'Bitwarden']`) ou use o modo anônimo.
- **Colar no terminal**: o Clipboard Indicator envia `Ctrl+Shift+Insert` para terminais; alguns
  (tmux, Ghostty) precisam de bind. Veja o README da extensão.
- **CopyQ instalado** (`copyq-clipboard@hluk.github.com`): desative a extensão dele para não
  haver dois gerenciadores disputando o clipboard.

## Reverter
```bash
gnome-extensions disable copyous@boerdereinar.dev   # ou clipboard-indicator@tudmotu.com
gsettings reset org.gnome.shell.keybindings toggle-message-tray
```

## Relacionado
Parte do [[setup-gnome-workstation]].
