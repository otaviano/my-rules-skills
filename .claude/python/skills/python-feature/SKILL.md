---
name: python-feature
description: Workflow skill for implementing new features in a Python project following idiomatic Python, Clean Architecture, and SOLID principles. Use when adding new use cases, services, repositories, API endpoints, or domain logic.
---

# Python Feature Implementation Skill

This skill provides a step-by-step workflow for implementing new features in a Python project following idiomatic Python and Clean Architecture practices.

## Invocation
Use this skill when adding new functionality. Examples:
- _"add an endpoint to create an order"_
- _"implement a service to send notifications"_
- _"add a repository method to fetch users by email"_

## When to Use
- Adding new business logic or use cases
- Creating new API endpoints (FastAPI/Flask)
- Implementing repository methods
- Defining new domain models or value objects
- Writing new service layer orchestration

---

## Workflow: Implement a New Feature

### 1. Define Domain Types in `src/my_package/domain/`
- Use `dataclass` or Pydantic `BaseModel` for entities and value objects
- Validate invariants inside `__post_init__` or validators — not in the service layer
- Keep domain types free of framework dependencies (no DB, no HTTP)
- Define domain exceptions here: `class OrderNotFoundError(Exception): ...`

```python
from dataclasses import dataclass
from datetime import datetime

@dataclass(frozen=True)
class OrderId:
    value: str

@dataclass
class Order:
    id: OrderId
    customer_id: str
    created_at: datetime

    def __post_init__(self) -> None:
        if not self.customer_id:
            raise ValueError("customer_id cannot be empty")
```

### 2. Define the Port (Protocol) in the Service Layer
- Define as `Protocol` in the service package — not in the repository
- Only expose the methods this service actually needs (ISP)

```python
# src/my_package/service/order_service.py
from typing import Protocol
from my_package.domain.models import Order, OrderId

class OrderRepository(Protocol):
    def save(self, order: Order) -> None: ...
    def find_by_id(self, order_id: OrderId) -> Order | None: ...
```

### 3. Implement the Service in `src/my_package/service/`
- Receive dependencies via `__init__` — never instantiate repos inside the service
- All public methods have type annotations and docstrings
- Wrap errors with context: `raise ServiceError("failed to create order") from err`

```python
class OrderService:
    def __init__(self, repository: OrderRepository) -> None:
        self._repository = repository

    def create_order(self, customer_id: str) -> Order:
        """Create a new order for the given customer.

        Args:
            customer_id: The customer placing the order.

        Returns:
            The newly created Order.

        Raises:
            ValueError: If customer_id is invalid.
        """
        order = Order(id=OrderId(str(uuid4())), customer_id=customer_id, created_at=datetime.utcnow())
        self._repository.save(order)
        return order
```

### 4. Implement the Repository in `src/my_package/repository/`
- Implement the Protocol defined in the service layer
- Map between domain types and DB/ORM models here
- Use `logger = logging.getLogger(__name__)` for diagnostic logging

```python
import logging
from my_package.domain.models import Order, OrderId

logger = logging.getLogger(__name__)

class SqlOrderRepository:
    def __init__(self, session: Session) -> None:
        self._session = session

    def save(self, order: Order) -> None:
        logger.debug("saving order %s", order.id.value)
        ...

    def find_by_id(self, order_id: OrderId) -> Order | None:
        ...
```

### 5. Add the API Endpoint in `src/my_package/api/`
- Handlers are thin: decode → call service → encode
- No business logic in handlers
- Map domain exceptions to HTTP status codes

```python
from fastapi import APIRouter, HTTPException
from my_package.domain.exceptions import OrderNotFoundError

router = APIRouter(prefix="/orders")

@router.post("/", status_code=201)
def create_order(body: CreateOrderRequest, service: OrderService = Depends(get_order_service)) -> OrderResponse:
    """Create a new order."""
    try:
        order = service.create_order(body.customer_id)
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
    return OrderResponse.from_domain(order)
```

### 6. Wire in `main.py` / `app.py`
- Instantiate dependencies bottom-up: DB session → repository → service → router
- No business logic here — composition only

### 7. Write Tests

**Unit test the service** (use a fake/mock repository):
```python
import pytest
from unittest.mock import MagicMock
from my_package.service.order_service import OrderService

@pytest.mark.parametrize("customer_id,should_raise", [
    ("cust-1", False),
    ("", True),
])
def test_create_order(customer_id: str, should_raise: bool) -> None:
    repo = MagicMock()
    service = OrderService(repository=repo)

    if should_raise:
        with pytest.raises(ValueError):
            service.create_order(customer_id)
    else:
        order = service.create_order(customer_id)
        assert order.customer_id == customer_id
        repo.save.assert_called_once_with(order)
```

**Integration test the repository** against a real (test) DB.

**API tests** using `httpx.AsyncClient` with FastAPI `TestClient`.

---

## Checklist Before Submitting

- [ ] `ruff check .` and `ruff format .` pass with no issues
- [ ] `mypy --strict` passes (no untyped public APIs)
- [ ] All public functions/classes have docstrings
- [ ] No bare `except:` clauses
- [ ] `is None` used (not `== None`)
- [ ] Module-level `logger = logging.getLogger(__name__)` — no `print()` for diagnostics
- [ ] `pytest` passes with `--tb=short`
- [ ] `pytest --cov` coverage maintained or improved
- [ ] Mutation tests pass (`mutmut run`); improve score if below threshold
- [ ] `uv sync` / `uv lock` updated if dependencies changed
- [ ] No business logic in API handlers or `main.py`
