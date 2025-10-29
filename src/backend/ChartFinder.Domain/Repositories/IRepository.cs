using ChartFinder.Domain.Entities;

namespace ChartFinder.Domain.Repositories;

/// <summary>
/// Defines the asynchronous CRUD surface for entity types that derive from <see cref="EntityBase" />.
/// </summary>
/// <typeparam name="TEntity">Concrete entity type handled by the repository.</typeparam>
public interface IRepository<TEntity>
    where TEntity : EntityBase
{
    /// <summary>
    /// Retrieves a single entity by its identifier.
    /// </summary>
    /// <param name="id">Domain-generated identifier treated as an opaque key.</param>
    /// <param name="cancellationToken">Token that signals the operation should be cancelled.</param>
    /// <returns>The entity when it exists; otherwise <c>null</c>.</returns>
    Task<TEntity?> GetAsync(string id, CancellationToken cancellationToken = default);

    /// <summary>
    /// Returns every entity the implementation chooses to expose to the caller.
    /// </summary>
    /// <param name="cancellationToken">Token that signals the operation should be cancelled.</param>
    /// <returns>A read-only list containing zero or more entities.</returns>
    Task<IReadOnlyList<TEntity>> ListAsync(CancellationToken cancellationToken = default);

    /// <summary>
    /// Persists a new entity in the underlying store.
    /// </summary>
    /// <param name="entity">Entity instance to create.</param>
    /// <param name="cancellationToken">Token that signals the operation should be cancelled.</param>
    Task CreateAsync(TEntity entity, CancellationToken cancellationToken = default);

    /// <summary>
    /// Persists modifications to an existing entity.
    /// </summary>
    /// <param name="entity">Entity instance carrying the updated state.</param>
    /// <param name="cancellationToken">Token that signals the operation should be cancelled.</param>
    Task UpdateAsync(TEntity entity, CancellationToken cancellationToken = default);

    /// <summary>
    /// Deletes the entity identified by <paramref name="id" /> when it exists.
    /// </summary>
    /// <param name="id">Domain-generated identifier treated as an opaque key.</param>
    /// <param name="cancellationToken">Token that signals the operation should be cancelled.</param>
    Task DeleteAsync(string id, CancellationToken cancellationToken = default);
}