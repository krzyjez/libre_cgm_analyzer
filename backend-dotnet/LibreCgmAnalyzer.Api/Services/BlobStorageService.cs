using Azure.Storage.Blobs;
using Microsoft.Extensions.Logging;
using System;
using System.IO;
using System.Threading.Tasks;

namespace LibreCgmAnalyzer.Api.Services
{
    public class BlobStorageService : IBlobStorageService
    {
        private readonly BlobServiceClient _blobServiceClient;
        private readonly ILogger<BlobStorageService> _logger;
        private const string DataContainer = "data";
        private const string ImagesContainer = "images";

        public BlobStorageService(string connectionString, ILogger<BlobStorageService> logger)
        {
            _logger = logger;
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

        public async Task<Stream> GetFileAsync(string containerName, string fileName)
        {
            var containerClient = _blobServiceClient.GetBlobContainerClient(containerName);
            var blobClient = containerClient.GetBlobClient(fileName);
            return await blobClient.OpenReadAsync();
        }

        public async Task SaveFileAsync(string containerName, string fileName, Stream content)
        {
            var containerClient = _blobServiceClient.GetBlobContainerClient(containerName);
            var blobClient = containerClient.GetBlobClient(fileName);
            await blobClient.UploadAsync(content, true);
        }

        public async Task DeleteFileAsync(string containerName, string fileName)
        {
            var containerClient = _blobServiceClient.GetBlobContainerClient(containerName);
            var blobClient = containerClient.GetBlobClient(fileName);
            await blobClient.DeleteIfExistsAsync();
        }
    }
}
