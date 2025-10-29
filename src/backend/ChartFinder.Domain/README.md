# ChartFinder.Domain

- Purpose: Domain entities, enums, and repository abstractions shared across infrastructure layers.
- Structure: `Entities/` for aggregate roots, `Repositories/` for interfaces, `Enums.cs` for supporting types.
- Convention: Entities derive from `EntityBase`; repositories implement or extend `IRepository<TEntity>`.
