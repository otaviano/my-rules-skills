---
name: dotnet-clean-architecture
description: Workflow for implementing features in a .NET Clean Architecture project using Zibetti.Mediator, Repository pattern, and crosscutting isolation.
---

# .NET Clean Architecture Implementation Skill

## When to Use
- Adding a command, query, or event handler
- Creating a new API endpoint
- Adding a repository (interface + implementation)
- Adding a new crosscutting adapter (e.g. external HTTP API)

## Workflow: Add New Use Case

### 1. Define Command or Query in `Application/UseCases/`
```csharp
// Command with result
public sealed record CreateItemCommand(string PluggyId) : ICommand<Guid>;

// Query
public sealed record GetItemsQuery : IQuery<IReadOnlyList<ItemResult>>;
public sealed record ItemResult(Guid Id, string Name);
```

### 2. Validator (same folder)
```csharp
public sealed class CreateItemCommandValidator : AbstractValidator<CreateItemCommand>
{
    public CreateItemCommandValidator()
    {
        RuleFor(x => x.PluggyId).NotEmpty();
    }
}
```

### 3. Handler
```csharp
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

### 4. Domain (if needed)
- Entity in `Domain/Entities/`
- Repository interface in `Domain/Repositories/`

### 5. Repository implementation in `Infrastructure/Persistence/Repositories/` (internal)
- Register via `RepositoryServiceExtensions.AddRepositories()`

### 6. API Endpoint in `Api/Endpoints/`
```csharp
group.MapPost("/items", async (
    [FromBody] CreateItemRequest request,
    [FromServices] IMediator mediator,
    CancellationToken ct) =>
{
    var id = await mediator.SendAsync<CreateItemCommand, Guid>(
        new CreateItemCommand(request.PluggyId), ct);
    return Results.Created($"/items/{id}", new { id });
});
```

`AddZibettiMediator` scans the Application assembly — no manual handler registration.

### 7. Tests
- Unit: handler (mock repository with NSubstitute) + validator
- Integration: WebApplicationFactory

## Workflow: Add Crosscutting Adapter

1. Create `Infrastructure.{Name}` project
2. Define port in `Application/{Domain}/Ports/IAdapterName.cs`
3. Implement in new project (`internal sealed class AdapterClient : IAdapterName`)
4. All adapter DTOs stay `internal`
5. Register in IoC: `services.AddHttpClient<IAdapterName, AdapterClient>(...)`

## Checklist
- [ ] Command/Query defined in Application with no infrastructure imports
- [ ] Handler injects only interfaces (repositories or Application ports)
- [ ] Repository interface in Domain; implementation `internal` in Infrastructure
- [ ] Endpoint uses `IMediator`, not handler directly
- [ ] Crosscutting adapter DTOs are `internal`
- [ ] Unit tests: handler + validator
- [ ] `dotnet build` 0 errors / `dotnet test` passing
