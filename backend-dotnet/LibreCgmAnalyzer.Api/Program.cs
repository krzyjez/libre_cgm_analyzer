using Serilog;
using Serilog.Events;
using LibreCgmAnalyzer.Api.Services;
using Microsoft.OpenApi.Models;

// Konfiguracja Serilog
Log.Logger = new LoggerConfiguration()
  .MinimumLevel.Debug()
  .MinimumLevel.Override("Microsoft", LogEventLevel.Information)
  .WriteTo.Console()
  .CreateLogger();

try
{
  Log.Information("Uruchamianie aplikacji...");

  var builder = WebApplication.CreateBuilder(args);

  // Konfiguracja Serilog
  builder.Host.UseSerilog();

  // Dodanie kontrolerów
  builder.Services.AddControllers();
  builder.Services.AddEndpointsApiExplorer();

  // Konfiguracja CORS
  builder.Services.AddCors();

  // Konfiguracja Swagger
  builder.Services.AddSwaggerGen(c =>
  {
    c.SwaggerDoc(LibreCgmAnalyzer.Api.Constants.ApiVersion, new OpenApiInfo { 
      Title = "LibreCgmAnalyzer API", 
      Version = LibreCgmAnalyzer.Api.Constants.ApiVersion,
      Description = "API do analizy danych z LibreCGM",
      Contact = new OpenApiContact
      {
        Name = "Krzysztof Jeż",
        Email = "krzyjez@gmail.com"
      }
    });
  });

  // Rejestracja BlobStorageService
  builder.Services.AddSingleton<IBlobStorageService>(sp =>
  {
    try 
    {
      var connectionString = Environment.GetEnvironmentVariable("AZURE_STORAGE_CONNECTION_STRING") 
          ?? builder.Configuration["AzureStorage:ConnectionString"];
      
      if (string.IsNullOrEmpty(connectionString))
      {
        Log.Error("Connection string is null or empty. Check AZURE_STORAGE_CONNECTION_STRING environment variable.");
        throw new InvalidOperationException("Azure Storage connection string not found in configuration");
      }

      Log.Information("Successfully configured Azure Storage connection");
      return new BlobStorageService(connectionString, sp.GetRequiredService<ILogger<BlobStorageService>>());
    }
    catch (Exception ex)
    {
      Log.Error(ex, "Failed to configure BlobStorageService");
      throw;
    }
  });

  var app = builder.Build();

  // Konfiguracja middleware
  // Zawsze włączamy Swagger w fazie rozwoju
  app.UseSwagger();
  app.UseSwaggerUI(c => 
  {
    c.SwaggerEndpoint($"/swagger/{LibreCgmAnalyzer.Api.Constants.ApiVersion}/swagger.json", $"LibreCgmAnalyzer API {LibreCgmAnalyzer.Api.Constants.ApiVersion}");
    c.RoutePrefix = string.Empty; // Swagger UI będzie dostępny pod root URL
  });

  // Włączenie CORS
  app.UseCors(x => x
      .AllowAnyMethod()
      .AllowAnyHeader()
      .SetIsOriginAllowed(origin => true) // allow any origin
      .AllowCredentials());

  app.UseHttpsRedirection();
  app.UseAuthorization();
  app.MapControllers();

  // Inicjalizacja kontenerów Blob Storage
  using (var scope = app.Services.CreateScope())
  {
    var blobService = scope.ServiceProvider.GetRequiredService<IBlobStorageService>();
    await blobService.InitializeAsync();
  }

  Log.Information("Aplikacja uruchomiona, nasłuchiwanie...");
  app.Run();
}
catch (Exception ex)
{
  Log.Fatal(ex, "Aplikacja zatrzymana z powodu błędu");
}
finally
{
  Log.CloseAndFlush();
}
