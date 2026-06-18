# Convert Eb tuning to "Tuning: Half-step down"

$count = 0
$songs = @()

Get-ChildItem -Path ".\partituras\*.txt", ".\partituras\*.md" -ErrorAction SilentlyContinue | ForEach-Object {
    $filePath = $_.FullName
    $content = Get-Content -Path $filePath -Raw
    
    # Check for Eb Ab Db Gb Bb Eb tuning (half-step down)
    if ($content -match "Afinación:\s*Eb\s+Ab\s+Db\s+Gb\s+Bb\s+Eb") {
        $newContent = $content -replace "Afinación:\s*Eb\s+Ab\s+Db\s+Gb\s+Bb\s+Eb", "Tuning: Half-step down"
        Set-Content -Path $filePath -Value $newContent -Encoding UTF8
        
        # Extract song name from filename
        $songName = $_.BaseName
        $songs += $songName
        
        Write-Output "✓ $($_.Name) - Clasificada como Half-step down"
        $count++
    }
}

Write-Output "`nTotal de canciones con Eb tuning: $count"
Write-Output "`nCanciones clasificadas:`n"
$songs | ForEach-Object { Write-Output "- $_" }
