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

#region Hyper-V
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -ErrorAction SilentlyContinue `
| Enable-WindowsOptionalFeature -Online -NoRestart
#endregion

#region Visual Studio
cinst visualstudio2017professional -y
cinst visualstudio2017-workload-manageddesktop -y
cinst visualstudio2017-workload-netweb -y
cinst resharper -y
#endregion

cinst jetbrains-rider --version 2017.2.1 -y

#region ruby
#cinst ruby -version 2.2.4 -y # this is the max version that works with nokogiri
#cinst ruby2.devkit -y
#cmd /c gem install bundler -v 1.12.5 # this is the max version vagrant works with
#endregion

Install-Module AWSPowerShell -Scope CurrentUser -Force
Install-Module -Name SqlServer -Scope CurrentUser -AllowClobber -Force

cinst openvpn -y
cinst nodejs.install -y
cinst windbg -y
cinst Firefox -y
#cinst sqlyog -y
cinst sql-server-management-studio -y
cinst sql-server-express -y
cinst pgadmin4 -y
cinst elixir -y; refreshenv; mix local.hex --force; mix local.rebar --force
