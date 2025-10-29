namespace ChartFinder.Domain.Entities;

/// <summary>
/// Represents an authenticated person in the system without persisting sensitive identity attributes.
/// </summary>
public sealed class UserProfile : EntityBase
{
    /// <summary>
    /// Stable subject identifier supplied by the upstream identity provider.
    /// </summary>
    public string ExternalSubject { get; set; } = string.Empty;

    /// <summary>
    /// Friendly display name shown in the UI.
    /// </summary>
    public string? DisplayName { get; set; }

    /// <summary>
    /// Optional email address used for notifications or support escalation.
    /// </summary>
    public string? Email { get; set; }

    /// <summary>
    /// Coarse-grained roles or claims attached to the authenticated user.
    /// </summary>
    public List<string> Roles { get; set; } = new();
}
