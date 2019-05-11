# Determine if we are running as admin
$wid = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$prp = New-Object System.Security.Principal.WindowsPrincipal($wid)
$adm = [System.Security.Principal.WindowsBuiltInRole]::Administrator
$isAdmin = $prp.IsInRole($adm)

if (-not $isAdmin) {
    Write-Error "Please run from an elevated prompt."
    #Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Unrestricted -Command `"& $($MyInvocation.MyCommand.Definition)`""
    return
}

$DeploymentDirectory = $PSScriptRoot
New-Item -Path "~/.deployment" -ItemType SymbolicLink -Value $DeploymentDirectory -Force

#region .gitconfig
if (-not (Test-Path "$HOME\.gitconfig")) {
    Write-Host 'Copying .gitconfig'
    Copy-Item "$DeploymentDirectory\git\.gitconfig" ~\.gitconfig
}

New-Item -Path "~\.gitconfig_common.xplat" -ItemType SymbolicLink -Value "~\.deployment\git\.gitconfig_common" -Force
New-Item -Path "~\.gitconfig_common.plat" -ItemType SymbolicLink -Value "~\.deployment\git\windows\.gitconfig_common" -Force
mkdir ~\.ssh -Force
Out-File -InputObject '' ~\.ssh\placeholder
Set-Service ssh-agent -StartupType Automatic
#endregion

#region PowerShell
$PowerShellDirectory = Split-Path $profile
if (Get-Item $PowerShellDirectory -ErrorAction SilentlyContinue | Where-Object { -not $_.LinkType }) {
    Rename-Item $PowerShellDirectory "$PowerShellDirectory.backup"
}
New-Item -Path $PowerShellDirectory -ItemType SymbolicLink -Value "~\.deployment\PowerShell" -Force
# For some reason, the link gets created all lower case; fix the case by renaming
Rename-Item $PowerShellDirectory "$PowerShellDirectory.1"
Rename-Item "$PowerShellDirectory.1" $PowerShellDirectory

$shellApp = New-Object -ComObject shell.application
$fonts = $shellApp.NameSpace(0x14)
$installedFontNames = $fonts.Items() | Select-Object -ExpandProperty Name
if ($installedFontNames -notcontains 'DejaVu Sans Mono for Powerline') {
    Remove-Item "$env:temp\fonts" -Recurse -Force -ErrorAction SilentlyContinue
    git clone https://github.com/PowerLine/fonts "$env:temp\fonts"
    & "$env:TEMP\fonts\install.ps1" dejavu*
}

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module PowerLine -Scope CurrentUser -AllowClobber -Force
Install-Module posh-git -Scope CurrentUser -AllowClobber -Force
Install-Module z -Scope CurrentUser -AllowClobber -Force
Install-Module DirColors -Scope CurrentUser -Force

Remove-Item HKCU:\Console -Recurse
reg import "$HOME\.deployment\Console\console.reg"
Remove-Item "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Windows PowerShell\*"
Copy-Item "~\.deployment\Console\Windows PowerShell.lnk" "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Windows PowerShell\"
#endregion

#region Developer mode
Set-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\AppModelUnlock -Name AllowDevelopmentWithoutDevLicense -Value 1
#endregion

#region Windows Defender
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender' -Name DisableAntiSpyware -Value 1
#endregion

#region Replace annoying "bling" sound
Get-ChildItem 'HKCU:\AppEvents\Schemes\Apps\.Default\' -Recurse |
    Get-ItemProperty -Name '(default)' -ErrorAction SilentlyContinue |
    Where-Object { $_.'(default)' -like '*\Windows Background.wav' } |
    ForEach-Object {
        Set-ItemProperty `
            -Path $_.PSPath `
            -Name '(default)' `
            -Value '%SystemRoot%\media\Windows Information Bar.wav' `
            -Type ExpandString
    }
#endregion

Get-Service beep | Set-Service -StartupType Disabled

#region Wi-Fi MAC randomization
if (Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\mrvlpcie8897\ MACRandomization -ErrorAction SilentlyContinue) {
    Set-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\mrvlpcie8897\ MACRandomization -Value 1
}
#endregion

#region Explorer settings
# Hide Recycle Bin desktop icon
New-Item 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel' -Force
Set-ItemProperty `
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel' `
    '{645FF040-5081-101B-9F08-00AA002F954E}' `
    -Value 1 `
    -Type DWord `
    -Force

# Hide OneDrive desktop icon
Set-ItemProperty `
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel' `
    '{018D5C66-4533-4307-9B53-224DE2ED1FE6}' `
    -Value 1 `
    -Type DWord `
    -Force

# File options
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name Hidden -Value 1
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name HideFileExt -Value 0

# Cortana Icon
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name SearchboxTaskbarMode -Value 1

# Hide Task View Icon
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name ShowTaskViewButton -Value 0

# Allows Slack to bring links to the foreground
Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name ForegroundLockTimeout -Value 0
Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name ForegroundFlashCount -Value 0

# Three Finger Tap = Mouse Back Button
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\PrecisionTouchPad' -Name ThreeFingerTapEnabled -Value 65535
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\PrecisionTouchPad' -Name CustomThreeFingerTap -Value 5

Get-Process explorer | Stop-Process -Force
#endregion

#region Theme
& "~\.deployment\theme.deskthemepack"
New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\DWM' -Name ColorPrevalence  -Value 1 -PropertyType DWORD -Force
New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\DWM' -Name AccentColor -Value 4280756521 -PropertyType DWORD -Force
New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\DWM' -Name AccentColorInactive -Value 4280756521 -PropertyType DWORD -Force
New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name AppsUseLightTheme -Value 0 -PropertyType DWORD -Force
New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name ColorPrevalence -Value 0 -PropertyType DWORD -Force
New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name EnableTransparency -Value 1 -PropertyType DWORD -Force
New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name SystemUsesLightTheme -Value 0 -PropertyType DWORD -Force
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

#region Visual Studio Code
mkdir "$($env:APPDATA)\Code" -Force | Out-Null
New-Item -Path "$($env:APPDATA)\Code\User" -ItemType SymbolicLink -Value "~\.deployment\VSCode" -Force
cinst visualstudiocode -y
RefreshEnv
code --install-extension ms-vscode.PowerShell
code --install-extension streetsidesoftware.code-spell-checker
code --install-extension dbaeumer.vscode-eslint
code --install-extension esbenp.prettier-vscode
code --install-extension ms-python.python
code --install-extension alefragnani.numbered-bookmarks
code --install-extension mjmcloug.vscode-elixir
code --install-extension sammkj.vscode-elixir-formatter
#endregion

#region WSL
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -ErrorAction SilentlyContinue `
| Enable-WindowsOptionalFeature -Online -NoRestart

