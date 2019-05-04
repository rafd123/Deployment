param (
    [switch]$HostSpecific
)

if ($HostSpecific) {
    $profileFilePath = $PROFILE
} else {
    $profileFilePath = Join-Path (Split-Path $PROFILE) 'profile.ps1'
}

Open-TextEditor $profileFilePath