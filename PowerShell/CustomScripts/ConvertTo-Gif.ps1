param (
  [Parameter(Mandatory = $true, Position = 0)]
  [string]$Path
)

$destination = Join-Path (Split-Path $Path) ([System.IO.Path]::GetFileNameWithoutExtension($Path) + '.gif')

ffmpeg -i "$Path" -filter_complex "[0:v] split [a][b];[a] palettegen=stats_mode=single [p];[b][p] paletteuse=new=1" "$destination"

Get-ChildItem $destination
