# ChartFinder.Api

- Purpose: ASP.NET Core API exposed via AWS Lambda in production and containers locally.
- Key areas: `Controllers/`, `Configuration/`, and `Program.cs` for startup wiring.
- Configuration: Uses layered `appsettings*.json` plus environment variables (Lambda supplies table name and other secrets).
- Local run: `dotnet run` from this directory or invoke through the solution.
