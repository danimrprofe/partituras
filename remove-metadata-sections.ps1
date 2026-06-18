# Remove metadata sections bordered by equals signs
# Pattern: ================================================================================
#          ARTISTA: ...
#          CANCION: ...
#          ALBUM: ...
#          ================================================================================

$count = 0

Get-ChildItem -Path ".\partituras\*.txt", ".\partituras\*.md" -ErrorAction SilentlyContinue | ForEach-Object {
    $filePath = $_.FullName
    $lines = @(Get-Content -Path $filePath)
    $newLines = @()
    $skipBlock = $false
    $blockStart = -1
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        
        # Check if this is the start of a metadata block
        if ($line -match "^={60,}$" -and $blockStart -eq -1) {
            # Check if next lines are ARTISTA, CANCION, ALBUM pattern
            if ($i + 3 -lt $lines.Count) {
                if ($lines[$i + 1] -match "^ARTISTA:" -and 
                    $lines[$i + 2] -match "^CANCION:" -and 
                    $lines[$i + 3] -match "^ALBUM:") {
                    $blockStart = $i
                    $skipBlock = $true
                    continue
                }
            }
        }
        
        # Check if this is the closing equals line of a metadata block
        if ($skipBlock -and $line -match "^={60,}$" -and $blockStart -ne -1) {
            $skipBlock = $false
            $blockStart = -1
            # Skip this line and any blank lines that follow
            $nextIdx = $i + 1
            while ($nextIdx -lt $lines.Count -and $lines[$nextIdx] -match "^\s*$") {
                $nextIdx++
            }
            $i = $nextIdx - 1
            continue
        }
        
        # If not in a skip block, add to new lines
        if (!$skipBlock) {
            $newLines += $line
        }
    }
    
    # Only write if lines were removed
    if ($newLines.Count -lt $lines.Count) {
        Set-Content -Path $filePath -Value $newLines -Encoding UTF8
        Write-Output "✓ $($_.Name) - Sección removida"
        $count++
    }
}

Write-Output "`nTotal de archivos modificados: $count"
