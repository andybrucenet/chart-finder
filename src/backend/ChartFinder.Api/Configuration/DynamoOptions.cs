using System.ComponentModel.DataAnnotations;

namespace ChartFinder.Api.Configuration;

/// <summary>
/// Configuration required to access the backing DynamoDB table for charts.
/// </summary>
public sealed class DynamoOptions
{
    /// <summary>
    /// Name of the configuration section supplying <see cref="DynamoOptions" /> values.
    /// </summary>
    public const string SectionName = "Dynamo";

    /// <summary>
    /// Name of the DynamoDB table used to persist charts.
    /// </summary>
    [Required]
    [MinLength(3)]
    public string TableName { get; set; } = string.Empty;

    /// <summary>
    /// Optional AWS region override when the table lives outside the default region.
    /// </summary>
    public string? Region { get; set; }
}
