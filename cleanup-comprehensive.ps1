param()

# Comprehensive cleanup script for partitura files
# - Remove metadata blocks (====...====)
# - Normalize section names (INTRO:, REPITE ESTRIBILLO, INTERLUDIO→INSTRUMENTAL, etc.)
# - Separate section names from chords (different lines)
# - Remove triple backticks and markdown titles
# - Remove duplicate metadata lines (Sin capo, etc.)

$count = 0
$sectionsNormalized = 0
$blocksRemoved = 0

Get-ChildItem -Path ".\partituras\*.txt", ".\partituras\*.md" -ErrorAction SilentlyContinue | ForEach-Object {
    $filePath = $_.FullName
    $lines = @(Get-Content -Path $filePath)
    $newLines = @()
    $i = 0
    $hasChanges = $false
    $capoLineFound = $false
    
    while ($i -lt $lines.Count) {
        $line = $lines[$i]
        
        # 1. Skip metadata blocks (between ====...)
        if ($line -match "^={40,}") {
            # Find the closing ====
            $blockStart = $i
            $i++
            while ($i -lt $lines.Count -and $lines[$i] -notmatch "^={40,}") {
                $i++
            }
            # Skip the closing ==== line
            if ($i -lt $lines.Count) {
                $i++
            }
            # Skip blank lines after block
            while ($i -lt $lines.Count -and $lines[$i] -match "^\s*$") {
                $i++
            }
            $hasChanges = $true
            $blocksRemoved++
            continue
        }
        
        # 2. Remove triple backticks
        if ($line -match "^```+\s*$") {
            $hasChanges = $true
            $i++
            continue
        }
        
        # 3. Remove markdown titles (#)
        if ($line -match "^#\s+") {
            $hasChanges = $true
            $i++
            continue
        }
        
        # 4. Remove duplicate "Sin capo" or "Capo X" lines (keep only first CEJILLA/CAPO)
        if ($line -match "^(Sin\s+capo|Capo\s+[0-9])" -and $capoLineFound) {
            $hasChanges = $true
            $i++
            continue
        }
        
        if ($line -match "^CEJILLA/CAPO:") {
            $capoLineFound = $true
            $newLines += $line
            $i++
            continue
        }
        
        # 5. Normalize section names - handle variations with colons and attached acordes
        if ($line -match "^(INTRO|ESTROFA|VERSO|ESTRIBILLO|CHORUS|PUENTE|BRIDGE|SOLO|INTERLUDIO|INTERMEDIO|INSTRUMENTAL|FINAL|OUTRO|REPITE)") {
            
            # Handle "REPITE ESTRIBILLO" → "ESTRIBILLO"
            if ($line -match "^REPITE\s+") {
                $line = $line -replace "^REPITE\s+", ""
            }
            
            # Handle "INTERLUDIO" → "INSTRUMENTAL"
            if ($line -match "^INTERLUDIO") {
                $line = $line -replace "^INTERLUDIO", "INSTRUMENTAL"
            }
            
            # Handle "INTERMEDIO" → "INSTRUMENTAL"
            if ($line -match "^INTERMEDIO") {
                $line = $line -replace "^INTERMEDIO", "INSTRUMENTAL"
            }
            
            # Handle section names with colons: "INTRO:" → "INTRO"
            if ($line -match "^(\w+):\s*(.+)$") {
                $sectionName = $matches[1]
                $restOfLine = $matches[2].Trim()
                
                # If there are chords after the colon, separate them
                if ($restOfLine -and $restOfLine -notmatch "^[a-z]") {
                    $newLines += $sectionName
                    $newLines += $restOfLine
                    $hasChanges = $true
                    $sectionsNormalized++
                    $i++
                    continue
                }
                else {
                    # Just a label, remove colon
                    $line = $sectionName
                }
            }
            
            # Handle "Solo:" or "SOLO:" format - separate from chords
            if ($line -match "^(SOLO):\s*(.+)$") {
                $sectionName = $matches[1]
                $restOfLine = $matches[2].Trim()
                if ($restOfLine) {
                    $newLines += $sectionName
                    $newLines += $restOfLine
                    $hasChanges = $true
                    $sectionsNormalized++
                    $i++
                    continue
                }
            }
            
            # Remove trailing colons
            $line = $line -replace ":$", ""
        }
        
        $newLines += $line
        $i++
    }
    
    if ($hasChanges) {
        Set-Content -Path $filePath -Value $newLines -Encoding UTF8
        Write-Output "Limpiada: $($_.Name)"
        $count++
    }
}

Write-Output ""
Write-Output "==== RESUMEN DE LIMPIEZA ===="
Write-Output "Total de archivos procesados: $count"
Write-Output "Bloques de metadata removidos: $blocksRemoved"
Write-Output "Secciones normalizadas: $sectionsNormalized"
