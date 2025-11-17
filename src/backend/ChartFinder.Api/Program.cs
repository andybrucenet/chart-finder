using System.IO;
using Microsoft.AspNetCore.Http;
using ChartFinder.Api.Configuration;
using ChartFinder.Common.Versioning;

var builder = WebApplication.CreateBuilder(args);

// configuration files in best order
var config = builder.Configuration;
var env = builder.Environment;
config.Sources.Clear();
config
    .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
    .AddJsonFile("local.appsettings.json", optional: true, reloadOnChange: true)
    .AddJsonFile($"appsettings.{env.EnvironmentName}.json", optional: true, reloadOnChange:
true)
    .AddJsonFile($"local.appsettings.{env.EnvironmentName}.json", optional: true,
reloadOnChange: true);
if (env.IsDevelopment())
    config.AddUserSecrets<Program>(optional: true);
config
    .AddEnvironmentVariables()
    .AddCommandLine(args); // keep last to mirror the default builder

// Add services to the container.
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddOpenApiDocument(settings =>
{
    settings.Title = "Chart Finder API";
    settings.Version = "v1";
    settings.Description = "Musician-facing API for discovering and purchasing charts.";
});
builder.Services.AddOptions<DynamoOptions>()
    .Bind(builder.Configuration.GetSection(DynamoOptions.SectionName))
    .ValidateDataAnnotations()
    .Validate(options => !string.IsNullOrWhiteSpace(options.TableName), "TableName must be provided.")
    .ValidateOnStart();
builder.Services.AddChartFinderVersion(typeof(Program).Assembly);

// Add AWS Lambda support. When application is run in Lambda Kestrel is swapped out as the web server with Amazon.Lambda.AspNetCoreServer. This
// package will act as the webserver translating request and responses between the Lambda event source and ASP.NET Core.
builder.Services.AddAWSLambdaHosting(LambdaEventSource.RestApi);

var app = builder.Build();


// hi
app.UseHttpsRedirection();
if (app.Environment.IsDevelopment())
{
    app.UseOpenApi(options => options.Path = "/swagger/v1/swagger.json");
    app.UseSwaggerUi(settings =>
    {
        settings.Path = "/swagger";
        settings.DocumentPath = "/swagger/v1/swagger.json";
        settings.DocumentTitle = "Chart Finder API v1";
    });
}
app.UseAuthorization();
app.MapControllers();

var aboutPagePath = Path.Combine(app.Environment.ContentRootPath, "Pages", "About.html");
var supportPagePath = Path.Combine(app.Environment.ContentRootPath, "Pages", "Support.html");

IResult ServeStaticPage(string path)
{
    if (!File.Exists(path))
    {
        return Results.Problem(
            detail: $"Missing static page: {Path.GetFileName(path)}",
            statusCode: StatusCodes.Status500InternalServerError);
    }

    return Results.File(path, "text/html; charset=utf-8");
}

app.MapGet("/", () => ServeStaticPage(aboutPagePath))
    .ExcludeFromDescription();

app.MapGet("/support", () => ServeStaticPage(supportPagePath))
    .ExcludeFromDescription();

app.Run();
