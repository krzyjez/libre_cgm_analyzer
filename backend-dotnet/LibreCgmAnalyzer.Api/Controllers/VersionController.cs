using Microsoft.AspNetCore.Mvc;

namespace LibreCgmAnalyzer.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class VersionController : ControllerBase
{
    [HttpGet]
    public IActionResult GetVersion()
    {
        return Ok(new { version = Constants.ApiVersion });
    }
}
