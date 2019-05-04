param (
    $Command
)

process {
    $_
}

end {
    try {
        if ($Command) {
            . $Command
        }
    } finally {
        Show-BalloonTip "Command Complete! `n$Command"
    }
}
