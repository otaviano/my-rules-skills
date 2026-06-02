# .NET Testing Conventions

## Stack
- **xUnit** — test framework (`[Fact]`, `[Theory]`, `[InlineData]`)
- **NSubstitute** — mocking
- **FluentAssertions** — assertions
- **coverlet** — code coverage (via `dotnet test --collect:"XPlat Code Coverage"`)
- **Stryker.NET** — mutation testing (target: **80% mutation score**)

## Project structure
Mirror the source under `tests/`:
```
tests/Finance.UnitTests/
  Items/Commands/SyncItem/SyncItemCommandHandlerTests.cs
  Notifications/Queries/GetDueInvoices/GetDueInvoicesQueryHandlerTests.cs
  ...
```

## Naming conventions
| Item | Pattern | Example |
|---|---|---|
| Test class | `{ClassUnderTest}Tests` | `SyncItemCommandHandlerTests` |
| Test method | `{Method}_{Scenario}_{ExpectedResult}` | `HandleAsync_WhenItemNotFound_CreatesNewItem` |

## Test structure (AAA)
```csharp
public class MyHandlerTests
{
    private readonly IMyDependency _dep = Substitute.For<IMyDependency>();
    private readonly MyHandler _sut;

    public MyHandlerTests()
    {
        _sut = new MyHandler(_dep);
    }

    [Fact]
    public async Task HandleAsync_WhenCondition_ThenExpectedResult()
    {
        // Arrange
        var command = new MyCommand(...);
        _dep.SomeMethod(Arg.Any<string>()).Returns("value");

        // Act
        var result = await _sut.HandleAsync(command, CancellationToken.None);

        // Assert
        result.Should().Be("value");
        await _dep.Received(1).SomeMethod("expected-arg");
    }
}
```

## NSubstitute patterns
```csharp
// Create
var mock = Substitute.For<IMyInterface>();

// Setup return (sync)
mock.Method().Returns(value);

// Setup return (async)
mock.MethodAsync().Returns(Task.FromResult(value));
// or shorter:
mock.MethodAsync().Returns(value);  // NSubstitute auto-wraps

// Setup return with null (nullable)
mock.FindAsync(Arg.Any<Guid>()).Returns((MyEntity?)null);

// Verify called
await mock.Received(1).MethodAsync(Arg.Is<Guid>(id => id == expected));

// Verify NOT called
await mock.DidNotReceive().MethodAsync(Arg.Any<Guid>());

// Capture args
Guid captured = default;
mock.Method(Arg.Do<Guid>(x => captured = x)).Returns(value);
```

## FluentAssertions patterns
```csharp
// Value equality
result.Should().Be(expected);
result.Should().BeNull();
result.Should().NotBeNull();

// Collections
list.Should().HaveCount(3);
list.Should().ContainSingle();
list.Should().BeEmpty();
list.Should().Contain(x => x.Id == id);

// Deep equality
result.Should().BeEquivalentTo(expected, opt => opt.ExcludingMissingMembers());

// Exceptions
var act = async () => await _sut.HandleAsync(command, CancellationToken.None);
await act.Should().ThrowAsync<InvalidOperationException>()
    .WithMessage("*not found*");

// Numeric
rate.Should().BeApproximately(33.3m, precision: 0.1m);
```

## Logger mocking
Use `Substitute.For<ILogger<T>>()` — no need to assert calls on it unless testing log output is critical.

```csharp
var logger = Substitute.For<ILogger<MyHandler>>();
var sut = new MyHandler(dep, logger);
```

## Stryker.NET setup

Install globally (once):
```bash
dotnet tool install -g dotnet-stryker
```

Or via manifest (recommended for team/CI):
```bash
dotnet new tool-manifest  # creates .config/dotnet-tools.json
dotnet tool install dotnet-stryker
```

Run from the **test project** directory (Stryker 4.x does not support `.slnx` solution format):
```bash
cd tests/MyProject.UnitTests
dotnet stryker --project MyProject.Application.csproj
```

Config file `stryker-config.json` at the backend root (or in test dir):
```json
{
  "stryker-config": {
    "project": "MyProject.Application.csproj",
    "reporters": ["html", "cleartext"],
    "mutation-level": "Standard",
    "thresholds": {
      "high": 80,
      "low": 70,
      "break": 0
    }
  }
}
```

## Coverage targets
| Layer | Target |
|---|---|
| Application handlers | ≥ 80% line + 80% mutation |
| Domain logic / pure functions | 100% |
| Infrastructure adapters | skip (integration tests) |

## What to test in handlers
- Happy path
- Not-found cases (throw expected exception)
- Each conditional branch (enabled/disabled, null fields, edge dates)
- Mapping functions (all enum cases)
- Side-effect verification (repository methods called with correct args)
- Boundary values (0, negative, max)
