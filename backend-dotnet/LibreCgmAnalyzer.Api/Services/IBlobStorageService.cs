using System.IO;
using System.Threading.Tasks;

namespace LibreCgmAnalyzer.Api.Services
{
    public interface IBlobStorageService
    {
        Task InitializeAsync();
        Task<Stream> GetFileAsync(string containerName, string fileName);
        Task SaveFileAsync(string containerName, string fileName, Stream content);
        Task DeleteFileAsync(string containerName, string fileName);
    }
}
