using ChartFinder.Domain.Entities;

namespace ChartFinder.Domain.Repositories;

/// <summary>
/// Provides asynchronous persistence operations for <see cref="UserProfile" /> entities while remaining storage-agnostic.
/// </summary>
public interface IUserProfileRepository: IRepository<UserProfile>
{
}
