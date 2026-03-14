using System.Threading.Tasks;

namespace Narko.Node.Desktop.Services;

public sealed class AutoUpdateService
{
    public Task<AutoUpdateCheckResult> CheckForUpdateAsync()
    {
        return Task.FromResult(new AutoUpdateCheckResult(
            IsUpdateAvailable: false,
            Message: "Not implemented yet. Hook this to your release feed / signed package channel."
        ));
    }
}

public readonly record struct AutoUpdateCheckResult(bool IsUpdateAvailable, string Message);
