param
(
    [Parameter(Mandatory=$true)]
    $Command
)

$Command = Get-Command $Command
$metadata = New-Object System.Management.Automation.CommandMetadata $Command
[System.Management.Automation.ProxyCommand]::Create($metadata)
