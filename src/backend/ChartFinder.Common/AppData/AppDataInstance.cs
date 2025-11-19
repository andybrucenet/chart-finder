using CfCommonUtils = ChartFinder.Common.Framework.Utils;
using System.Reflection;

namespace ChartFinder.Common.AppData;

/// <summary>
/// Provides appdata metadata describing a built Chart Finder component.
/// Consumers use this contract to surface build data across services.
/// </summary>
public class AppDataInstance : IAppDataInstance
{
    private static readonly string[] MetadataExposeOpenAPI = { "BackendExposeOpenAPI", "ExposeOpenAPI" };

    /// <inheritdoc/>
    public bool ExposeOpenAPI { get; }

    /// <summary>
    /// Consruct instance
    /// </summary>
    /// <param name="exposeOpenAPI"></param>
    public AppDataInstance(bool exposeOpenAPI)
    {
        ExposeOpenAPI = exposeOpenAPI;
    }

    /// <summary>
    /// Render a human-readable summary including branch/comment/build metadata when available.
    /// </summary>
    public override string ToString() =>
        $"{nameof(ExposeOpenAPI)}={ExposeOpenAPI}";

    /// <summary>
    /// Hydrates version information from the provided assembly.
    /// </summary>
    public static IAppDataInstance FromAssembly(Assembly assembly)
    {
        if (assembly is null)
        {
            throw new ArgumentNullException(nameof(assembly));
        }

        bool exposeOpenAPI;
        {
            var rawValue = GetMetadataValue(assembly, MetadataExposeOpenAPI) ?? string.Empty;
            bool parsedValue;
            var parsedOK = Boolean.TryParse(rawValue, out parsedValue);
            exposeOpenAPI = parsedOK ? parsedValue : false;
        }

        return new AppDataInstance(exposeOpenAPI);
    }

    /// <summary>
    /// Retrieve custom assembly metadata by key (case-insensitive).
    /// </summary>
    private static string? GetMetadataValue(Assembly assembly, IReadOnlyCollection<string> keys) =>
        CfCommonUtils.GetMetadataValue(assembly, keys);
}