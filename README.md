# my-rules-skills

An agnostic library of Claude Code rules and skills, organized by language and shared concerns. Drop the `.claude/` folder into any project to bring consistent AI-assisted development conventions.

## Directory Structure

```
.claude/
├── shared/
│   ├── rules/          # Rules applied across all languages
│   └── skills/         # Skills available in all projects
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

## Current Skills

### .NET
| Skill | Description |
|-------|-------------|
| [dotnet-clean-architecture](.claude/dotnet/skills/dotnet-clean-architecture/SKILL.md) | Workflow for implementing features following Clean Architecture |
