#region environment
Set-StrictMode -version latest

$Host.UI.RawUI.WindowTitle = 'PowerShell'

$profileDirectory = Split-Path $profile
$env:path += ";$(Join-Path $profileDirectory 'CustomScripts')"
$env:PSModulePath += ";$(Join-Path $profileDirectory 'CustomModules')"
$env:PIP_REQUIRE_VIRTUALENV='true'
$env:GIT_SSH="$env:SystemRoot\System32\OpenSSH\ssh.exe"

$docs = [System.Environment]::GetFolderPath('MyDocuments')

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("UseDeclaredVarsMoreThanAssignments", "desktop")]
$desktop = [System.Environment]::GetFolderPath('Desktop')

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("UseDeclaredVarsMoreThanAssignments", "projects")]
$projects = Join-Path $docs 'Projects'
#endregion

#region aliases
Set-Alias done Show-CommandCompleteNotification
Set-Alias u Set-LocationAncestor
Set-Alias e Open-Explorer
Set-Alias gh Get-Help
Set-Alias cl Copy-LocationToClipboard
Set-Alias fs Search-Code
Set-Alias n Open-TextEditor
Set-Alias ss Select-String
Set-Alias dl Set-LocationAlias
Set-Alias su Elevate-Process
Set-Alias ch Copy-HistoryToClipboard
Set-Alias sw Search-Web
Set-Alias pt ConvertTo-PrettyTable
Set-Alias -Name octave -Value 'C:\Octave\Octave-4.2.0\bin\octave-cli.exe'
Remove-Item alias:\curl -ErrorAction SilentlyContinue; Set-Alias -Name curl -Value "$env:ProgramFiles\Git\mingw64\bin\curl.exe" -Force
#endregion

#region functions
function rider {
    $rider = Get-ChildItem ${env:ProgramFiles(x86)}\JetBrains,$env:ProgramFiles\JetBrains rider64.exe -Recurse -ErrorAction SilentlyContinue `
    | Sort-Object { $_.VersionInfo.ProductVersionRaw } -Descending `
    | Select-Object -First 1 `
    | Select-Object -ExpandProperty FullName `

    Write-Warning $rider
    & $rider $args
}

function prompt {
    Set-StrictMode -Off

    Write-Host ''
    Write-Host (Get-Location).Path -NoNewline -ForegroundColor DarkGray

	Write-VcsStatus

    $nextHistoryId = (Get-History -Count 1).Id + 1
    Write-Host "`n[$nextHistoryId]>" -ForegroundColor DarkGray -NoNewline
    return " "
}

function title {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$NewTitle
    )

    [System.Console]::Title = $NewTitle
}
#endregion

#region imports
Import-Module posh-git
$global:GitPromptSettings.WorkingForegroundColor = [ConsoleColor]::Red
$global:GitPromptSettings.LocalWorkingStatusForegroundColor = [ConsoleColor]::Red
$global:GitPromptSettings.IndexForegroundColor = [ConsoleColor]::Green

Import-Module z

$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

Import-Module DirColors
Update-DirColors ~/.deployment/wsl/.dircolors

Set-PSReadlineOption -ContinuationPrompt " ... "
#endregion

#region default param values
$PSDefaultParameterValues["Out-Default:OutVariable"] = "___"
#endregion

#region load private profiles
$PrivateProfilesRoot = "$(Split-Path $PROFILE).private"
if (Test-Path $PrivateProfilesRoot -Type Container) {
    Get-ChildItem $PrivateProfilesRoot profile.ps1 -Recurse | ForEach-Object { . $_.FullName }
}
#endregion

#region tmux
function tmux {
    param (
        [switch]$UseBashConfig
    )

    if ($UseBashConfig) {
        bash -c "tmux $args"
    } else {
        bash -c "tmux -f ~/.deployment/wsl/tmux/pstmux.conf $args"
    }
}
#endregion
