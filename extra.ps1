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

# Install-Module AWSPowerShell -Scope CurrentUser -Force

# Install-Module -Name SqlServer -Scope CurrentUser -AllowClobber -Force
# cinst sql-server-management-studio -y
# cinst sql-server-express -y

# cinst jetbrains-rider -y

#region React Native
# http://facebook.github.io/react-native/docs/getting-started.html
# cinst nodejs python2 jdk8 androidstudio -y
# refreshenv
# npm install -g expo-cli react-native-cli
# # For expo, the correct network adapter needs to show up first when running ipconfig; see:
# # https://github.com/react-community/create-react-native-app/issues/60#issuecomment-287081523
#endregion

# cinst pgadmin4 -y
# cinst crashplanpro -y
# cinst octave -y
# cinst virtualbox -y
# cinst shotcut -y

#region ruby
# cinst ruby -version 2.2.4 -y # this is the max version that works with nokogiri
# cinst ruby2.devkit -y
# cmd /c gem install bundler -v 1.12.5 # this is the max version vagrant works with
#endregion

# cinst screenpresso --ignore-checksums -y

#region Snagit
# cinst snagit -y
# mkdir "$($env:LOCALAPPDATA)\TechSmith\Snagit" -Force | Out-Null
# New-Item -Path "$($env:LOCALAPPDATA)\TechSmith\Snagit\Presets2.xml" -ItemType SymbolicLink -Value "~\.deployment\Snagit\Presets2.xml" -Force
#endregion


#region AquaSnap
# reg import "$HOME\.deployment\AquaSnap\AquaSnap.reg"
# cinst aquasnap -y
#endregion
