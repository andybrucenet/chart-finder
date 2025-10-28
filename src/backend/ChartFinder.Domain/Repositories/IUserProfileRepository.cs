namespace ChartFinder.Domain.Repositories;

/// <summary>
/// Provides asynchronous persistence operations for <see cref="UserProfile" /> entities while remaining storage-agnostic.
/// </summary>
public interface IUserProfileRepository
{
    /// <summary>
    /// Retrieves a single user profile by its unique identifier.
    /// </summary>
    /// <param name="id">Identifier produced by the domain; implementation treats it as an opaque key.</param>
    /// <param name="cancellationToken">Optional cancellation notification.</param>
    /// <returns>The user profile when found; otherwise <c>null</c>.</returns>
    Task<UserProfile?> GetAsync(string id, CancellationToken cancellationToken = default);

    /// <summary>Í
    /// Returns all user profiles visible to the caller.
    /// </summary>
    /// <param name="cancellationToken">Optional cancellation notification.</param>
    /// <returns>A read-only list containing zero or more user profiles.</returns>
    Task<IReadOnlyList<UserProfile>> ListAsync(CancellationToken cancellationToken = default);

    /// <summary>
    /// Creates or updates a user profile in the underlying store.
    /// </summary>
    /// <param name="userProfile">The user profile to persist.</param>
    /// <param name="cancellationToken">Optional cancellation notification.</param>
    Task SaveAsync(UserProfile userProfile, CancellationToken cancellationToken = default);

    /// <summary>
    /// Removes a user profile identified by <paramref name="id" /> if it exists.
    /// </summary>
    /// <param name="id">Identifier produced by the domain; implementation treats it as an opaque key.</param>
    /// <param name="cancellationToken">Optional cancellation notification.</param>
    Task DeleteAsync(string id, CancellationToken cancellationToken = default);
}
