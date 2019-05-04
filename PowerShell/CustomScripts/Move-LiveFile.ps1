[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$SourceFolderId,

    [Parameter(Mandatory=$true)]
    [string]$DestinationDirectoryPath,

    [Parameter(Mandatory=$true)]
    [string]$ClientId,

    [Parameter(Mandatory=$true)]
    [string]$Secret,

    [Parameter(Mandatory=$true)]
    [string]$ProfileName
)

function GetAccessToken {
    Get-LiveAccessToken -ClientId $ClientId -Secret $Secret -ProfileName $ProfileName
}

$ErrorActionPreference = 'Stop'
Import-Module Live

if (-not (Test-Path $DestinationDirectoryPath -PathType Container)) {
    mkdir $DestinationDirectoryPath | Out-Null
}

$DestinationDirectoryPath = (Resolve-Path $DestinationDirectoryPath).Path
$webClient = New-Object System.Net.WebClient

$pageUrl = "$SourceFolderId/files?limit=10"
while($pageUrl) {
    $page = Invoke-LiveRestMethod -Resource $pageUrl -AccessToken (GetAccessToken)

    $page | ConvertTo-Json -Depth 10| Out-String | Write-Host

    $page.data | ForEach-Object {
        $file = $_
        $filePath = Join-Path $DestinationDirectoryPath $file.name
        $fileUrl = $file.source

        if ($fileUrl) {
            Write-Host "Downloading $fileUrl to $filePath"
            $webClient.DownloadFile($fileUrl, $filePath)

            if (-not (Test-Path $filePath -PathType Leaf)) {
                throw "$filePath not found!"
            }

            Write-Host "Deleting $fileUrl"
            Invoke-LiveRestMethod $file.Id -Method Delete -AccessToken (GetAccessToken)
        }
    }

    if ($page.paging) {
        $pageUrl = $page.paging.next
    } else {
        $pageUrl = $null
    }
}
