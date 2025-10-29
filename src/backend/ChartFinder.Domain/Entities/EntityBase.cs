using System;

namespace ChartFinder.Domain.Entities;

/// <summary>
/// Base class for all domain entities with properties common regardless of backend.
/// </summary>
public class EntityBase
{
    /// <summary>
    /// Unique identifier for the entity (always specific to the derived type).
    /// <para></para>
    /// For example:
    /// <list type="unordered">
    /// <item>
    /// <term>Chart</term>
    /// <description>Unique identifier for the chart, such as a slug or an external catalog number.</description>
    /// </item>
    /// <item>
    /// <term>UserProfile</term>
    /// <description>Unique identifier used by domain logic (generally a username/email).</description>
    /// </item>
    /// </list>
    /// </summary>
    public string Id { get; set; } = string.Empty;

    /// <summary>
    /// UTC timestamp captured when the entity is first persisted.
    /// </summary>
    /// <remarks>
    /// Use this to audit when the record was originally created; it should never be mutated
    /// after initial save.
    /// </remarks>
    public DateTimeOffset DateCreatedUtc { get; init; } = DateTimeOffset.UtcNow;

    /// <summary>
    /// UTC timestamp of the most recent modification to the entity.
    /// </summary>
    /// <remarks>
    /// Update this each time the entity is saved to track write history; leave
    /// <c>null</c> when no updates have occurred since creation.
    /// </remarks>
    public DateTimeOffset? DateModifiedUtc { get; set; }
}
