function Write-NetScopeFrame {
    param(
        [string[]]$Lines
    )

    [Console]::SetCursorPosition(0,0)

    $Text = $Lines -join [Environment]::NewLine

    Write-Host $Text -NoNewline

    # Fill the rest of the window so old text disappears
    $Remaining = [Console]::WindowHeight - $Lines.Count

    for ($i = 0; $i -lt $Remaining; $i++) {
        Write-Host (" " * [Console]::WindowWidth)
    }
}