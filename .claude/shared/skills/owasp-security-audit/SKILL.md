---
name: owasp-security-audit
description: Audita uma app/PR contra o OWASP Top 10 (2021) e o OWASP API Security Top 10 (2023) — valida vulnerabilidades e qualidade de segurança, classifica achados por severidade e propõe remediação acionável. Use quando o usuário pede para "revisar segurança", "checar vulnerabilidades", "auditar OWASP", "validar a qualidade de segurança" de uma app, endpoint, API ou PR. Aplica-se a .NET, Go, Python e Node/React.
license: MIT
---

# Auditoria de segurança OWASP

Valida uma aplicação (ou as mudanças de um PR) contra **OWASP Top 10 2021** + **OWASP API Security Top 10 2023**.
Não é varredura genérica: cada achado é mapeado a um item OWASP, classificado por severidade e acompanhado de remediação.

Para vazamento de segredos no commit, use [[audit-secrets-before-commit]] — esta skill foca em vulnerabilidades de design/código.

## Como conduzir

### 1. Definir escopo e superfície de ataque
- **PR vs app inteira**: se há branch de trabalho, audite o diff (`git diff main...HEAD`); senão, varra o projeto.
- Mapeie a superfície: endpoints HTTP, autenticação/autorização, dados sensíveis (PII, credenciais), integrações externas, upload/fetch de URLs, dependências.
- Identifique a stack (.NET / Go / Python / Node-React) para aplicar os gotchas certos abaixo.

Priorize código que toca **endpoints, auth ou dados sensíveis** — é onde o risco se concentra.

### 2. Varrer por categoria (com sinais de detecção)

Para cada categoria, busque o sinal e **valide manualmente o contexto** antes de reportar (grep gera falso-positivo).

**A01/API01/API05 — Broken Access Control / BOLA / Function Level Auth** ⭐ (mais comum)
- Endpoint recebe `id`/objeto e busca sem checar **ownership** contra o usuário autenticado.
- Endpoint privilegiado sem `[Authorize]`/middleware de role.
```bash
# handlers que recebem id — checar se há validação de ownership logo abaixo
grep -rInE '\{id\}|GetById|FindById|/:id|GetAsync\(id' --include=*.cs --include=*.go --include=*.py --include=*.ts .
grep -rInE 'AllowAnonymous|\.Authorize\(|@app.route|router\.(get|post|delete)' .
```
Valide: todo acesso a recurso por ID confere `recurso.OwnerId == currentUser`? Endpoints admin exigem role? Deny-by-default?

**A02 — Cryptographic Failures**
```bash
grep -rInE 'MD5|SHA1|DES\b|TripleDES|RC4|new Random\(\)|http://' .
grep -rInE 'BCrypt|Argon2|PBKDF2|HashPassword' .   # ausência em fluxo de senha = red flag
```
Valide: senhas com bcrypt/argon2 (nunca MD5/SHA1); TLS 1.2+ e HSTS; sem dados sensíveis armazenados sem necessidade.

