namespace ChartFinder.Domain.Repositories;

/// <summary>
/// Provides asynchronous persistence operations for <see cref="Chart" /> entities while remaining storage-agnostic.
/// </summary>
public interface IChartRepository
{
    /// <summary>
    /// Retrieves a single chart by its unique identifier.
    /// </summary>
    /// <param name="id">Identifier produced by the domain; implementation treats it as an opaque key.</param>
    /// <param name="cancellationToken">Optional cancellation notification.</param>
    /// <returns>The chart when found; otherwise <c>null</c>.</returns>
    Task<Chart?> GetAsync(string id, CancellationToken cancellationToken = default);

    /// <summary>
    /// Returns all charts visible to the caller.
    /// </summary>
    /// <param name="cancellationToken">Optional cancellation notification.</param>
    /// <returns>A read-only list containing zero or more charts.</returns>
    Task<IReadOnlyList<Chart>> ListAsync(CancellationToken cancellationToken = default);

    /// <summary>
    /// Creates or updates a chart in the underlying store.
    /// </summary>
    /// <param name="chart">The chart to persist.</param>
    /// <param name="cancellationToken">Optional cancellation notification.</param>
    Task SaveAsync(Chart chart, CancellationToken cancellationToken = default);

    /// <summary>
    /// Removes a chart identified by <paramref name="id" /> if it exists.
    /// </summary>
    /// <param name="id">Identifier produced by the domain; implementation treats it as an opaque key.</param>
    /// <param name="cancellationToken">Optional cancellation notification.</param>
    Task DeleteAsync(string id, CancellationToken cancellationToken = default);
}
