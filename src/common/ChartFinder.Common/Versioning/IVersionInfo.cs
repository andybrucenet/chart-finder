using System;

namespace ChartFinder.Common.Versioning;

/// <summary>
/// Provides metadata describing a built Chart Finder component.
/// Consumers use this contract to surface build provenance across services.
/// </summary>
public interface IVersionInfo
{
    /// <summary>
    /// Product name extracted from the assembly metadata.
    /// </summary>
    string Product { get; }

    /// <summary>
    /// Descriptive text from the assembly (AssemblyDescription).
    /// </summary>
    string Description { get; }

    /// <summary>
    /// Four-part numeric version that satisfies platform constraints.
    /// </summary>
    Version Version { get; }

    /// <summary>
    /// Company name recorded on the assembly.
    /// </summary>
    string Company { get; }

    /// <summary>
    /// Copyright statement associated with this build.
    /// </summary>
    string Copyright { get; }

    /// <summary>
    /// Source branch that produced the build (if known).
    /// </summary>
    string Branch { get; }

    /// <summary>
    /// Additional release tag or descriptive comment for the build.
    /// </summary>
    string Comment { get; }

    /// <summary>
    /// Monotonically increasing build identifier (UTC timestamp string by convention).
    /// </summary>
    string BuildNumber { get; }
}
