using System;
using System.Reflection;
using Microsoft.Extensions.DependencyInjection;

namespace ChartFinder.Common.Versioning;

/// <summary>
/// Dependency injection helpers for registering Chart Finder version information.
/// </summary>
public static class VersionInfoServiceCollectionExtensions
{
    /// <summary>
    /// Register a singleton <see cref="IVersionInfo"/> resolved from the supplied (or current) assembly.
    /// </summary>
    /// <param name="services">Service collection to mutate.</param>
    /// <param name="assembly">Optional assembly to source version metadata from.</param>
    /// <returns>The original <see cref="IServiceCollection"/> for chaining.</returns>
    public static IServiceCollection AddChartFinderVersion(this IServiceCollection services, Assembly? assembly = null)
    {
        if (services is null)
        {
            throw new ArgumentNullException(nameof(services));
        }

        var sourceAssembly = assembly
                             ?? Assembly.GetEntryAssembly()
                             ?? Assembly.GetExecutingAssembly();

        var versionInfo = VersionInfo.FromAssembly(sourceAssembly);
        services.AddSingleton<IVersionInfo>(versionInfo);
        return services;
    }
}
