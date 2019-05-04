$editors = @(
    "${env:ProgramFiles(x86)}\PowerGUI\ScriptEditor.exe"
)

foreach($e in $editors)
{
    if([System.IO.File]::Exists($e))
    {
        return $e;
    }
}

return "PowerShell_ISE.exe"