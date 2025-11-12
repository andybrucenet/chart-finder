using ChartFinder.Common.Versioning;
using Microsoft.AspNetCore.Mvc;

namespace ChartFinder.Api.Controllers;

/// <summary>
/// Exposes utility endpoints that surface build and version metadata.
/// </summary>
[ApiController]
[Route("utils/v1")]
public class UtilsController : ControllerBase
{
    private readonly IVersionInfo _versionInfo;

    /// <summary>
    /// Create a new controller instance that surfaces build metadata.
    /// </summary>
    /// <param name="versionInfo">Version information for the running application.</param>
    public UtilsController(IVersionInfo versionInfo)
    {
        _versionInfo = versionInfo;
    }

    /// <summary>
    /// Retrieve version details for the running Chart Finder backend.
    /// </summary>
    /// <returns>Structured version metadata.</returns>
    [HttpGet("version")]
    public IActionResult GetVersion()
    {
        return Ok(new
        {
            product = _versionInfo.Product,
            description = _versionInfo.Description,
            version = _versionInfo.Version.ToString(),
            company = _versionInfo.Company,
            copyright = _versionInfo.Copyright,
            branch = _versionInfo.Branch,
            comment = _versionInfo.Comment,
            buildNumber = _versionInfo.BuildNumber
        });
    }
}
