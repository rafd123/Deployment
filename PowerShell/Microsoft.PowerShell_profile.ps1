# Initialize-PowerLinePrompt
# Set-Theme RafD123

if (-not $env:SSH_CONNECTION -or $env:TERM -like '*color*') {
    Set-PoshPrompt -Theme ~\OneDrive\Documents\PowerShell\PoshThemes\RafD123.omp.json
}

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
