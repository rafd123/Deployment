#requires -Version 2 -Modules posh-git

function Write-Theme {

    param(
        [bool]
        $lastCommandFailed,
        [string]
        $with
    )

    $prompt += Set-Newline

    $lastColor = [ConsoleColor]::DarkGray

    $prompt += Write-Prompt -Object " $($MyInvocation.HistoryId) " -ForegroundColor ([ConsoleColor]::DarkGray) -BackgroundColor ([ConsoleColor]::Gray)
    $prompt += Write-Prompt -Object $sl.PromptSymbols.SegmentForwardSymbol -ForegroundColor ([ConsoleColor]::Gray) -BackgroundColor $lastColor


    # Writes the drive portion
    $path = (Get-FullPath -dir $pwd).Replace('\', ' ' + [char]::ConvertFromUtf32(0xE0B1) + ' ') + ' '
    $prompt += Write-Prompt -Object " $path" -ForegroundColor $sl.Colors.PromptForegroundColor -BackgroundColor $lastColor

    $gitStatus = Get-GitStatus
    if ($gitStatus) {
        $prompt += Write-Prompt -Object $sl.PromptSymbols.SegmentForwardSymbol -ForegroundColor $lastColor -BackgroundColor $sl.Git.Branch.Background
        $lastColor = $sl.Git.Branch.Background
        $prompt += Write-Prompt -Object " $($sl.Git.Branch.Object) $($gitStatus.Branch) " -ForegroundColor $sl.Git.Branch.Foreground -BackgroundColor $lastColor

        if ($gitStatus.Upstream) {
            if ($gitStatus.AheadBy -eq 0 -and $gitStatus.BehindBy -eq 0) {
                $prompt += Write-Prompt -Object "$([char]::ConvertFromUtf32(0xE0B1)) $($sl.Git.Identical.Object) " -ForegroundColor $sl.Git.Branch.Foreground -BackgroundColor $lastColor
            }
            else {
                if ($gitStatus.AheadBy -gt 0) {
                    $prompt += Write-Prompt -Object $sl.PromptSymbols.SegmentForwardSymbol -ForegroundColor $lastColor -BackgroundColor $sl.Git.AheadBy.Background
                    $lastColor = $sl.Git.AheadBy.Background
                    $prompt += Write-Prompt " $($sl.Git.AheadBy.Object)$($gitStatus.AheadBy) " -ForegroundColor $sl.Git.AheadBy.Foreground -BackgroundColor $lastColor
                }

                if ($gitStatus.BehindBy -gt 0) {
                    $prompt += Write-Prompt -Object $sl.PromptSymbols.SegmentForwardSymbol -ForegroundColor $lastColor -BackgroundColor $sl.Git.BehindBy.Background
                    $lastColor = $sl.Git.BehindBy.Background
                    $prompt += Write-Prompt " $($sl.Git.BehindBy.Object)$($gitStatus.BehindBy) " -ForegroundColor $sl.Git.BehindBy.Foreground -BackgroundColor $lastColor
                }
            }
        }

        $StagedChanges = $gitStatus.Index
        $UnStagedChanges = $gitStatus.Working

        if (0 -ne $StagedChanges.Length) {
            $prompt += Write-Prompt -Object $sl.PromptSymbols.SegmentForwardSymbol -ForegroundColor $lastColor -BackgroundColor $sl.Git.StagedChanges.Background
            $lastColor = $sl.Git.StagedChanges.Background

            $prompt += Write-Prompt -ForegroundColor $sl.Git.StagedChanges.Foreground -BackgroundColor $lastColor (' ' + $($(
                $count = $StagedChanges.Added.Length
                if (0 -lt $count -or !$sl.Git.HideZero) { "+$count" }

                $count = $StagedChanges.Modified.Length
                if (0 -lt $count -or !$sl.Git.HideZero) { "$([char]::ConvertFromUtf32(0x270E))$count" } # ✎

                $count = $StagedChanges.Deleted.Length
                if (0 -lt $count -or !$sl.Git.HideZero) { "-$count" }

                $count = $StagedChanges.Unmerged.Length
                if (0 -lt $count -or !$sl.Git.HideZero) { "$([char]::ConvertFromUtf32(0x2694))$count" } # ⚔
            ) -join " ") + ' ')
        }

        if (0 -ne $UnStagedChanges.Length) {
            $prompt += Write-Prompt -Object $sl.PromptSymbols.SegmentForwardSymbol -ForegroundColor $lastColor -BackgroundColor $sl.Git.UnstagedChanges.Background
            $lastColor = $sl.Git.UnstagedChanges.Background

            $prompt += Write-Prompt -ForegroundColor $sl.Git.UnstagedChanges.Foreground -BackgroundColor $lastColor (' ' + $($(
                $count = $UnStagedChanges.Added.Length
                if (0 -lt $count -or !$sl.Git.HideZero) { "+$count" }

                $count = $UnStagedChanges.Modified.Length
                if (0 -lt $count -or !$sl.Git.HideZero) { "$([char]::ConvertFromUtf32(0x270E))$count" } # ✎

                $count = $UnStagedChanges.Deleted.Length
                if (0 -lt $count -or !$sl.Git.HideZero) { "-$count" }

                $count = $UnStagedChanges.Unmerged.Length
                if (0 -lt $count -or !$sl.Git.HideZero) { "$([char]::ConvertFromUtf32(0x2694))$count" } # ⚔
            ) -join " ") + ' ')
        }
    }

    if ($with) {
        $prompt += Write-Prompt -Object $sl.PromptSymbols.SegmentForwardSymbol -ForegroundColor $lastColor -BackgroundColor $sl.Colors.WithBackgroundColor
        $prompt += Write-Prompt -Object " $($with.ToUpper()) " -BackgroundColor $sl.Colors.WithBackgroundColor -ForegroundColor $sl.Colors.WithForegroundColor
        $lastColor = $sl.Colors.WithBackgroundColor
    }

    # Writes the postfix to the prompt
    $prompt += Write-Prompt -Object $sl.PromptSymbols.SegmentForwardSymbol -ForegroundColor $lastColor
    $prompt += Set-Newline

    If (Test-Administrator) {
        $prompt += Write-Prompt -Object " $($sl.PromptSymbols.ElevatedSymbol)" -ForegroundColor $sl.Colors.AdminIconForegroundColor -BackgroundColor $sl.Colors.SessionInfoBackgroundColor
    }

    If ($lastCommandFailed) {
        $prompt += Write-Prompt -Object " $($sl.PromptSymbols.FailedCommandSymbol)" -ForegroundColor $sl.Colors.CommandFailedIconForegroundColor -BackgroundColor $sl.Colors.SessionInfoBackgroundColor
    }

    $prompt += Write-Prompt -Object " PS " -BackgroundColor ([ConsoleColor]::DarkGray)
    $prompt += Write-Prompt -Object $sl.PromptSymbols.SegmentForwardSymbol -ForegroundColor ([ConsoleColor]::DarkGray)
    $prompt
}

$sl = $global:ThemeSettings #local settings
$sl.PromptSymbols.SegmentForwardSymbol = [char]::ConvertFromUtf32(0xE0B0)
$sl.Colors.AdminIconForegroundColor = [ConsoleColor]::Yellow
$sl.Colors.SessionInfoBackgroundColor = [ConsoleColor]::DarkGray
$sl.Colors.PromptForegroundColor = [ConsoleColor]::White
$sl.Colors.PromptSymbolColor = [ConsoleColor]::White
$sl.Colors.PromptHighlightColor = [ConsoleColor]::DarkBlue
$sl.Colors.GitForegroundColor = [ConsoleColor]::DarkGray
$sl.Colors.WithForegroundColor = [ConsoleColor]::White
$sl.Colors.WithBackgroundColor = [ConsoleColor]::DarkRed
$sl.Colors.VirtualEnvBackgroundColor = [System.ConsoleColor]::Red
$sl.Colors.VirtualEnvForegroundColor = [System.ConsoleColor]::White
$sl | Add-Member -MemberType NoteProperty -Name Git -Value (New-Object psobject -Property @{
    HideZero = $True
    Branch = New-Object psobject -Property (@{
        Background = [ConsoleColor]::DarkMagenta
        Foreground = [ConsoleColor]::Gray
        Object     = [char]::ConvertFromUtf32(0xE0A0)
    })
    Identical = New-Object psobject -Property (@{
        Background = [ConsoleColor]::DarkMagenta
        Foreground = [ConsoleColor]::Gray
        Object     = [char]::ConvertFromUtf32(0x2261) # ≡
    })
    BehindBy = New-Object psobject -Property (@{
        Background = [ConsoleColor]::Red
        Foreground = [ConsoleColor]::Gray
        Object     = [char]::ConvertFromUtf32(0x2193) # ↓
    })
    UnstagedChanges = New-Object psobject -Property (@{
        Background = [ConsoleColor]::DarkRed
        Foreground = [ConsoleColor]::Gray
    })
    StagedChanges = New-Object psobject -Property (@{
        Background = [ConsoleColor]::Yellow
        Foreground = [ConsoleColor]::Black
    })
    AheadBy = New-Object psobject -Property (@{
        Background = [ConsoleColor]::DarkGreen
        Foreground = [ConsoleColor]::Black
        Object     = [char]::ConvertFromUtf32(0x2191) # ↑
    })
})
