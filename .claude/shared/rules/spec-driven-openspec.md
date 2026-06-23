---
name: spec-driven-openspec
description: Fluxo Spec-Driven Development com OpenSpec + ADRs. Aplica-se a projetos com pasta openspec/ — quando/como criar specs, changes e ADRs, e onde cada artefato mora.
applyTo: "**/openspec/**,**/docs/adr/**"
---

# Spec-Driven Development (OpenSpec) + ADRs

Projetos com `openspec/` usam Spec-Driven Development. Antes de implementar mudança
não-trivial, gere a spec; antes de tomar decisão arquitetural, registre um ADR.

## Onde cada artefato mora

| Artefato | Local | Para quê |
|---|---|---|
| Specs vivas por capability | `openspec/specs/<cap>/spec.md` | O **quê** o sistema faz hoje (baseline) |
| Mudanças propostas | `openspec/changes/<id>/` (`proposal.md`, `specs/` deltas, `design.md`, `tasks.md`) | O **quê vai mudar**, antes de codar |
| Contexto do projeto | `openspec/config.yaml` (campo `context`) | Injetado nas instruções dos artefatos |
| ADRs (log de decisão) | `docs/adr/ADR-NNN-*.md` (MADR-lite) | O **porquê** de cada decisão arquitetural |

ADRs podem ser espelhados num vault Obsidian via junction; a fonte canônica é o repo.

## Quando usar o quê

- **Mudança de comportamento de uma capability** → crie um **change** OpenSpec (não edite a
  spec baseline direto; o delta é aplicado à baseline no `archive`).
- **Decisão arquitetural** (novo padrão, dependência externa, mudança de modelo de dados,
  trade-off de segurança/performance) → escreva um **ADR**. Um change pode referenciar um ADR.
- **Card de backlog vago** → use a skill `card-to-spec` para detalhar e gerar o change.

## Fluxo de uma mudança

1. `/opsx:propose "<ideia>"` (ou `npx openspec new change <name>`) → gera artefatos.
2. Revise proposal → specs (deltas) → design (se necessário) → tasks.
3. `npx openspec validate <name>` deve passar.
4. `/opsx:apply` para implementar as tasks.
5. `/opsx:archive` ao concluir (aplica os deltas às specs baseline).

## Formato de spec (validável)

- Baseline: `## Purpose` + `## Requirements`.
- `### Requirement: <nome>` com texto normativo usando **SHALL/MUST** (evite should/may).
- `#### Scenario: <nome>` com **exatamente 4 `#`**, em formato `- **WHEN** ...` / `- **THEN** ...`.
- Todo requirement tem ao menos um scenario.
- Deltas (em changes): `## ADDED|MODIFIED|REMOVED|RENAMED Requirements`. MODIFIED carrega o
  bloco **inteiro** atualizado; REMOVED inclui **Reason** e **Migration**.

## Formato de ADR (MADR-lite)

`ADR-NNN-slug.md` com: **Status** (Proposto→Aceito→Substituído) / **Data** / **Projeto** /
Contexto / Decisão / Alternativas Consideradas / Consequências (Positivas/Negativas) /
Referências (`[[wikilinks]]` + caminhos de spec). Numeração sequencial; mantenha o índice
em `docs/adr/README.md`.

## Acesso de agentes

ADRs entram no contexto via **índice lazy** no `CLAUDE.md` (título + caminho), lidos sob
demanda — **não** via `@import` eager (evita inflar o contexto). Specs e changes são lidos
pelo fluxo `opsx`/`openspec`.
