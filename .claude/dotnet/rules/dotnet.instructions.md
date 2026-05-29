---
name: dotnet-clean-architecture-rules
description: Architecture and coding rules for .NET Clean Architecture projects. CQRS with Zibetti.Mediator, Repository pattern, crosscutting isolation, and Minimal API conventions.
applyTo: "**/*.{cs,csproj,slnx}"
---

# .NET Clean Architecture Rules

## Architecture Overview
Clean Architecture with CQRS using **Zibetti.Mediator** (`dotnet add package Zibetti.Mediator`). Layers:

- **Api**: Minimal API endpoints, middleware, view models
- **Application**: Commands, queries, handlers, validators, ports (interfaces for external services)
- **Domain**: Entities, value objects, enums, repository interfaces
- **Infrastructure**: EF Core, repository implementations (internal), BackgroundService
- **Infrastructure.{Concern}**: Isolated crosscutting adapters (e.g. `Infrastructure.Pluggy`) — all adapter DTOs internal
- **Infrastructure.IoC**: Composition root — DI wiring only

## CQRS with Zibetti.Mediator

### Command (with result)
```csharp
public sealed record CreateItemCommand(string PluggyId) : ICommand<Guid>;

public sealed class CreateItemCommandHandler(IItemRepository repository)
    : ICommandHandler<CreateItemCommand, Guid>
{
    public async Task<Guid> HandleAsync(CreateItemCommand command, CancellationToken ct = default)
    {
        var item = new Item(command.PluggyId);
        await repository.AddAsync(item, ct);
        return item.Id;
    }
}
```

### Query
```csharp
public sealed record GetItemsQuery : IQuery<IReadOnlyList<ItemResult>>;

public sealed class GetItemsQueryHandler(IItemRepository repository)
    : IQueryHandler<GetItemsQuery, IReadOnlyList<ItemResult>>
{
    public async Task<IReadOnlyList<ItemResult>> HandleAsync(GetItemsQuery query, CancellationToken ct = default)
        => (await repository.GetAllAsync(ct)).Select(i => new ItemResult(i.Id, i.Name)).ToList();
}
```

### Dispatch in endpoint
```csharp
// Command with result
var id = await mediator.SendAsync<CreateItemCommand, Guid>(command, ct);
// Fire-and-forget
await mediator.SendAsync(command, ct);
// Query
var result = await mediator.QueryAsync<GetItemsQuery, IReadOnlyList<ItemResult>>(query, ct);
```

### Registration
```csharp
services.AddZibettiMediator(typeof(Application.AssemblyMarker).Assembly);
```

## Repository Pattern

### Interface in Domain
```csharp
// Domain/Repositories/IItemRepository.cs
public interface IItemRepository
{
    Task<Item?> FindByPluggyIdAsync(string pluggyItemId, CancellationToken ct = default);
    Task<IReadOnlyList<Item>> GetAllAsync(CancellationToken ct = default);
    Task AddAsync(Item item, CancellationToken ct = default);
    Task UpdateAsync(Item item, CancellationToken ct = default);
    Task DeleteAsync(Item item, CancellationToken ct = default);
}
```

### Implementation in Infrastructure (internal)
```csharp
// Infrastructure/Persistence/Repositories/ItemRepository.cs
internal sealed class ItemRepository(AppDbContext db) : IItemRepository { ... }
```

### Expose via extension in Infrastructure
```csharp
// Infrastructure/Persistence/RepositoryServiceExtensions.cs
public static IServiceCollection AddRepositories(this IServiceCollection services)
{
    services.AddScoped<IItemRepository, ItemRepository>();
    return services;
}
```
IoC calls `services.AddRepositories()` — never references `internal` types directly.

## Crosscutting Adapters

External APIs go in isolated projects (`Infrastructure.{Name}`). The adapter implements a **port** defined in Application. All adapter-specific DTOs are `internal`.

```
Infrastructure.Pluggy/
  PluggyClient.cs    ← internal implementation of Application.Ports.IPluggyClient
  PluggyDtos.cs      ← internal — never leaks out
  PluggyOptions.cs

Application/Ports/
  IPluggyClient.cs   ← port, defined in Application
```

## Port Location

| Port type | Lives in |
|---|---|
| Repository (`IItemRepository`) | **Domain** |
| External service (`IPluggyClient`) | **Application** |
| Background service interface | **Application** |

## API Layer
- Minimal API + endpoint groups
- Scalar for OpenAPI (`app.MapScalarApiReference()`)
- Exception middleware in Infrastructure.IoC or Api
- CORS configured in IoC

## Validation
- FluentValidation in Application alongside the command/query
- Endpoint filters apply validation before handler

## Testing
- xUnit + NSubstitute + FluentAssertions
- Mirror source in `tests/`
- Naming: `MethodName_Scenario_ExpectedResult`