if (-not (Get-AppxPackage CanonicalGroupLimited.UbuntuonWindows -ErrorAction SilentlyContinue)) {
    . {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri https://aka.ms/wsl-ubuntu-1604 -OutFile $env:TEMP\Ubuntu.appx -UseBasicParsing
    }

    Add-AppxPackage -Path $env:TEMP\Ubuntu.appx

    $installLocation = (Get-AppxPackage CanonicalGroupLimited.UbuntuonWindows).InstallLocation
    New-ItemProperty `
        HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce `
        -Name InitWSL `
        -Value "powershell.exe -NoExit `"& { cd ~; & '$installLocation\ubuntu' -c './.deployment/wsl/deploy.sh' }`"" `
        -Force
}
#endregion

#region Windows Sandbox
Get-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM -ErrorAction SilentlyContinue `
| Enable-WindowsOptionalFeature -Online -NoRestart
#endregion

#region Hyper
cinst hyper -y
New-Item -Path "$env:APPDATA\Hyper\.hyper.js" -ItemType SymbolicLink -Value "~\.deployment\hyper\.hyper.js" -Force
New-Item -Path "~\.hyper.js" -ItemType SymbolicLink -Value "~\.deployment\hyper\.hyper.js" -Force
#endregion

#region ConEmu
cinst conemu -y
Copy-Item "~\.deployment\ConEmu\ConEmu.xml" "$($env:APPDATA)\ConEmu.xml" -Force
#endregion

#region Sublime Text
mkdir "$($env:APPDATA)\Sublime Text 3\Packages" -Force | Out-Null
New-Item -Path "$($env:APPDATA)\Sublime Text 3\Packages\User" -ItemType SymbolicLink -Value "~\.deployment\Sublime\Packages\User" -Force
cinst sublimetext3 -y
Write-Output 'st3' | cinst sublimetext3.packagecontrol -y
#endregion

#region Sublime Merge
mkdir "$($env:APPDATA)\Sublime Merge\Packages" -Force | Out-Null
New-Item -Path "$($env:APPDATA)\Sublime Merge\Packages\User" -ItemType SymbolicLink -Value "~\.deployment\Sublime Merge\Packages\User" -Force
#endregion

#region vim
cinst vim -y
New-Item -Path '~\vimfiles' -Value '~\.deployment\wsl\vim\.vim' -ItemType SymbolicLink -Force
New-Item -Path '~\_vimrc' -Value '~\.deployment\wsl\vim\.vimrc' -ItemType SymbolicLink -Force
#endregion

#region vcxsrv
cinst vcxsrv -y
New-Item -Path "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\config.xlaunch" -ItemType SymbolicLink -Value "~\.deployment\VcXsrv\config.xlaunch" -Force
Start-Process "~\.deployment\VcXsrv\config.xlaunch"
#endregion

#region Python
cinst python3 -y
refreshenv
$env:PIP_REQUIRE_VIRTUALENV = 'false'
pip install ipython
pip install texttable
$env:PIP_REQUIRE_VIRTUALENV = 'true'
#endregion

#region AquaSnap
reg import "$HOME\.deployment\AquaSnap\AquaSnap.reg"
cinst aquasnap -y
#endregion

#region Ditto
cinst ditto -y
Start-Process "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Ditto\Ditto.lnk"
#endregion

#region Snagit
# cinst screenpresso --ignore-checksums -y
cinst snagit -y
mkdir "$($env:LOCALAPPDATA)\TechSmith\Snagit" -Force | Out-Null
New-Item -Path "$($env:LOCALAPPDATA)\TechSmith\Snagit\Presets2.xml" -ItemType SymbolicLink -Value "~\.deployment\Snagit\Presets2.xml" -Force
#endregion

#region VeraCrypt
mkdir "$($env:APPDATA)\VeraCrypt" -Force | Out-Null
New-Item -Path "$($env:APPDATA)\VeraCrypt\Configuration.xml" -ItemType SymbolicLink -Value "~\.deployment\VeraCrypt\Configuration.xml" -Force
cinst veracrypt -y
#endregion

cinst GoogleChrome -y
cinst edgedeflector -y
cinst beyondcompare -y
cinst sysinternals -y

Remove-Item "$([environment]::GetFolderPath('Desktop'))\*.lnk"
Remove-Item "$([environment]::GetFolderPath('CommonDesktop'))\*.lnk"
