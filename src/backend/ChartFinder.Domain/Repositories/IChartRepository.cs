using ChartFinder.Domain.Entities;

namespace ChartFinder.Domain.Repositories;

/// <summary>
/// Provides asynchronous persistence operations for <see cref="Chart" /> entities while remaining storage-agnostic.
/// </summary>
public interface IChartRepository: IRepository<Chart>
{
}
