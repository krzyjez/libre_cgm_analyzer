using Microsoft.AspNetCore.Mvc;
using LibreCgmAnalyzer.Api.Services;


namespace LibreCgmAnalyzer.Api.Controllers;

[ApiController]
[Route("api")]
public class DataController(IBlobStorageService blobStorageService, ILogger<DataController> logger) : ControllerBase
{
  private const string DataContainer = "data";
  private const string ImagesContainer = "images";

  [HttpGet("csv-data")]
  public async Task<IActionResult> GetCsvData()
  {
    try
    {
      var stream = await blobStorageService.GetFileAsync(DataContainer, "data.csv");
      return File(stream, "text/csv");
    }
    catch (Exception ex)
    {
      logger.LogError(ex, "Błąd podczas pobierania pliku CSV");
      return NotFound();
    }
  }

  [HttpPost("csv-data")]
  public async Task<IActionResult> SaveCsvData()
  {
    try
    {
      using var reader = new StreamReader(Request.Body);
      var content = await reader.ReadToEndAsync();
      using var stream = new MemoryStream();
      using var writer = new StreamWriter(stream);
      await writer.WriteAsync(content);
      await writer.FlushAsync();
      stream.Position = 0;
      
      await blobStorageService.SaveFileAsync(DataContainer, "data.csv", stream);
      return Ok();
    }
    catch (Exception ex)
    {
      logger.LogError(ex, "Błąd podczas zapisywania pliku CSV");
      return BadRequest();
    }
  }

  [HttpGet("user-data")]
  public async Task<IActionResult> GetUserData()
  {
    try
    {
      Stream? stream;
      try
      {
        stream = await blobStorageService.GetFileAsync(DataContainer, "user_data.json");
      }
      catch (Exception)
      {
        // Jeśli nie ma pliku, zwracamy pusty obiekt JSON
        logger.LogInformation("Brak danych użytkownika - zwracam pusty obiekt");
        return Content("{}", "application/json; charset=utf-8");
      }
      
      return File(stream, "application/json; charset=utf-8");
    }
    catch (Exception ex)
    {
      logger.LogError(ex, "Błąd podczas pobierania danych użytkownika");
      return BadRequest();
    }
  }

  [HttpPost("user-data")]
  public async Task<IActionResult> SaveUserData()
  {
    try
    {
      using var reader = new StreamReader(Request.Body);
      var content = await reader.ReadToEndAsync();
      using var stream = new MemoryStream();
      using var writer = new StreamWriter(stream, encoding: System.Text.Encoding.UTF8);
      await writer.WriteAsync(content);
      await writer.FlushAsync();
      stream.Position = 0;
      
      await blobStorageService.SaveFileAsync(DataContainer, "user_data.json", stream);
      return Ok();
    }
    catch (Exception ex)
    {
      logger.LogError(ex, "Błąd podczas zapisywania danych użytkownika");
      return BadRequest();
    }
  }

  [HttpPost("images")]
  public async Task<IActionResult> UploadImage([FromForm] IFormFile file)
  {
    try
    {
      if (file == null || file.Length == 0)
        return BadRequest("Brak pliku");

      using var stream = file.OpenReadStream();
      var myFilename = $"{DateTime.UtcNow:yyyyMMddHHmmss}_{file.FileName}";
      await blobStorageService.SaveFileAsync(ImagesContainer, myFilename, stream);
      
      return Ok(new { filename = myFilename });
    }
    catch (Exception ex)
    {
      logger.LogError(ex, "Błąd podczas uploadowania obrazka");
      return BadRequest();
    }
  }

  [HttpDelete("images/{fileName}")]
  public async Task<IActionResult> DeleteImage(string fileName)
  {
    try
    {
      await blobStorageService.DeleteFileAsync(ImagesContainer, fileName);
      return Ok();
    }
    catch (Exception ex)
    {
      logger.LogError(ex, "Błąd podczas usuwania obrazka");
      return BadRequest();
    }
  }

  [HttpGet("images/{fileName}")]
  public async Task<IActionResult> GetImage(string fileName)
  {
    try
    {
      var stream = await blobStorageService.GetFileAsync(ImagesContainer, fileName);
      
      // Określamy Content-Type na podstawie rozszerzenia pliku
      string contentType = "image/jpeg"; // domyślnie
      var extension = Path.GetExtension(fileName).ToLower();
      if (extension == ".png")
      {
        contentType = "image/png";
      }
      else if (extension == ".gif")
      {
        contentType = "image/gif";
      }
      
      return File(stream, contentType);
    }
    catch (Exception ex)
    {
      logger.LogError(ex, "Błąd podczas pobierania obrazka");
      return NotFound();
    }
  }
}
