param([string]$LocationHint)

if("" -eq $LocationHint)
{
  Set-Location ..
  return
}

$item = (Get-Item .).Parent
while($item -ne $null)
{
    if($item.Name -like "$LocationHint*")
    {
        Push-Location $item.FullName    
        break
    }

    $item = $item.Parent
}