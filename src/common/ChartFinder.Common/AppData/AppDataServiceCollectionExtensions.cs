using System;
using System.Reflection;
using Microsoft.Extensions.DependencyInjection;

namespace ChartFinder.Common.AppData;

/// <summary>
/// Dependency injection helpers for registering Chart Finder AppData information.
/// </summary>
public static class AppDataServiceCollectionExtensions
{
    /// <summary>
    /// The single global AppDataInstance created when AddChartFinderAppData is invoked
    /// </summary>
    public static IAppDataInstance? Instance { get; private set; }

    /// <summary>
    /// Register a singleton <see cref="IAppData"/> resolved from the supplied (or current) assembly.
    /// </summary>
    /// <param name="services">Service collection to mutate.</param>
    /// <param name="assembly">Optional assembly to source version metadata from.</param>
    /// <returns>The original <see cref="IServiceCollection"/> for chaining.</returns>
    public static IServiceCollection AddChartFinderAppData(this IServiceCollection services, Assembly? assembly = null)
    {
        if (services is null)
        {
            throw new ArgumentNullException(nameof(services));
        }

        var sourceAssembly = assembly
                             ?? Assembly.GetEntryAssembly()
                             ?? Assembly.GetExecutingAssembly();

        // create instance, save to this global, and add to services
        var appData = AppDataInstance.FromAssembly(sourceAssembly);
        Instance = appData;
        services.AddSingleton<IAppDataInstance>(appData);
        return services;
    }
}
