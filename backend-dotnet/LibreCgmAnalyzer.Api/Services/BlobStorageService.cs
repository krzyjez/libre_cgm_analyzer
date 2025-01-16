using Azure.Storage.Blobs;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System;
using System.IO;

namespace LibreCgmAnalyzer.Api.Services;

public class BlobStorageService
{
  private readonly BlobServiceClient _blobServiceClient;
  private readonly ILogger<BlobStorageService> _logger;
  private const string DataContainer = "data";
  private const string ImagesContainer = "images";

  public BlobStorageService(IConfiguration configuration, ILogger<BlobStorageService> logger)
  {
    _logger = logger;
    var connectionString = configuration["AzureStorage:ConnectionString"] 
      ?? throw new ArgumentNullException(nameof(configuration), "AzureStorage:ConnectionString not configured");
    _blobServiceClient = new BlobServiceClient(connectionString);
  }

  public async Task InitializeAsync()
  {
    // Inicjalizacja kontenera data
    var dataContainerClient = _blobServiceClient.GetBlobContainerClient(DataContainer);
    if (!await dataContainerClient.ExistsAsync())
    {
      await dataContainerClient.CreateAsync();
      _logger.LogInformation("Utworzono kontener {Container}", DataContainer);
    }
    else
    {
      _logger.LogInformation("Kontener {Container} już istnieje", DataContainer);
    }

    // Inicjalizacja kontenera images
    var imagesContainerClient = _blobServiceClient.GetBlobContainerClient(ImagesContainer);
    if (!await imagesContainerClient.ExistsAsync())
    {
      await imagesContainerClient.CreateAsync();
      _logger.LogInformation("Utworzono kontener {Container}", ImagesContainer);
    }
    else
    {
      _logger.LogInformation("Kontener {Container} już istnieje", ImagesContainer);
    }
  }

  public async Task<Stream> GetFileAsync(string container, string fileName)
  {
    var containerClient = _blobServiceClient.GetBlobContainerClient(container);
    var blobClient = containerClient.GetBlobClient(fileName);
    return await blobClient.OpenReadAsync();
  }

  public async Task SaveFileAsync(string container, string fileName, Stream content)
  {
    var containerClient = _blobServiceClient.GetBlobContainerClient(container);
    var blobClient = containerClient.GetBlobClient(fileName);
    await blobClient.UploadAsync(content, true);
  }

  public async Task DeleteFileAsync(string container, string fileName)
  {
    var containerClient = _blobServiceClient.GetBlobContainerClient(container);
    var blobClient = containerClient.GetBlobClient(fileName);
    await blobClient.DeleteIfExistsAsync();
  }
}
