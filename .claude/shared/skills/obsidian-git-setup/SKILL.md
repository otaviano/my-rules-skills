---
name: obsidian-git-setup
description: Configura sincronização gratuita de um vault Obsidian via Git (GitHub como hub), no desktop e no celular, com higiene de estado local e autenticação por PAT. Use ao preparar sync de notas/ADRs do Obsidian, ao abrir o vault numa máquina nova, ou quando o usuário fala em "sincronizar o Obsidian de graça".
license: MIT
---

# Setup de sync do Obsidian via Git

Sync gratuito e versionado usando o GitHub como hub central (assíncrono — não exige os
dispositivos online ao mesmo tempo). Vault de markdown leve é o caso ideal.

## Passos

### 1. Vault = repositório git clonado
O vault precisa ser o repo **clonado**, não uma pasta solta:
```bash
gh repo clone <owner>/<vault-repo> ~/<vault>
```

### 2. Higiene de estado local (.gitignore)
Estado por-dispositivo gera conflito — ignore; mas **versione** a config compartilhável:
```gitignore
.obsidian/workspace.json
.obsidian/workspace-mobile.json
.obsidian/cache
.trash/
.obsidian/plugins/        # cada dispositivo instala o próprio binário
```
- **Versione** `.obsidian/community-plugins.json` (lista de plugins) e `app/appearance/core-plugins/graph`.
- Se `workspace.json` já estiver rastreado: `git rm --cached .obsidian/workspace.json`.

### 3. Plugin Git no desktop
- Community plugin **"Git"** (autor **Vinzent03** — foi renomeado de "Obsidian Git"; busque por
  `Vinzent` se "Obsidian Git" não aparecer).
- Settings: *Pull on startup* ✅, *Pull before push* ✅, *Auto commit-and-sync* a cada ~10 min.

### 4. Autenticação por PAT
Crie um **PAT fine-grained** restrito ao repo do vault, *Contents: Read and write*.
- Em **flatpak/sandbox** o plugin não acessa o credential helper do sistema — embuta o token no remote:
  ```bash
  git -C ~/<vault> remote set-url origin "https://<user>:<PAT>@github.com/<owner>/<vault>.git"
  ```
  (fica em `.git/config` local, não versionado). Valide: `git ls-remote --heads origin` (exit 0).

### 5. Celular
- **Android**: mesmo plugin "Git" (Vinzent03) → comando *Clone an existing remote repository* + PAT.
- **iOS**: o plugin do Vinzent costuma travar; prefira uma alternativa multi-plataforma baseada na
  API do GitHub (ex.: "Fit") no celular, mantendo o "Git" só no desktop.

### 6. Validar ponta a ponta
Crie uma nota de teste → `Git: Commit-and-sync` → confirme o commit no remoto
(`git -C ~/<vault> fetch && git log origin/main --oneline -1`). Depois **apague** a nota e
sincronize de novo, confirmando que a exclusão também propaga.

## Guardrails
- Nunca versione `.obsidian/workspace*.json` (conflito garantido entre máquinas).
- PAT mínimo (um repo, escopo Contents); nunca commite o token.
- Conflito raro de edição simultânea offline: `Pull before push` + commits frequentes mitigam.
