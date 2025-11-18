using System;
using ChartFinder.Api.Configuration;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;

#pragma warning disable CA1707 // Underscores

namespace ChartFinder.Api.UnitTests;

/// <summary>
/// Basic tests
/// </summary>
public class ConfigurationTests
{
    private const string MISSING_TABLE_NAME = $"MISSING: {nameof(DynamoOptions.TableName)}";

    [Fact]
    public void DynamoOptions_BindsSuccessfully_WhenTableNameProvided()
    {
        var inMemorySettings = new Dictionary<string, string?>
        {
            ["Dynamo:TableName"] = "ChartFinder-dev-test",
            ["Dynamo:Region"] = "us-east-2",
        };
        var configuration = new ConfigurationBuilder()
            .AddInMemoryCollection(inMemorySettings)
            .Build();

        var services = new ServiceCollection();
        services.AddOptions<DynamoOptions>()
            .Bind(configuration.GetSection(DynamoOptions.SectionName))
            .ValidateDataAnnotations()
            .Validate(options => !string.IsNullOrWhiteSpace(options.TableName), MISSING_TABLE_NAME)
            .ValidateOnStart();

        var provider = services.BuildServiceProvider();

        _ = provider.GetRequiredService<IOptions<DynamoOptions>>().Value;
    }

    [Fact]
    public void DynamoOptions_Throws_WhenTableNameMissing()
    {
        // empty
        var configuration = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>())
            .Build();

        var services = new ServiceCollection();
        services.AddOptions<DynamoOptions>()
            .Bind(configuration.GetSection(DynamoOptions.SectionName))
            .ValidateDataAnnotations()
            .Validate(options => !string.IsNullOrWhiteSpace(options.TableName), MISSING_TABLE_NAME)
            .ValidateOnStart();

        // assert
        var exception = Assert.Throws<OptionsValidationException>(() =>
        {
            _ = services.BuildServiceProvider().GetRequiredService<IOptions<DynamoOptions>>().Value;
        });
        Assert.Contains(MISSING_TABLE_NAME, exception.Failures);
    }
}