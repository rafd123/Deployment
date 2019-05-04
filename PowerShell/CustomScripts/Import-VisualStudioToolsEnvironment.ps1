param (
    $Version = '12',
    $Platform = 'x86'
)

$ErrorActionPreference = 'Stop'

$vsCommonToolsDirectoryPath = dir "env:VS$($Version)0COMNTOOLS" | Select-Object -ExpandProperty Value
$vcVarsAllFilePath = (Resolve-Path (Join-Path $vsCommonToolsDirectoryPath '..\..\VC\vcvarsall.bat')).Path

cmd /c " `"$vcVarsAllFilePath`" $Platform && set" | ForEach-Object {
    if ($_ -match "^(.*?)=(.*)$")  
    { 
        Set-Content "env:\$($matches[1])" $matches[2]  
    }
}