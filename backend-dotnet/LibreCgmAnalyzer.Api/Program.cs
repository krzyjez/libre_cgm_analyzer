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

  // Konfiguracja Swagger
  builder.Services.AddSwaggerGen(c =>
  {
    c.SwaggerDoc("v1", new OpenApiInfo { 
      Title = "LibreCgmAnalyzer API", 
      Version = "v1",
      Description = "API do analizy danych z LibreCGM",
      Contact = new OpenApiContact
      {
        Name = "Krzysztof Jeziorny",
        Email = "krzysztof.jeziorny@gmail.com"
      }
    });
  });

  // Rejestracja BlobStorageService
  builder.Services.AddSingleton<IBlobStorageService>(sp =>
  {
    var connectionString = Environment.GetEnvironmentVariable("AZURE_STORAGE_CONNECTION_STRING") 
        ?? builder.Configuration["AzureStorage:ConnectionString"]
        ?? throw new InvalidOperationException("Connection string not found");
    return new BlobStorageService(connectionString, sp.GetRequiredService<ILogger<BlobStorageService>>());
  });

  // Konfiguracja CORS
  builder.Services.AddCors(options =>
  {
    options.AddPolicy("AllowAll", builder =>
    {
      builder.AllowAnyOrigin()
             .AllowAnyMethod()
             .AllowAnyHeader();
    });
  });

  var app = builder.Build();

  // Konfiguracja middleware
  // Zawsze włączamy Swagger w fazie rozwoju
  app.UseSwagger();
  app.UseSwaggerUI(c => 
  {
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "LibreCgmAnalyzer API v1");
    c.RoutePrefix = string.Empty; // Swagger UI będzie dostępny pod root URL
  });

  app.UseCors("AllowAll");
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
