---
name: bootstrap-claude-machine
description: Configura uma máquina nova com o ambiente Claude do usuário — dotfiles (chezmoi), plugin marketplace de skills e vault Obsidian sincronizado. Use ao preparar um computador novo, reinstalar o SO ou trocar de máquina ("setup do zero", "bootstrap", "máquina nova").
license: MIT
---

# Bootstrap de máquina Claude

Orquestra a configuração de uma máquina nova para deixar o ambiente Claude completo e portável.
Modelo híbrido em 3 camadas: **config** (dotfiles/chezmoi) + **skills** (plugin marketplace) +
**notas** (Obsidian Git).

## Pré-requisitos
- `git` e `gh` instalados; `gh auth status` autenticado.
- Acesso aos repos do usuário (dotfiles privado, marketplace de skills, vault).
- Confirme os nomes dos repos antes (não invente): peça/derive `owner/repo` de cada um.

## Passos

### 1. Config do Claude via chezmoi (dotfiles)
```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin     # instala chezmoi
chezmoi init --apply <owner>/dotfiles                       # pergunta segredos (ex: NOTION_TOKEN)
```
- Garanta que `~/.local/bin` está no PATH (senão, ajuste no perfil do SO).
- Valide: `chezmoi diff` deve sair vazio; confira `~/.claude/{CLAUDE.md,settings.json,mcp.json}`.
- **Sandbox (flatpak/containers)**: o `XDG_DATA_HOME`/`XDG_CONFIG_HOME` pode estar desviado
  (ex.: `~/.var/app/.../`). Force os padrões reais ao rodar fora do terminal nativo:
  `XDG_DATA_HOME=~/.local/share XDG_CONFIG_HOME=~/.config chezmoi ...`.

### 2. Skills via plugin marketplace
No Claude Code:
```
/plugin marketplace add <owner>/my-rules-skills
/plugin install otaviano-core@otaviano-rules-skills
```
- Confirme com `/plugin` que o plugin está enabled e as skills aparecem.
- Atualizações futuras: `/plugin marketplace update`.

### 3. Vault Obsidian (notas/ADRs)
- Delegue à skill [[obsidian-git-setup]] (clone do vault + plugin Git + PAT + auto-sync).

### 4. Validação final
- `chezmoi diff` vazio; `claude` lê settings/mcp; plugin instalado; vault sincroniza.
- Liste o que ficou pendente de credencial (tokens, chaves OAuth) para o usuário preencher.

## Guardrails
- **Nunca** commitar segredos: rode [[audit-secrets-before-commit]] antes de versionar qualquer coisa.
- Segredos entram por prompt/secret manager do chezmoi, nunca no git.
- Paths específicos de SO viram template (`{{ .chezmoi.homeDir }}`), nunca hardcoded.
- Faça backup de `~/.claude/{settings.json,CLAUDE.md}` antes de sobrescrever.
