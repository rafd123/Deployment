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

Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
cinst git -y --package-parameters='/NoAutoCrlf'
Import-Module "$env:ChocolateyInstall\helpers\chocolateyInstaller.psm1"
Update-SessionEnvironment

$deploymentDir = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Deployment'

git clone https://github.com/rafd123/Deployment.git $deploymentDir

if (-not $DeployType) {
   $DeployType = 'base'
}

& "$deploymentDir\$DeployType.ps1"
