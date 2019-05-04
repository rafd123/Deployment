param (
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    $InputObject,

    [Parameter(Mandatory = $true, Position = 0)]
    $Count
)

begin {
    $counter = [pscustomobject] @{ Value = 0 }
    $objects = @()
}

process {
    $objects += $InputObject
}

end {
    $size = [math]::Ceiling($objects.Count / $Count)    
    $objects | Group-Object -Property { [math]::Floor($counter.Value++ / $size) }
}
