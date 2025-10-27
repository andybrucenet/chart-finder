namespace ChartFinder.Domain.Enums;

/// <summary>
/// Describes the overall difficulty of a chart.
/// </summary>
public enum ChartDifficulty
{
    /// <summary>
    /// Difficulty is unknown or has not been assessed.
    /// </summary>
    Unknown = 0,

    /// <summary>
    /// Suitable for early-stage ensembles learning fundamentals.
    /// </summary>
    Beginner = 1,

    /// <summary>
    /// Appropriate for most school and community groups with moderate experience.
    /// </summary>
    Intermediate = 2,

    /// <summary>
    /// Intended for advanced or professional ensembles.
    /// </summary>
    Advanced = 3
}

/// <summary>
/// Identifies the primary ensemble format that a chart serves.
/// </summary>
public enum EnsembleType
{
    /// <summary>
    /// Ensemble type is unknown or not specified.
    /// </summary>
    Unknown = 0,

    /// <summary>
    /// Full big band instrumentation (typically 17–18 pieces).
    /// </summary>
    BigBand = 1,

    /// <summary>
    /// Small combo or chamber jazz instrumentation (typically 3–9 pieces).
    /// </summary>
    Combo = 2,

    /// <summary>
    /// Vocal feature with accompanying ensemble.
    /// </summary>
    Vocal = 3,

    /// <summary>
    /// Solo instrument or unaccompanied performer.
    /// </summary>
    Solo = 4
}
