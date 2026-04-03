---
name: python-project-structure
description: Python project layout, package organization, dependency management, and tooling conventions based on modern Python standards (pyproject.toml, uv, src layout).
applyTo: "**/*.{py,toml,cfg,ini}"
---

# Python Project Structure & Package Organization

## Recommended Layout (src layout)

```
my_project/
├── pyproject.toml          # Single source of truth for project metadata and tooling
├── uv.lock                 # Lock file (uv) — commit this for reproducible installs
├── README.md
├── src/
│   └── my_package/
│       ├── __init__.py
│       ├── domain/         # Pure business logic; no framework dependencies
│       │   ├── __init__.py
│       │   ├── models.py
│       │   └── exceptions.py
│       ├── service/        # Orchestration; depends on domain + ports (interfaces)
│       │   ├── __init__.py
│       │   └── order_service.py
│       ├── repository/     # Data access implementations
│       │   ├── __init__.py
│       │   └── order_repository.py
│       ├── api/            # HTTP layer (FastAPI / Flask routers)
│       │   ├── __init__.py
│       │   └── routers/
│       └── config.py       # Configuration loading (pydantic-settings or dataclasses)
└── tests/
    ├── conftest.py         # Shared fixtures
    ├── unit/
    │   └── test_order_service.py
    └── integration/
        └── test_order_repository.py
```

## pyproject.toml (Modern Standard)

```toml
[project]
name = "my_package"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = [
    "fastapi>=0.111",
    "pydantic>=2.0",
]

[project.optional-dependencies]
dev = ["pytest", "pytest-cov", "mypy", "ruff"]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.ruff]
line-length = 79
select = ["E", "F", "I", "UP", "B"]

[tool.mypy]
strict = true
python_version = "3.12"

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "--tb=short -q"
```

## Dependency Management
- Use `uv` as the primary tool: `uv add <package>`, `uv sync`, `uv run`
- Commit `uv.lock` for applications (reproducible installs); omit for libraries
- Never pin dependencies in library code — use ranges (`>=2.0,<3`)
- Pin exact versions only in lock files, not in `pyproject.toml`
- Separate dev dependencies into `[project.optional-dependencies]` dev group

## Virtual Environments
- `uv` manages venvs automatically (`uv sync` creates `.venv`)
- Never install packages globally for project work
- Add `.venv/` to `.gitignore`

## Configuration
- Load configuration at startup using `pydantic-settings` or `dataclasses`
- Read from environment variables / `.env` files at the entry point only
- Never call `os.getenv()` inside domain or service logic — inject config as a dependency
- Validate config at startup; fail fast with a clear error if required values are missing

## Architecture Layers
- **Domain**: Pure Python, no framework imports. Entities, value objects, domain exceptions, ports (abstract base classes / Protocols)
- **Service**: Orchestration only. Receives domain objects and port abstractions via constructor. No direct DB or HTTP calls
- **Repository / Adapter**: Implements domain ports. Handles DB/external API I/O
- **API layer**: Thin handlers. Decode request → call service → encode response. No business logic

## Dependency Injection
- Pass dependencies via `__init__` parameters — never instantiate infra classes inside service logic
- Define ports as `Protocol` or `ABC` in the domain/service layer
- Wire dependencies at the entry point (`main.py`, `app.py`, or factory functions)

## Error Flow
- Domain raises domain-specific exceptions (`OrderNotFoundError`, `InsufficientStockError`)
- Service layer lets domain exceptions propagate; catches and translates infra errors
- API layer catches domain exceptions and maps them to HTTP status codes
- Never log and re-raise the same error (double logging)

## Tooling (run in CI)
| Tool | Purpose |
|------|---------|
| `ruff` | Linting + formatting (replaces flake8, isort, black) |
| `mypy --strict` | Static type checking |
| `pytest --cov` | Testing + coverage |
| `uv sync` | Dependency install |
