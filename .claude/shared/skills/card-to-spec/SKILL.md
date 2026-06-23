---
name: card-to-spec
description: Detalha interativamente um card (ex.: Notion) e o transforma num change OpenSpec pronto para implementar, atualizando o card de volta com o detalhamento. Use quando o usuário quer "detalhar um card", "transformar card em spec", "preparar card pro openspec" ou passa uma URL/ID de card do Notion.
license: MIT
---

# Card → Spec (OpenSpec)

Workflow interativo que pega um card de backlog vago e produz:
1. Um **change OpenSpec** local (`openspec/changes/<id>/`) pronto para `/opsx:apply`.
2. (Se houver decisão arquitetural) um **rascunho de ADR** (`docs/adr/ADR-NNN-*.md`, status Proposto).
3. O **card atualizado** com contexto, escopo e critérios de aceite estruturados.

> Requer o OpenSpec CLI no repo alvo (`npx openspec --version`). Se `openspec/` não existir,
> rode `npx openspec init --tools claude` antes (ou avise o usuário).

## Pré-condições

- Estar no repositório de código alvo (onde vive `openspec/`).
- Ferramenta de leitura do card disponível (Notion MCP: `API-retrieve-page-markdown`,
  `API-retrieve-a-page`, `API-update-page-markdown`). Se não houver, peça ao usuário o
  conteúdo do card colado.

## Passos

### 1. Resolver e ler o card
- Receba a URL/ID do card (ou o título). Da URL do Notion, extraia o `page_id` (o hash do
  parâmetro `p=` ou do final do path).
- Leia o card: `API-retrieve-a-page` (título + properties) e `API-retrieve-page-markdown`
  (corpo). Se o corpo estiver vazio, trabalhe a partir do título + perguntas.

### 2. Reunir contexto (não pergunte o que dá pra descobrir)
- Leia as **specs existentes**: `openspec/specs/*/spec.md` (capabilities atuais).
- Leia os **ADRs**: índice em `docs/adr/README.md` + o ADR relevante.
- Investigue o **código** relacionado (handlers, endpoints, componentes) para entender o
  estado atual e nomear a capability afetada.
- Se houver vault/notas do projeto, consulte para decisões e gotchas.

### 3. Fechar lacunas com perguntas (AskUserQuestion)
Faça apenas as perguntas que o contexto não respondeu. Cubra:
- **Problema / motivação** — por que agora? que dor resolve?
- **Escopo** e **fora de escopo** explícito.
- **Capability**: é nova (`### New Capabilities`) ou modifica uma existente de
  `openspec/specs/`? (delta MODIFIED vs ADDED).
- **Critérios de aceite** verificáveis (viram Scenarios WHEN/THEN).
- **Decisão arquitetural?** Se introduz/!muda um padrão, dependência externa ou modelo de
  dados → vai gerar ADR.

Prefira decidir com defaults sensatos e seguir; só pergunte o que muda o resultado.

### 4. Gerar o change OpenSpec
- Derive um nome kebab-case do card (ex.: "Histórico de faturas" → `add-invoice-history`).
- Crie o change e os artefatos. Caminho recomendado: delegar pro fluxo nativo
  **`/opsx:propose "<descrição>"`** (gera proposal/design/tasks). Alternativa manual:
  ```bash
  npx openspec new change "<name>"
  ```
  e preencha, conforme o schema `spec-driven`:
  - `proposal.md` — Why / What Changes / Capabilities (New e Modified) / Impact.
  - `specs/<capability>/spec.md` — deltas com `## ADDED|MODIFIED|REMOVED Requirements`,
    `### Requirement:` (SHALL/MUST) e `#### Scenario:` (exatamente 4 `#`, WHEN/THEN).
  - `design.md` — só se cross-cutting/nova dependência/decisão; senão omita.
  - `tasks.md` — checklist `- [ ] N.M ...` por dependência.
- Valide: `npx openspec validate <name>` (deve passar antes de seguir).

### 5. Rascunhar ADR se houver decisão
- Se o passo 3 indicou decisão arquitetural, crie `docs/adr/ADR-NNN-slug.md` (próximo NNN
  pelo índice), **status Proposto**, no formato MADR (Contexto / Decisão / Alternativas /
  Consequências / Referências com `[[wikilinks]]`). Linke a capability do change.
- Atualize `docs/adr/README.md` (índice).

### 6. Atualizar o card
- Escreva de volta no card (`API-update-page-markdown`) um detalhamento estruturado:
  **Contexto**, **Escopo**, **Fora de escopo**, **Critérios de aceite**, e o link/nome do
  change OpenSpec (`openspec/changes/<name>`) e do ADR, se houver.
- Não apague o conteúdo original do usuário — complemente.

## Saída
Resuma para o usuário: nome/local do change, capabilities afetadas, se gerou ADR, e que o
card foi atualizado. Aponte o próximo passo: `/opsx:apply` (ou "me peça para implementar").

## Guardrails
- Nunca invente comportamento: derive specs do código + respostas do usuário.
- Não modifique código de produção neste fluxo — só artefatos de spec/ADR/card.
- Um change por card; se já existir change com o nome, pergunte se continua ou cria novo.
- Sempre rode `openspec validate` antes de declarar pronto.
