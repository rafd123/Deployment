param (
    [Parameter(
        ValueFromPipeline=$true, 
        Mandatory=$true, Position= 0)]
    $Xml
)

process {
    if ($Xml -is [xml]) {
        $Xml = $Xml.OuterXml
    }

    Add-Type -AssemblyName System.Xml.Linq
    [System.Xml.Linq.XDocument]::Parse($Xml).ToString()
}