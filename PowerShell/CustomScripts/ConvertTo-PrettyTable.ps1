param (
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    $InputObject
)

begin {
    $accum = @()
}

process {
    $accum += $InputObject
}

end {
    $accum |
        ConvertTo-Csv -NoTypeInformation |
        ForEach-Object { $_ -replace '"_+"','' } |
        python -c @'
import sys
from texttable import Texttable
import csv

rows = [ row for row in csv.reader(sys.stdin) ]
table = Texttable(max_width=10000)
table.set_cols_dtype([ 't' for _ in rows[0] ])
table.add_rows(rows)
print(table.draw())
'@
}
