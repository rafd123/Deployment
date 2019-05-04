Get-ChildItem -Directory |
    Where-Object Name -match '(?<year>^\d\d\d\d)-' |
    ForEach-Object {
        if (!(Test-Path $Matches.year)) {
            mkdir $Matches.year
        }
        
        Move-Item -Path $_.FullName -Destination $matches.year
    }
