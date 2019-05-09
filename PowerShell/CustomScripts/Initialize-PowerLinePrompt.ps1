# if ($env:VSCODE_PID) {
#   return
# }

Import-Module PowerLine

$global:PowerLinePromptConfig = New-Object psobject -Property @{
  FullColor = $true
  DefaulLightBackground = '#AAAAAA'
  DefaulDarkBackground = '#444444'
  Git = New-Object psobject -Property @{
    HideZero = $True
    Branch = New-Object psobject -Property (@{
      Background = '#555577'
      Foreground = 'Gray'
      Object = "&Branch; "
    })
    Identical = New-Object psobject -Property (@{
      Background = '#555577'
      Foreground = 'Gray'
      Object = '&#x2261;' # ≡
    })
    BehindBy = New-Object psobject -Property (@{
      Background = '#EE0000'
      Foreground = 'Gray'
      Object = '&#x2193;' # ↓
    })
    UnstagedChanges = New-Object psobject -Property (@{
      Background = '#990000'
      Foreground = 'Gray'
    })
    StagedChanges = New-Object psobject -Property (@{
      Background = 'Yellow'
      Foreground = 'Black'
    })
    AheadBy = New-Object psobject -Property (@{
      Background = '#00EE00'
      Foreground = 'Black'
      Object = '&#x2191;' # ↑
    })
  }
}

if ($env:TERM_PROGRAM -eq 'Hyper' -or $env:SESSIONNAME -ne 'Console') {
  $PowerLinePromptConfig.FullColor = $false
  $PowerLinePromptConfig.DefaulLightBackground = 'Gray'
  $PowerLinePromptConfig.DefaulDarkBackground = 'DarkGray'
  $PowerLinePromptConfig.Git.Branch.Background = 'DarkMagenta'
  $PowerLinePromptConfig.Git.Identical.Background = 'DarkMagenta'
  $PowerLinePromptConfig.Git.BehindBy.Background = 'Red'
  $PowerLinePromptConfig.Git.AheadBy.Background = 'DarkGreen'
  $PowerLinePromptConfig.Git.UnstagedChanges.Background = 'DarkRed'
}

function global:Write-PowerLineGitStatus {
    [CmdletBinding()]
    param ()
    end {
        $gitStatus = Get-GitStatus

        if($gitStatus -and $PowerLinePromptConfig.Git) {
            $PowerLinePromptConfig.Git.Branch | New-PowerLineBlock ("$($PowerLinePromptConfig.Git.Branch.Object)" + $gitStatus.Branch)

            if ($gitStatus.Upstream) {
              if ($gitStatus.AheadBy -eq 0 -and $gitStatus.BehindBy -eq 0) {
                $PowerLinePromptConfig.Git.Identical | New-PowerLineBlock ("$($PowerLinePromptConfig.Git.Identical.Object)")
              } else {
                if($gitStatus.AheadBy -gt 0) {
                    $PowerLinePromptConfig.Git.AheadBy | New-PowerLineBlock ("$($PowerLinePromptConfig.Git.AheadBy.Object)" + $gitStatus.AheadBy)
                }

                if($gitStatus.BehindBy -gt 0) {
                    $PowerLinePromptConfig.Git.BehindBy | New-PowerLineBlock ("$($PowerLinePromptConfig.Git.BehindBy.Object)" + $gitStatus.BehindBy)
                }
              }
            }

            $StagedChanges = $gitStatus.Index
            $UnStagedChanges = $gitStatus.Working

            if(0 -ne $StagedChanges.Length) {
                $PowerLinePromptConfig.Git.StagedChanges | New-PowerLineBlock $($(
                    $count = $StagedChanges.Added.Length
                    if(0 -lt $count -or !$PowerLinePromptConfig.Git.HideZero) { "+$count" }

                    $count = $StagedChanges.Modified.Length
                    if(0 -lt $count -or !$PowerLinePromptConfig.Git.HideZero) { "&#x270E;$count" } # ✎

                    $count = $StagedChanges.Deleted.Length
                    if(0 -lt $count -or !$PowerLinePromptConfig.Git.HideZero) { "-$count" }

                    $count = $StagedChanges.Unmerged.Length
                    if(0 -lt $count -or !$PowerLinePromptConfig.Git.HideZero) { "&#x2694;$count" } # ⚔
                ) -join " ")
            }

            if(0 -ne $UnStagedChanges.Length) {
                $PowerLinePromptConfig.Git.UnStagedChanges | New-PowerLineBlock $($(
                  $count = $UnStagedChanges.Added.Length
                  if(0 -lt $count -or !$PowerLinePromptConfig.Git.HideZero) { "+$count" }

                  $count = $UnStagedChanges.Modified.Length
                  if(0 -lt $count -or !$PowerLinePromptConfig.Git.HideZero) { "&#x270E;$count" } # ✎

                  $count = $UnStagedChanges.Deleted.Length
                  if(0 -lt $count -or !$PowerLinePromptConfig.Git.HideZero) { "-$count" }

                  $count = $UnStagedChanges.Unmerged.Length
                  if(0 -lt $count -or !$PowerLinePromptConfig.Git.HideZero) { "&#x2694;$count" } # ⚔
                ) -join " ")
            }
        }
    }
}

function global:pad {
  process { $_.Object = " $($_.Object) "; $_ }
}

$env:VIRTUAL_ENV_DISABLE_PROMPT=1

$global:Prompt = @(
    { "`n" + (New-PromptText " $($MyInvocation.HistoryId) " -BackgroundColor $PowerLinePromptConfig.DefaulLightBackground) }
    { Get-SegmentedPath -BackgroundColor $PowerLinePromptConfig.DefaulDarkBackground | pad }
    { Write-PowerLineGitStatus | pad }
    { "`n" }
    { New-PromptText " PS " -ForegroundColor 'Black' -BackgroundColor (& { if (Test-Elevation) { "Red" } else { 'DarkGray' } }) }
    {
      if (-not ($env:VIRTUAL_ENV)) {
        return
      }

      $venv = Split-Path $env:VIRTUAL_ENV -Leaf

      New-PromptText " &#x2622; $venv &#x2622; " -BackgroundColor 'Yellow' -ForegroundColor 'Black'
    }
)

$colors = [System.Collections.Generic.List[PoshCode.Pansies.RgbColor]]::new()
$colors.Add([PoshCode.Pansies.RgbColor]$PowerLinePromptConfig.DefaulLightBackground)
$colors.Add([PoshCode.Pansies.RgbColor]$PowerLinePromptConfig.DefaulDarkBackground)

Set-PowerLinePrompt -FullColor:$PowerLinePromptConfig.FullColor -PowerLineFont -RestoreVirtualTerminal -Colors $colors
