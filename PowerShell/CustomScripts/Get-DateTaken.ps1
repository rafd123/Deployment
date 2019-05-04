param (
    [Parameter(ValueFromPipeline = $true)]
    $FileInfo
)

begin {
    Add-Type -AssemblyName System.Drawing
}

process {
    $dateTaken = $null   
    $image = [System.Drawing.Image]::FromFile($FileInfo.FullName)
    
    try {
        $dateTakenString = [System.Text.Encoding]::UTF8.GetString($image.GetPropertyItem(306).Value)
        $dateTakenString = ($dateTakenString -split " ")[0]
        $dateTakenString = $dateTakenString -replace ":","-"
        $dateTaken = [datetime]$dateTakenString    
    } catch {
    }
    
    Add-Member -InputObject $FileInfo -MemberType NoteProperty -Name DateTaken -Value $dateTaken -PassThru
}