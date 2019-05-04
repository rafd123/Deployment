[CmdletBinding()]
param (
    [Parameter(
        Position = 0,
        Mandatory = $true,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true)]
    [Alias("FullName")]
    [string]$FilePath,

    [Parameter(
        Position = 1,
        Mandatory = $true)]
    [string]$Extension
)

$newName = [System.IO.Path]::GetFileName($FilePath)
$newName = [System.IO.Path]::GetFileNameWithoutExtension($newName) + "." + $Extension
Rename-Item $FilePath $newName