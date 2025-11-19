using System.Reflection;

namespace ChartFinder.Common.Framework;

/// <summary>
/// Common utilities for all ChartFinder .net projects
/// </summary>
public static class Utils
{
    /// <summary>
    /// Retrieve custom assembly metadata by key (case-insensitive).
    /// </summary>
    public static string? GetMetadataValue(Assembly assembly, IReadOnlyCollection<string> keys)
    {
        foreach (var attribute in assembly.GetCustomAttributes<AssemblyMetadataAttribute>())
        {
            foreach (var key in keys)
            {
                if (string.Equals(attribute.Key, key, StringComparison.OrdinalIgnoreCase))
                {
                    return attribute.Value;
                }
            }
        }

        return null;
    }
}