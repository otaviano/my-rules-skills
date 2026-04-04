# my-rules-skills

An agnostic library of Claude Code rules and skills, organized by language and shared concerns. Drop the `.claude/` folder into any project to bring consistent AI-assisted development conventions.

## Directory Structure

```
.claude/
├── commands/           # Slash command shortcuts (invoke skills via /command-name)
├── shared/
│   ├── rules/          # Rules applied across all languages
│   ├── skills/         # Skills available in all projects
│   └── subagents/      # Specialized subagents used by shared skills
├── dotnet/
│   ├── rules/          # .NET-specific architecture and coding rules
│   └── skills/         # .NET-specific workflow skills
├── golang/
│   ├── rules/
│   └── skills/
├── python/
│   ├── rules/
│   └── skills/
└── react/
    ├── rules/
    └── skills/
```

## How to Use

Copy or symlink the `.claude/` folder into the root of any project:

```bash
# Copy
cp -r /path/to/my-rules-skills/.claude /path/to/your-project/

# Or symlink (keeps rules in sync)
ln -s /path/to/my-rules-skills/.claude /path/to/your-project/.claude
```

Claude Code will automatically pick up rules and skills from the `.claude/` directory.

## How Rules Work

Rules are Markdown files with YAML frontmatter stored under `rules/`. Claude Code loads them automatically based on the `applyTo` glob pattern.

```markdown
---
name: my-rule
description: What this rule does and when it applies.
applyTo: "**/*.{cs,ts}"
---

# Rule Title
...rule content...
```

- `applyTo` controls which files trigger the rule
- The `description` is used by Claude to decide relevance
- Rules in `shared/rules/` apply across all languages

## How Skills Work

Skills are Markdown files stored under `skills/<skill-name>/SKILL.md`. Invoke them in Claude Code with:

```
/skill-name
```

or by describing what you want to do — Claude will activate the matching skill automatically based on its `description`.

```markdown
---
name: my-skill
description: When and how to use this skill.
---

# Skill Title
...workflow steps...
```

## Adding New Rules

1. Create a `.md` file in the appropriate `rules/` directory
2. Add frontmatter with `name`, `description`, and `applyTo`
3. Write the rule content in Markdown

## Adding New Skills

1. Create a folder under the appropriate `skills/` directory
2. Add a `SKILL.md` file with frontmatter (`name`, `description`)
3. Write the workflow steps in Markdown

## Current Rules

### Shared
| Rule | Description |
|------|-------------|
| [clean-code-uncle-bob](.claude/shared/rules/clean-code-uncle-bob.md) | Clean Code principles (Uncle Bob) |
| [solid](.claude/shared/rules/solid.enforcer.md) | SOLID principles enforcer |
| [object-calisthenics](.claude/shared/rules/object.calisthenics.enforcer.md) | Nine rules of Object Calisthenics |

### .NET
| Rule | Description |
|------|-------------|
| [dotnet-conventions](.claude/dotnet/rules/dotnet.conventions.md) | .NET coding conventions |
| [dotnet-clean-architecture](.claude/dotnet/rules/dotnet.instructions.md) | Clean Architecture with Brighter/Darker and Minimal API |

### Go
| Rule | Description |
|------|-------------|
| [golang-conventions](.claude/golang/rules/golang.conventions.md) | Naming, formatting, error handling, concurrency, and testing (Effective Go + Google Style) |
| [golang-project-structure](.claude/golang/rules/golang.project-structure.md) | Package layout, dependency injection, module conventions |

### Python
| Rule | Description |
|------|-------------|
| [python-conventions](.claude/python/rules/python.conventions.md) | Naming, formatting, type hints, error handling, logging, and testing (PEP 8/257/20) |
| [python-project-structure](.claude/python/rules/python.project-structure.md) | src layout, pyproject.toml, uv, dependency injection, architecture layers |

### React
| Rule | Description |
|------|-------------|
| [react-conventions](.claude/react/rules/react.conventions.md) | Component purity, hooks rules, state, effects, props, TypeScript, and accessibility (react.dev) |
| [react-project-structure](.claude/react/rules/react.project-structure.md) | Feature-slice layout, state architecture, data fetching, routing, and tooling |

## Current Skills

### Shared
| Skill | Description |
|-------|-------------|
| [code-review](.claude/shared/skills/code-review/SKILL.md) | Analyzes recent changes for security, performance, quality, test coverage, and design patterns |
| [pull-request](.claude/shared/skills/pull-request/SKILL.md) | Prepares and creates a pull request following conventional commits, running tests and code review first |
| [test-runner](.claude/shared/skills/test-runner/SKILL.md) | Runs tests, analyzes coverage gaps, writes missing tests, and validates mutation score |

### .NET
| Skill | Description |
|-------|-------------|
| [dotnet-clean-architecture](.claude/dotnet/skills/dotnet-clean-architecture/SKILL.md) | Workflow for implementing features following Clean Architecture |

### Go
| Skill | Description |
|-------|-------------|
| [golang-feature](.claude/golang/skills/golang-feature/SKILL.md) | Workflow for implementing features (domain → service → repository → handler → tests) |

### Python
| Skill | Description |
|-------|-------------|
| [python-feature](.claude/python/skills/python-feature/SKILL.md) | Workflow for implementing features (domain → service → repository → API endpoint → tests) |

### React
| Skill | Description |
|-------|-------------|
| [react-feature](.claude/react/skills/react-feature/SKILL.md) | Workflow for implementing features (types → API → hooks → components → page → tests) |
