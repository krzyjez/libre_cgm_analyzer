using Microsoft.AspNetCore.Mvc;
using LibreCgmAnalyzer.Api.Services;
using System;
using System.IO;

namespace LibreCgmAnalyzer.Api.Controllers;

[ApiController]
[Route("api")]
public class DataController : ControllerBase
{
  private readonly ILogger<DataController> _logger;
  private readonly BlobStorageService _blobStorageService;
  private const string DataContainer = "data";
  private const string ImagesContainer = "images";

  public DataController(ILogger<DataController> logger, BlobStorageService blobStorageService)
    : base()
  {
    _logger = logger;
    _blobStorageService = blobStorageService;
  }

  [HttpGet("csv-data")]
  public async Task<IActionResult> GetCsvData()
  {
    try
    {
      var stream = await _blobStorageService.GetFileAsync(DataContainer, "data.csv");
      return File(stream, "text/csv");
    }
    catch (Exception ex)
    {
      _logger.LogError(ex, "Błąd podczas pobierania pliku CSV");
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
      
      await _blobStorageService.SaveFileAsync(DataContainer, "data.csv", stream);
      return Ok();
    }
    catch (Exception ex)
    {
      _logger.LogError(ex, "Błąd podczas zapisywania pliku CSV");
      return BadRequest();
    }
  }

  [HttpGet("user-data")]
  public async Task<IActionResult> GetUserData()
  {
    try
    {
      var stream = await _blobStorageService.GetFileAsync(DataContainer, "user_data.json");
      return File(stream, "application/json");
    }
    catch (Exception ex)
    {
      _logger.LogError(ex, "Błąd podczas pobierania danych użytkownika");
      return NotFound();
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
      using var writer = new StreamWriter(stream);
      await writer.WriteAsync(content);
      await writer.FlushAsync();
      stream.Position = 0;
      
      await _blobStorageService.SaveFileAsync(DataContainer, "user_data.json", stream);
      return Ok();
    }
    catch (Exception ex)
    {
      _logger.LogError(ex, "Błąd podczas zapisywania danych użytkownika");
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
      var fileName = $"{DateTime.UtcNow:yyyyMMddHHmmss}_{file.FileName}";
      await _blobStorageService.SaveFileAsync(ImagesContainer, fileName, stream);
      return Ok(new { fileName });
    }
    catch (Exception ex)
    {
      _logger.LogError(ex, "Błąd podczas uploadowania obrazka");
      return BadRequest();
    }
  }

  [HttpDelete("images/{fileName}")]
  public async Task<IActionResult> DeleteImage(string fileName)
  {
    try
    {
      await _blobStorageService.DeleteFileAsync(ImagesContainer, fileName);
      return Ok();
    }
    catch (Exception ex)
    {
      _logger.LogError(ex, "Błąd podczas usuwania obrazka");
      return BadRequest();
    }
  }

  [HttpGet("images/{fileName}")]
  public async Task<IActionResult> GetImage(string fileName)
  {
    try
    {
      var stream = await _blobStorageService.GetFileAsync(ImagesContainer, fileName);
      return File(stream, "image/jpeg"); // lub "image/png" w zależności od typu obrazka
    }
    catch (Exception ex)
    {
      _logger.LogError(ex, "Błąd podczas pobierania obrazka");
      return NotFound();
    }
  }
}
