# Determine if we are running as admin
$wid = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$prp = New-Object System.Security.Principal.WindowsPrincipal($wid)
$adm = [System.Security.Principal.WindowsBuiltInRole]::Administrator
$isAdmin = $prp.IsInRole($adm)

if(-not $isAdmin) {
    Write-Error "Please run from an elevated prompt."
    #Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Unrestricted -Command `"& $($MyInvocation.MyCommand.Definition)`""
    return
}

. $PSScriptRoot\base.ps1

#region Hyper-V
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -ErrorAction SilentlyContinue `
| Enable-WindowsOptionalFeature -Online -NoRestart

Get-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -ErrorAction SilentlyContinue `
| Enable-WindowsOptionalFeature -Online -NoRestart
#endregion

#region Docker
cinst docker-desktop -y
Install-Module DockerCompletion -Scope CurrentUser -Force
#endregion

#region Visual Studio
cinst visualstudio2017professional -y
cinst visualstudio2017-workload-manageddesktop -y
cinst visualstudio2017-workload-netweb -y
cinst resharper -y
#endregion

cinst windbg -y

Remove-Item "$([environment]::GetFolderPath('Desktop'))\*.lnk"
Remove-Item "$([environment]::GetFolderPath('CommonDesktop'))\*.lnk"
