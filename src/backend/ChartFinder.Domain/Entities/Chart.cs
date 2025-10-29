using ChartFinder.Domain.Enums;

namespace ChartFinder.Domain.Entities;

/// <summary>
/// Represents an arrangement or chart with metadata that helps musicians discover, preview, and purchase music.
/// </summary>
public sealed class Chart : EntityBase
{
    /// <summary>
    /// Creates a new <see cref="Chart" /> with empty list properties to satisfy JSON serializers that require settable collections.
    /// </summary>
    public Chart()
    {
    }

    /// <summary>
    /// Title that performers will recognize on a set list or in a catalog.
    /// </summary>
    public string Title { get; set; } = string.Empty;

    /// <summary>
    /// Composer credit, if known.
    /// </summary>
    public string? Composer { get; set; }

    /// <summary>
    /// Arranger credit, if applicable.
    /// </summary>
    public string? Arranger { get; set; }

    /// <summary>
    /// Ensemble size or instrumentation archetype.
    /// </summary>
    public EnsembleType Ensemble { get; set; } = EnsembleType.Unknown;

    /// <summary>
    /// Difficulty rating that helps band leaders match charts to performer ability.
    /// </summary>
    public ChartDifficulty Difficulty { get; set; } = ChartDifficulty.Unknown;

    /// <summary>
    /// Specific instrumentation calls (e.g., trumpet 1, tenor sax, rhythm section).
    /// </summary>
    public List<string> Instrumentation { get; set; } = new();

    /// <summary>
    /// Free-form tags that assist with discovery such as genres, styles, or moods.
    /// </summary>
    public List<string> Tags { get; set; } = new();

    /// <summary>
    /// Link to a location where the chart can be purchased or licensed.
    /// </summary>
    public Uri? PurchaseUrl { get; set; }

    /// <summary>
    /// Link to an audio or PDF preview of the chart.
    /// </summary>
    public Uri? PreviewUrl { get; set; }

    /// <summary>
    /// Additional notes that do not belong in structured fields.
    /// </summary>
    public string? Notes { get; set; }
}
