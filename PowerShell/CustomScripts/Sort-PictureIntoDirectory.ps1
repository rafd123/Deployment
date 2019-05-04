function addDateTakenMember {
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        $FileInfo
    )

    begin {
        add-type -AssemblyName System.Drawing
    }

    process {
        $dateTaken = $null   
        $fileStream = $null
        $image = $null

        try
        {
            $fileStream = new-object System.IO.FileStream $FileInfo.FullName, "Open", "Read"
            $image = [System.Drawing.Image]::FromStream($fileStream, $false, $false)
            $dateTakenString = [System.Text.Encoding]::UTF8.GetString($image.GetPropertyItem(36867).Value)
            $dateTakenString = ($dateTakenString -split " ")[0]
            $dateTakenString = $dateTakenString -replace ":","-"
            $dateTaken = [datetime]$dateTakenString    
        } catch {
        } finally {
            if ($null -ne $image) {
                $image.Dispose()
                $image = $null        
            }

            if ($null -ne $fileStream) {
                $fileStream.Dispose()
                $fileStream = $null
            }
        }

        if (-not $dateTaken) {
            if ($FileInfo.Name -match '^wp_(?<timestamp>\d\d\d\d\d\d\d\d_\d\d\d\d\d\dZ)\.mp4$') {
                $dateTakenString = $Matches['timestamp']
                $dateTaken = [datetime]::ParseExact($dateTakenString, 'yyyyMMdd_HHmmssZ', [System.Globalization.CultureInfo]::InvariantCulture, 'AssumeUniversal')
            } elseif ($FileInfo.Name -match '^wp_(?<timestamp>\d\d\d\d\d\d\d\d_\d\d_\d\d_\d\d).*?\.mp4$') {
                $dateTakenString = $Matches['timestamp']
                $dateTaken = [datetime]::ParseExact($dateTakenString, 'yyyyMMdd_HH_mm_ss', [System.Globalization.CultureInfo]::InvariantCulture, 'AssumeUniversal')
            } elseif ($FileInfo.Name -match '^(?<timestamp>\d\d\d\d\d\d\d\d_\d\d\d\d\d\d)\d\d\d_iOS\..*?$') {
                $dateTakenString = $Matches['timestamp']
                $dateTaken = [datetime]::ParseExact($dateTakenString, 'yyyyMMdd_HHmmss', [System.Globalization.CultureInfo]::InvariantCulture, 'AssumeUniversal')
            }
        }
        
        Add-Member -InputObject $FileInfo -MemberType NoteProperty -Name DateTaken -Value $dateTaken -PassThru
    }
}

dir |
    Where-Object { -not $_.PSIsContainer } |
    addDateTakenMember |
    foreach {
        if (-not ($_.DateTaken)) {
            Write-Warning "DateTaken was not found for $($_.Name)"
            return
        }

        $date = $_.DateTaken

        $destDir = "$($date.Year)-$($date.Month.ToString('D2'))-$($date.Day.ToString('D2'))"
        if (-not (Test-Path $destDir -PathType "Container")) {
            Write-Host "Creating directory: $destDir"
            mkdir $destDir | Out-Null
        }
        
        $destPath = Join-Path $destDir $_.Name
        
        Write-Host "Moving $($_.Name) to $destPath"
        move $_ $destPath
    }