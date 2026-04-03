---
name: python-conventions
description: General Python coding conventions based on PEP 8, PEP 257, PEP 20 (Zen of Python), and official Python docs. Naming, formatting, type hints, error handling, logging, and testing patterns.
applyTo: "**/*.py"
---

# General Python Coding Conventions

## Formatting (PEP 8)
- 4 spaces per indentation level — never tabs
- Maximum line length: 79 characters for code, 72 for docstrings/comments
- 2 blank lines between top-level functions and classes
- 1 blank line between methods inside a class
- Use `black` or `ruff format` to enforce formatting automatically
- Break long lines before binary operators (Knuth style):
  ```python
  total = (income
           + capital_gains
           - deductions)
  ```

## Imports
- Group in order: standard library → third-party → local; blank line between each group
- One import per line; avoid `from module import *`
- Prefer absolute imports over relative
- Use `isort` or `ruff` to organize imports automatically

## Naming (PEP 8)
- Modules/packages: `lowercase_with_underscores`, short names
- Classes: `CapWords`
- Functions/methods/variables: `lowercase_with_underscores`
- Constants: `UPPER_CASE_WITH_UNDERSCORES`
- Private members: single underscore `_private`; double `__` invokes name mangling
- Avoid: `l`, `O`, `I` as single-letter names (visually ambiguous)
- Boolean variables/functions: use `is_`, `has_`, `can_` prefixes (`is_valid`, `has_permission`)

## Type Hints (PEP 484 / 526)
- Annotate all public function signatures and return types
- Use modern union syntax (`int | None` over `Optional[int]`, Python 3.10+)
- Use lowercase generics (`list[int]`, `dict[str, int]`, Python 3.9+)
- Use `TypeAlias` or `type` statement for complex aliases
- Use `Protocol` for structural/duck-typing contracts
- Use `Final` for immutable module-level constants
- Run `mypy --strict` (or `pyright`) in CI — type hints are not enforced at runtime

## Docstrings (PEP 257)
- Use `"""triple double quotes"""` for all docstrings
- Every public module, class, function, and method must have a docstring
- One-liners: summary on a single line, closing quotes on the same line
- Multi-line: summary → blank line → details; closing `"""` on its own line
- Use Google style (preferred) or NumPy style — pick one and stay consistent:
  ```python
  def fetch_user(user_id: int) -> User:
      """Fetch a user by their ID.

      Args:
          user_id: The unique identifier of the user.

      Returns:
          The User object matching the given ID.

      Raises:
          UserNotFoundError: If no user exists with that ID.
      """
  ```

## Error / Exception Handling
- Always catch specific exception types — never bare `except:`
- Use `is` / `is not` for singleton comparisons (`x is None`, not `x == None`)
- Use `isinstance(x, T)` for type checks — never `type(x) == T`
- Use `.startswith()` / `.endswith()` for string prefix/suffix checks
- Raise exceptions for error conditions; don't return sentinel values like `-1` or `None` to signal errors
- "Errors should never pass silently" (PEP 20) — let exceptions propagate unless explicitly handled
- Add context when re-raising: `raise OrderNotFoundError("order not found") from err`

## Logging
- Use `logging` module — never `print()` for diagnostic output
- Create a module-level logger: `logger = logging.getLogger(__name__)`
- Libraries: add only `NullHandler`; never configure handlers in library code
- Applications: configure logging once at startup (entry point / `main`)
- Use lazy string formatting: `logger.debug("value: %s", value)` — not f-strings in log calls
- Guard expensive computations: `if logger.isEnabledFor(logging.DEBUG): ...`
- Standard levels: `DEBUG` (diagnostics), `INFO` (normal ops), `WARNING` (unexpected), `ERROR` (failure), `CRITICAL` (fatal)

## Zen of Python (PEP 20) — Core Principles
- **Explicit > Implicit** — make intent visible
- **Simple > Complex** — but complex > complicated
- **Flat > Nested** — avoid deep nesting; use early returns
- **Readability counts** — code is read far more than it is written
- **One obvious way** — prefer idiomatic solutions
- **Errors never silent** — fail fast and visibly

## Testing (pytest)
- Use `pytest` as the test framework
- Test files: `test_*.py` or `*_test.py` in a `tests/` directory mirroring source
- Test functions: `test_*()` prefix
- Use `pytest.fixture` for setup/teardown — avoid `setUp`/`tearDown` style
- Parametrize tests with `@pytest.mark.parametrize` instead of loops
- Assert with plain `assert` — pytest rewrites assertions with clear output
- Run with `pytest --tb=short -q` in CI; add `pytest-cov` for coverage

## Common Pitfalls — Must Avoid
- Mutable default arguments: `def f(items=[])` → use `def f(items=None): items = items or []`
- Bare `except:` clauses — always name the exception
- `== None` comparisons — use `is None`
- `type(x) == T` checks — use `isinstance(x, T)`
- Wildcard imports (`from module import *`)
- Silent error swallowing (`except Exception: pass`)
- Global mutable state
- Missing type annotations on public APIs
- Using `print()` for logging in library/service code