**A03 — Injection (SQLi, Command, XSS)**
```bash
grep -rInE 'FromSqlRaw|ExecuteSqlRaw|string\.Format.*SELECT|\$"SELECT|f"SELECT|`SELECT.*\$\{|exec\(|os\.system|child_process|dangerouslySetInnerHTML' .
```
Valide: queries parametrizadas; sem concatenação de input em SQL/shell; output encoding/CSP contra XSS; React sem `dangerouslySetInnerHTML` com dado de usuário.

**A04/API06 — Insecure Design / Abuso de fluxos críticos**
- Não é grep — é raciocínio. Fluxos de negócio que permitem bypass (pular pagamento via parâmetro), criação em massa, ausência de limites de negócio.
- Valide: há threat modeling (STRIDE) e casos de abuso para a feature crítica? Defense-in-depth, fail-secure, least-privilege.

**A05/API08 — Security Misconfiguration**
```bash
grep -rInE 'IsDevelopment|UseSwagger|AllowAnyOrigin|AllowAnyHeader|DetailedErrors|DEBUG\s*=\s*True|app.run\(.*debug=True' .
```
Valide: Swagger/debug só em dev; stack trace desligado em prod; CORS restrito (sem `AllowAnyOrigin`); headers de segurança presentes (X-Content-Type-Options, X-Frame-Options, Referrer-Policy); sem credencial default.

**A06 — Vulnerable & Outdated Components**
```bash
dotnet list package --vulnerable --include-transitive 2>/dev/null   # .NET
npm audit --omit=dev 2>/dev/null                                    # Node/React
pip-audit 2>/dev/null || safety check 2>/dev/null                   # Python
govulncheck ./... 2>/dev/null                                       # Go
```
Valide: sem CVEs conhecidos; lock files presentes; checagem no pipeline CI.

**A07/API02 — Authentication Failures**
- Valide: rate limiting/lockout em login; JWT com `ValidateIssuerSigningKey`+`ValidateLifetime` e `ClockSkew` curto; TTL curto + refresh rotation; invalidação no logout; MFA em contas sensíveis.
```bash
grep -rInE 'ValidateLifetime|ValidateIssuerSigningKey|ClockSkew|jwt\.decode\(.*verify=False|algorithms.*none' .
```

**A08 — Software & Data Integrity Failures**
- Valide: lock files (`packages.lock.json`, `package-lock.json`, `go.sum`, `poetry.lock`); CI com least-privilege; artefatos assinados/hashes verificados.

**A09 — Security Logging & Monitoring Failures**
- Valide: falhas de auth (401) e autorização (403), inputs inválidos e operações sensíveis (delete, mudança de role) são logadas **com contexto** (userId, IP, endpoint).
- **Anti-padrão**: senha/token/PII em log. `grep -rInE 'log.*(password|token|secret|ssn|cpf)'`

**A10/API07 — SSRF**
```bash
grep -rInE 'HttpClient|fetch\(|requests\.(get|post)|http\.Get|urllib' . | grep -iE 'url|uri|host|endpoint'
```
Valide: fetch de URL fornecida pelo usuário usa **allowlist** de domínios; ranges privados bloqueados (169.254.169.254, 10.x, 172.16.x, 192.168.x); webhooks validados.

**API03 — Broken Object Property Level Auth (Mass Assignment / Excessive Exposure)**
- Valide: entidade nunca retornada/aceita diretamente — usar **DTOs** explícitos (input e output); sem `passwordHash`/`role`/campos internos no response; allowlist de campos no update.
```bash
grep -rInE 'return Ok\((user|entity|model)\)|res\.json\((user|entity)\)' .
```

**API04 — Unrestricted Resource Consumption**
- Valide: rate limiting por IP/usuário; tamanho máximo de payload; **paginação obrigatória** em listagens; timeouts em integrações externas.

**API09 — Improper Inventory Management**
- Valide: sem endpoints de debug/test ou versões depreciadas expostas em prod; inventário de versões ativas.

**API10 — Unsafe Consumption of APIs**
- Valide: dados de APIs externas tratados como input não confiável (validar/sanitizar); **nunca** desabilitar verificação de certificado SSL (`ServerCertificateCustomValidationCallback => true`, `verify=False`, `rejectUnauthorized:false`); timeouts e circuit breakers.

### 3. Classificar achados
Severidade por impacto × facilidade de exploração:
- **Crítico** — BOLA/IDOR explorável, SQLi, auth bypass, secret exposto, SSRF para metadata cloud.
- **Alto** — falta de rate limiting em auth, CORS aberto, mass assignment, JWT sem validação de assinatura.
- **Médio** — logging insuficiente, headers ausentes, dependência com CVE médio.
- **Baixo** — hardening/defense-in-depth, melhorias de inventário.

### 4. Relatório
Para cada achado:
```
[SEVERIDADE] <Categoria OWASP> — <título>
Local:    arquivo.cs:42
Risco:    o que um atacante consegue fazer
Correção: mudança concreta (com snippet quando útil)
```
Feche com o **checklist de PR** (item 5) marcado e um veredito: bloquear merge (há crítico/alto) ou liberar com ressalvas.

### 5. Checklist de code review (rodar sempre em PR que toca endpoint/auth/dados)
- [ ] Endpoint verifica ownership do recurso (BOLA/IDOR)?
- [ ] Input parametrizado / DTO explícito no input **e** output?
- [ ] Dados sensíveis ausentes de logs e responses?
- [ ] Rate limiting aplicado no endpoint?
- [ ] Tokens com expiração + validação de assinatura?
- [ ] CORS restrito ao necessário?
- [ ] Stack trace / Swagger desabilitado em produção?
- [ ] Secrets fora do código (env vars / vault)?
- [ ] Dependências sem vulnerabilidades conhecidas?
- [ ] Falhas de autorização sendo logadas?
- [ ] Paginação obrigatória em listagens?
- [ ] Timeout + verificação de cert em chamadas externas?

## Labs e referências
PortSwigger Web Security Academy, [crAPI](https://github.com/OWASP/crAPI) (APIs), [WebGoat](https://github.com/WebGoat/WebGoat), [Microsoft Threat Modeling Tool](https://aka.ms/threatmodelingtool). Base: OWASP Top 10 2021 + OWASP API Security Top 10 2023.
