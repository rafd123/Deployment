[CmdletBinding()]param (
    [Parameter(Position = 0)]
    $FilePath = '*'
)

if ($FilePath -and -not (Test-Path $FilePath)) {
    if (-not (Test-Path $FilePath)) {
        '' | Set-Content -Path $FilePath -Encoding Ascii
    }

    $FilePath = Resolve-Path $FilePath
}

if (Test-Path variable:\psISE) {
    psEdit $FilePath
    return
}

if (Test-Path variable:\PGSE) {
    $PGSE.DocumentWindows.Add($FilePath)
    return 
}

$texteditor = Get-TextEditor;
Invoke-Expression "&`"$texteditor`" `"$FilePath`""