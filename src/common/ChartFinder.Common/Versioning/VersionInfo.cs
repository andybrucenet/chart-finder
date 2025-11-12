using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Text;

namespace ChartFinder.Common.Versioning;

/// <summary>
/// Concrete implementation of <see cref="IVersionInfo"/> backed by assembly metadata.
/// Use <see cref="FromAssembly(System.Reflection.Assembly)"/> to hydrate version details from a compiled assembly.
/// </summary>
public sealed class VersionInfo : IVersionInfo
{
    private const string DefaultProduct = "Chart Finder";
    private const string DefaultCompany = "SoftwareAB";
    private const string DefaultCopyright = "Copyright (c) SoftwareAB";
    private static readonly string[] MetadataBranches = { "BackendBuildBranch", "BuildBranch" };
    private static readonly string[] MetadataComments = { "BackendBuildComment", "BuildComment" };
    private static readonly string[] MetadataBuildNumbers = { "BackendBuildNumber", "BuildNumber" };

    /// <summary>
    /// Initializes a new <see cref="VersionInfo"/> instance with provided metadata values.
    /// </summary>
    /// <param name="product">Product name recorded on the assembly.</param>
    /// <param name="description">Assembly description.</param>
    /// <param name="version">Four-part version number.</param>
    /// <param name="company">Company name associated with the assembly.</param>
    /// <param name="copyright">Copyright statement.</param>
    /// <param name="branch">Source control branch for the build.</param>
    /// <param name="comment">Human-readable release tag or comment.</param>
    /// <param name="buildNumber">Build identifier (UTC timestamp string by convention).</param>
    public VersionInfo(
        string product,
        string description,
        Version version,
        string company,
        string copyright,
        string branch,
        string comment,
        string buildNumber)
    {
        Product = product;
        Description = description;
        Version = version;
        Company = company;
        Copyright = copyright;
        Branch = branch;
        Comment = comment;
        BuildNumber = buildNumber;
    }

    /// <inheritdoc />
    public string Product { get; }

    /// <inheritdoc />
    public string Description { get; }

    /// <inheritdoc />
    public Version Version { get; }

    /// <inheritdoc />
    public string Company { get; }

    /// <inheritdoc />
    public string Copyright { get; }

    /// <inheritdoc />
    public string Branch { get; }

    /// <inheritdoc />
    public string Comment { get; }

    /// <inheritdoc />
    public string BuildNumber { get; }

    /// <summary>
    /// Render a human-readable summary including branch/comment/build metadata when available.
    /// </summary>
    public override string ToString()
    {
        var builder = new StringBuilder();
        builder.Append(Product);
        builder.Append(", v");
        builder.Append(Version);

        var metadata = new List<string>();
        if (!string.IsNullOrWhiteSpace(Branch))
        {
            metadata.Add(Branch);
        }
        if (!string.IsNullOrWhiteSpace(Comment))
        {
            metadata.Add(Comment);
        }
        if (!string.IsNullOrWhiteSpace(BuildNumber))
        {
            metadata.Add($"Build {BuildNumber}");
        }

        if (metadata.Count > 0)
        {
            builder.Append(" (");
            builder.Append(string.Join(", ", metadata));
            builder.Append(')');
        }

        return builder.ToString();
    }

    /// <summary>
    /// Hydrates version information from the provided assembly.
    /// </summary>
    public static VersionInfo FromAssembly(Assembly assembly)
    {
        if (assembly is null)
        {
            throw new ArgumentNullException(nameof(assembly));
        }

        var product = assembly.GetCustomAttribute<AssemblyProductAttribute>()?.Product
                      ?? assembly.GetName().Name
                      ?? DefaultProduct;
        var description = assembly.GetCustomAttribute<AssemblyDescriptionAttribute>()?.Description ?? string.Empty;
        var company = assembly.GetCustomAttribute<AssemblyCompanyAttribute>()?.Company ?? DefaultCompany;
        var copyright = assembly.GetCustomAttribute<AssemblyCopyrightAttribute>()?.Copyright
                        ?? DefaultCopyright;

        var version = ResolveVersion(assembly);
        var branch = GetMetadataValue(assembly, MetadataBranches) ?? string.Empty;
        var comment = GetMetadataValue(assembly, MetadataComments) ?? string.Empty;
        var buildNumber = GetMetadataValue(assembly, MetadataBuildNumbers) ?? string.Empty;

        return new VersionInfo(product, description, version, company, copyright, branch, comment, buildNumber);
    }

    /// <summary>
    /// Determine the best version number available for the assembly.
    /// Falls back from informational version to assembly version to 0.0.0.0.
    /// </summary>
    private static Version ResolveVersion(Assembly assembly)
    {
        var informational = assembly.GetCustomAttribute<AssemblyInformationalVersionAttribute>()?.InformationalVersion;

        if (!string.IsNullOrWhiteSpace(informational))
        {
            var candidate = informational.Split('+')[0];
            var parsed = ParseVersion(candidate);
            if (parsed is not null)
            {
                return parsed;
            }
        }

        var assemblyVersion = assembly.GetName().Version;
        if (assemblyVersion is not null)
        {
            return assemblyVersion;
        }

        return new Version(0, 0, 0, 0);
    }

    /// <summary>
    /// Parse a version string into a four-part <see cref="Version"/> instance.
    /// </summary>
    private static Version? ParseVersion(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        var parts = value.Split('.', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries).ToList();
        if (parts.Count == 0)
        {
            return null;
        }

        while (parts.Count < 4)
        {
            parts.Add("0");
        }

        var normalized = string.Join('.', parts.Take(4));

        return Version.TryParse(normalized, out var version)
            ? version
            : null;
    }

    /// <summary>
    /// Retrieve custom assembly metadata by key (case-insensitive).
    /// </summary>
    private static string? GetMetadataValue(Assembly assembly, IReadOnlyCollection<string> keys)
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
