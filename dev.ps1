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

#region WSL
$wslInstallationResult = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -ErrorAction SilentlyContinue `
| Enable-WindowsOptionalFeature -Online -NoRestart

if ($wslInstallationResult) {
    if ($wslInstallationResult.RestartNeeded) {
        New-ItemProperty `
            HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce `
            -Name InstallLxRunOffline `
            -Value "powershell.exe -NoExit `"& { sudo cinst lxrunoffline -y }`"" `
            -Force
    } else {
        cinst lxrunoffline -y
    }

    if (-not (Get-AppxPackage CanonicalGroupLimited.Ubuntu* -ErrorAction SilentlyContinue)) {
        & {
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri https://aka.ms/wsl-ubuntu-1604 -OutFile $env:TEMP\Ubuntu.appx -UseBasicParsing
        }

        Add-AppxPackage -Path $env:TEMP\Ubuntu.appx

        $installLocation = (Get-AppxPackage CanonicalGroupLimited.Ubuntu*).InstallLocation
        New-ItemProperty `
            HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce `
            -Name InitWSL `
            -Value "powershell.exe -NoExit `"& { cd ~; & '$installLocation\ubuntu' -c './.deployment/wsl/deploy.sh' }`"" `
            -Force
    }
}
#endregion

#region vcxsrv
cinst vcxsrv -y
New-Item -Path "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\config.xlaunch" -ItemType SymbolicLink -Value "~\.deployment\VcXsrv\config.xlaunch" -Force
Start-Process "~\.deployment\VcXsrv\config.xlaunch"
#endregion

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

#region GitExtensions
# Pre-set GitExtension settings to prevent it from overwriting .gitconfig
cinst gitextensions -y
New-Item HKCU:\Software\GitExtensions -Force
New-ItemProperty -Path HKCU:\Software\GitExtensions -Name CheckSettings -Value 'false' -Force
New-ItemProperty -Path HKCU:\Software\GitExtensions -Name gitcommand -Value (Get-Command git | Select-Object -ExpandProperty Path) -Force
mkdir "$($env:APPDATA)\GitExtensions\GitExtensions" -Force | Out-Null
Copy-Item "~\.deployment\GitExtensions\GitExtensions.settings" "$($env:APPDATA)\GitExtensions\GitExtensions\GitExtensions.settings" -Force
#endregion

cinst nodejs -y
cinst windbg -y

#region Visual Studio
cinst visualstudio2019community -y
cinst visualstudio2019-workload-manageddesktop -y
cinst visualstudio2019-workload-netweb -y
cinst visualstudio2019-workload-universal -y
cinst visualstudio2019-workload-netcoretools -y
cinst dotnetcore-sdk -y
cinst resharper -y
#endregion

Remove-Item "$([environment]::GetFolderPath('Desktop'))\*.lnk"
Remove-Item "$([environment]::GetFolderPath('CommonDesktop'))\*.lnk"
