# Remove lines with "Afinación: Estándar (E A D G B E)"
$count = 0

Get-ChildItem -Path ".\partituras\*.txt", ".\partituras\*.md" -ErrorAction SilentlyContinue | ForEach-Object {
    $filePath = $_.FullName
    $lines = @(Get-Content -Path $filePath)
    $newLines = @()
    
    foreach ($line in $lines) {
        if ($line -match "(?i)afinaci[óo]n.*Est[áa]ndar\s*\(E\s+A\s+D\s+G\s+B\s+E\)") {
            # Skip this line (it matches the pattern to remove)
            continue
        }
        $newLines += $line
    }
    
    # Only write if lines were removed
    if ($newLines.Count -lt $lines.Count) {
        Set-Content -Path $filePath -Value $newLines -Encoding UTF8
        Write-Output "✓ $($_.Name) - Línea eliminada"
        $count++
    }
}

Write-Output "`nTotal de archivos modificados: $count"
