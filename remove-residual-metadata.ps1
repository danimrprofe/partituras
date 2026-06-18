param()

# Remove remaining metadata blocks with ===== patterns that weren't caught before
# This handles variations like: ARTISTA: ... CANCIÓN: ... + Key: BPM: COMPÁS: NOTAS ADICIONALES:

$count = 0
$totalBlocksRemoved = 0

Get-ChildItem -Path ".\partituras\*.txt", ".\partituras\*.md" -ErrorAction SilentlyContinue | ForEach-Object {
    $filePath = $_.FullName
    $lines = @(Get-Content -Path $filePath)
    $newLines = @()
    $i = 0
    $hasChanges = $false
    
    while ($i -lt $lines.Count) {
        $line = $lines[$i]
        
        # Check for separator line with many equals
        if ($line -match "^={40,}") {
            # Look ahead to see if this is the start of a metadata block
            $nextIdx = $i + 1
            $blockLines = @($line)
            $isMetadataBlock = $false
            
            # Read lines until next separator or end of block
            while ($nextIdx -lt $lines.Count -and $lines[$nextIdx] -notmatch "^={40,}") {
                $blockLines += $lines[$nextIdx]
                
                # Check if contains metadata keywords
                if ($lines[$nextIdx] -match "^(ARTISTA|CANCIÓN|ÁLBUM|Key:|BPM:|COMPÁS:|NOTAS ADICIONALES):") {
                    $isMetadataBlock = $true
                }
                
                $nextIdx++
            }
            
            # If we found a closing separator, add it to block
            if ($nextIdx -lt $lines.Count -and $lines[$nextIdx] -match "^={40,}") {
                $blockLines += $lines[$nextIdx]
                $nextIdx++
            }
            
            # If this is a metadata block, skip it
            if ($isMetadataBlock) {
                Write-Host "Eliminado metadata block de: $($_.Name)"
                $hasChanges = $true
                $totalBlocksRemoved++
                
                # Skip blank lines after the block
                while ($nextIdx -lt $lines.Count -and $lines[$nextIdx] -match "^\s*$") {
                    $nextIdx++
                }
                
                $i = $nextIdx
                continue
            }
        }
        
        $newLines += $line
        $i++
    }
    
    if ($hasChanges) {
        Set-Content -Path $filePath -Value $newLines -Encoding UTF8
        Write-Host "Limpiado: $($_.Name)"
        $count++
    }
}

Write-Host ""
Write-Host "Total de archivos limpiados: $count"
Write-Host "Total de bloques de metadata removidos: $totalBlocksRemoved"
