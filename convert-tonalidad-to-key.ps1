# Convert tonalidad information to English notation (C, Cm, D, Dm, etc.)

function Convert-ToEnglishKey {
    param([string]$tonalidad)
    
    $tonalidad = $tonalidad.Trim()
    
    # Remove parentheses and extra info
    if ($tonalidad -match "\(([A-G]#?[m]?)\)") {
        return $matches[1]
    }
    
    # Map Spanish note names to English
    $noteMap = @{
        "Do"  = "C";
        "Re"  = "D";
        "Mi"  = "E";
        "Fa"  = "F";
        "Sol" = "G";
        "La"  = "A";
        "Si"  = "B"
    }
    
    # Detect if it's minor
    $isMinor = $tonalidad -match "(?i)(menor|minor)"
    
    # Extract the note name (handle special cases)
    foreach ($spanishNote in $noteMap.Keys) {
        if ($tonalidad -match "(?i)$spanishNote") {
            $englishNote = $noteMap[$spanishNote]
            
            # Handle sharps/flats
            if ($tonalidad -match "$spanishNote\s*#") {
                $englishNote += "#"
            }
            elseif ($tonalidad -match "$spanishNote\s*b") {
                $englishNote += "b"
            }
            
            # Add minor suffix if needed
            if ($isMinor) {
                $englishNote += "m"
            }
            
            return $englishNote
        }
    }
    
    return ""
}

$count = 0
$converted = 0

Get-ChildItem -Path ".\partituras\*.txt", ".\partituras\*.md" -ErrorAction SilentlyContinue | ForEach-Object {
    $filePath = $_.FullName
    $lines = @(Get-Content -Path $filePath)
    $newLines = @()
    $hasChanges = $false
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        
        # Match TONALIDAD: ... or Tonalidad (Key): ... but skip table headers
        if (($line -match "^TONALIDAD:\s+(.+)$" -or $line -match "^Tonalidad \(Key\):\s+(.+)$") -and $line -notmatch "^\s*\|") {
            $tonalidad = $matches[1]
            
            # Skip lines with just dashes (undefined tonality)
            if ($tonalidad -match "^[—-]+$") {
                $newLines += $line
                continue
            }
            
            $englishKey = Convert-ToEnglishKey -tonalidad $tonalidad
            
            if ($englishKey) {
                $newLines += "Key: $englishKey"
                $hasChanges = $true
                $converted++
            } else {
                $newLines += $line
            }
        }
        else {
            $newLines += $line
        }
    }
    
    if ($hasChanges) {
        Set-Content -Path $filePath -Value $newLines -Encoding UTF8
        Write-Output "✓ $($_.Name) - Tonalidad convertida"
        $count++
    }
}

Write-Output "`nTotal de archivos modificados: $count"
Write-Output "Total de tonalidades convertidas: $converted"
