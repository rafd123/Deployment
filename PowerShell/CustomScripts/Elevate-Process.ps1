[CmdletBinding()]
param (
    [Parameter(
        Position = 0,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true)]
    [Alias("FullName")]
    [string]$FilePath = 'powershell'
)

[string]$arguments = $args;
$psi = new-object System.Diagnostics.ProcessStartInfo $FilePath;
$psi.Arguments = $arguments;
$psi.Verb = "runas";
$psi.WorkingDirectory = Get-Location;
[void][System.Diagnostics.Process]::Start($psi);