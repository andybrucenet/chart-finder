namespace ChartFinder.Common.AppData;

/// <summary>
/// Provides appdata metadata describing a built Chart Finder component.
/// Consumers use this contract to surface build data across services.
/// </summary>
public interface IAppDataInstance
{
    /// <summary>
    /// Should this app expose its OpenAPI endpoint (generally: swagger/v1/swagger.json)
    /// </summary>
    bool ExposeOpenAPI { get; }
}
