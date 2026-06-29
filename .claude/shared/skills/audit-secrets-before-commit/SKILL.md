---
name: audit-secrets-before-commit
description: Varre arquivos por segredos (tokens, chaves, senhas) e por paths não-portáveis antes de versionar, especialmente em repositórios públicos. Use antes de um primeiro commit, ao adicionar config/dotfiles ao git, ou quando o usuário pede para "checar se não tem segredo" / "pode commitar isso?".
license: MIT
---

# Auditoria de segredos antes do commit

Defesa contra vazar credenciais e contra versionar caminhos que só funcionam numa máquina.
Rode **antes** de `git add`/commit — sobretudo em repo **público**.

## Passos

### 1. Determinar o risco
```bash
gh repo view <owner>/<repo> --json visibility --jq .visibility   # PUBLIC eleva o rigor
```
Repo público = qualquer segredo exposto deve ser considerado comprometido (rotacionar).

### 2. Varrer por segredos
Procure **nomes de chave** sensíveis e **valores** com formato de credencial:
```bash
# nomes de chave (JSON/YAML/env)
grep -rInE '"[^"]*(token|secret|api[_-]?key|password|passwd|bearer|authorization|client[_-]?secret)[^"]*"\s*:' .
# formatos de valor conhecidos
grep -rInE 'ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|xox[baprs]-[A-Za-z0-9-]+|sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|ntn_[A-Za-z0-9]{20,}|-----BEGIN [A-Z ]*PRIVATE KEY-----' .
```
- Para JSON, distinga **chave** de **valor**: percorra a árvore e reporte o *caminho* da chave
  sensível **sem imprimir o valor**.
- Cuidado com falso-positivo: a palavra "password" pode estar em string inócua (ex.: comando de
  teste, mensagem de commit). Inspecione o contexto antes de alarmar.

### 3. Varrer por paths não-portáveis
```bash
grep -rInE '[A-Za-z]:\\|/c/Users/|/Users/[^/]+/|/home/[^/]+/' .   # Windows / homedir hardcoded
```
Esses quebram em outra máquina/SO — devem virar template ou variável (`$HOME`, `{{ .chezmoi.homeDir }}`).

### 4. Conferir a malha de proteção do repo
- `.gitignore` cobre: `.env*`, `*.pem`, `*.key`, `.credentials.json`, `chezmoi.toml`, dumps/backups.
- Nada sensível já **rastreado**: `git ls-files | grep -iE 'env|secret|credential|\.pem$|\.key$'`.

### 5. Remediar (não apenas reportar)
- Segredo: externalizar (template + prompt/secret manager, env var, ou arquivo não-versionado) e,
  se já vazou em repo público/remoto, **rotacionar o token**.
- Path: parametrizar por variável/template.
- Guard final, só nos arquivos staged:
  ```bash
  git diff --cached | grep -InE 'ghp_|github_pat_|sk-|AKIA|ntn_|PRIVATE KEY' && echo "ABORTAR" || echo "ok"
  ```

## Saída
Relatório curto: nível de risco (público?), achados (segredos / paths) com caminho mas **sem expor
valores**, e as ações de remediação aplicadas. Conclua com "seguro para commitar" só após o guard final passar.
