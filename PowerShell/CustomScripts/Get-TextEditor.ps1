$texteditors = @(
    "$($env:LOCALAPPDATA)\Programs\Microsoft VS Code\bin\code.cmd"
    "$($env:programfiles)\Microsoft VS Code\bin\code.cmd"
    "${env:ProgramFiles(x86)}\Microsoft VS Code\bin\code.cmd"
    "$($env:programfiles)\Sublime Text 3\sublime_text.exe"
    "$($env:programfiles)\Notepad++\notepad++.exe"
    "${env:ProgramFiles(x86)}\Notepad++\notepad++.exe"
    "$($env:programfiles)\TextPad 5\TextPad.exe"
    "${env:ProgramFiles(x86)}\TextPad 5\TextPad.exe",
    "${env:ProgramFiles}\Notepad2\notepad2.exe",
    "${env:ProgramFiles(x86)}\Notepad2\notepad2.exe"
)

foreach ($te in $texteditors) {
    if([System.IO.File]::Exists($te)) {
        $te;
        return;
    }
}

"notepad.exe"
