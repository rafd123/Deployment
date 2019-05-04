$wslApiDllFilePath = Join-Path ([System.Environment]::GetFolderPath('System')) wslapi.dll

Add-Type `
    -TypeDefinition @"
        using System;
        using System.ComponentModel;
        using System.Runtime.InteropServices;

        public static class Wsl
        {
            [DllImport("wslapi.dll", CharSet = CharSet.Ansi)]
            public static extern uint WslLaunchInteractive(
                string distributionName,
                string command,
                bool useCurrentWorkingDirectory,
                out uint exitCode);

            public static uint LaunchInteractive(
                string distributionName,
                string command,
                bool useCurrentWorkingDirectory)
            {
                // command = string.IsNullOrEmpty(command) ? "/bin/bash --login" : command;
                
                // Console.WriteLine(distributionName);
                // Console.WriteLine(command);
                // Console.WriteLine(useCurrentWorkingDirectory);
                // Console.WriteLine(command == null);

                uint exitCode = 0;
                var hresult = WslLaunchInteractive(distributionName, command, useCurrentWorkingDirectory, out exitCode);
                if (hresult != 0)
                {
                    throw new Win32Exception((int)hresult);
                }
                return exitCode;
            }
        }
"@

function Get-WSLDistribution {
    [CmdletBinding(DefaultParameterSetName='All')]
    param (
        [Parameter(ParameterSetName='ByName', Position=0)]
        $Name,

        [Parameter(ParameterSetName='ByDefault')]
        [switch]$Default
    )

    $globbing = $PSCmdlet.ParameterSetName -eq 'All' -or [WildcardPattern]::ContainsWildcardCharacters($Name)

    $defaultDistributionId = Get-ItemProperty `
        -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss `
        -Name DefaultDistribution `
        -ErrorAction SilentlyContinue | Select-Object -ExpandProperty DefaultDistribution

    Get-ChildItem HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss |
        ForEach-Object {
            $key = $_
            [pscustomobject] @{
                Name = Get-ItemPropertyValue -Path $key.PSPath -Name DistributionName
                Id = $key.PSChildName
                Path = Get-ItemPropertyValue -Path $key.PSPath -Name BasePath
                DefaultUid = Get-ItemProperty `
                    -Path $key.PSPath `
                    -Name DefaultUid `
                    -ErrorAction SilentlyContinue | Select-Object -ExpandProperty DefaultUid
                IsDefault = $key.PSChildName -eq $defaultDistributionId
            }
        } |
        Where-Object {
            $disto = $_
            switch ($PSCmdlet.ParameterSetName) {
                'All' { $true }
                'ByDefault' { $disto.IsDefault }
                'ByName' {
                    if ($globbing) {
                        $disto.Name -like $Name
                    } else {
                        $disto.Name -eq $Name                        
                    }                    
                }
            }            
        } |
        ForEach-Object -Begin {
            $found = $globbing
        } -Process {
            $found = $true
            $_
        } -End {
            if (-not $found) {
                switch ($PSCmdlet.ParameterSetName) {
                    'ByDefault' { 
                        Write-Error 'Default distribution not found.'
                     }
                    'ByName' {
                        Write-Error "Distribution '$Name' not found"
                    }
                }
            }
        }
}

function Invoke-WSLDistribution {
    param (
        [Parameter(Position=0, Mandatory=$true)]
        $Name,

        [Parameter(Position=1)]
        $Command = ''
    )

    $distro = Get-WSLDistribution -Name $Name -ErrorAction Stop
    $useCurrentWorkingDirectory = $false
    [Wsl]::LaunchInteractive($distro.Name, $Command, $useCurrentWorkingDirectory) | Out-Null
}

Export-ModuleMember -Function 'Get-WSLDistribution','Invoke-WSLDistribution'