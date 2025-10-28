using ChartFinder.Api.Configuration;

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
builder.Services.AddOptions<DynamoOptions>()
    .Bind(builder.Configuration.GetSection(DynamoOptions.SectionName))
    .ValidateDataAnnotations()
    .Validate(options => !string.IsNullOrWhiteSpace(options.TableName), "TableName must be provided.")
    .ValidateOnStart();

// Add AWS Lambda support. When application is run in Lambda Kestrel is swapped out as the web server with Amazon.Lambda.AspNetCoreServer. This
// package will act as the webserver translating request and responses between the Lambda event source and ASP.NET Core.
builder.Services.AddAWSLambdaHosting(LambdaEventSource.RestApi);

var app = builder.Build();


app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

app.MapGet("/", () => "Welcome to running ASP.NET Core Minimal API on AWS Lambda");

app.Run();