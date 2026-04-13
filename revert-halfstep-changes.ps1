# Revert the tuning change - restore Afinación: Eb Ab Db Gb Bb Eb

$count = 0

Get-ChildItem -Path ".\partituras\*.txt", ".\partituras\*.md" -ErrorAction SilentlyContinue | ForEach-Object {
    $filePath = $_.FullName
    $content = Get-Content -Path $filePath -Raw
    
    # Check for "Tuning: Half-step down" and restore to original
    if ($content -match "Tuning: Half-step down") {
        $newContent = $content -replace "Tuning: Half-step down", "Afinación: `tEb Ab Db Gb Bb Eb"
        Set-Content -Path $filePath -Value $newContent -Encoding UTF8
        
        Write-Output "✓ Revertida: $($_.Name)"
        $count++
    }
}

Write-Output "`nTotal de archivos revertidos: $count"
