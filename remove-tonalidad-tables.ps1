# Remove table blocks with Tonalidad | Afinación | Compás | Capo headers

$count = 0

Get-ChildItem -Path ".\partituras\*.txt", ".\partituras\*.md" -ErrorAction SilentlyContinue | ForEach-Object {
    $filePath = $_.FullName
    $lines = @(Get-Content -Path $filePath)
    $newLines = @()
    $i = 0
    $hasChanges = $false
    
    while ($i -lt $lines.Count) {
        $line = $lines[$i]
        
        # Look for the header line with Tonalidad | Afinación | Compás | Capo
        if ($line -match "^\|\s*Tonalidad\s*\|.*Afinación.*\|.*Compás.*\|.*Capo") {
            # This is the start of the table block - skip it and the next lines
            $i++ # Skip header line
            
            # Skip the separator line
            if ($i -lt $lines.Count -and $lines[$i] -match "^\|\s*-+\s*\|") {
                $i++
            }
            
            # Skip data rows (lines that start with |)
            while ($i -lt $lines.Count -and $lines[$i] -match "^\|") {
                $i++
            }
            
            # Skip empty lines that follow
            while ($i -lt $lines.Count -and $lines[$i] -match "^\s*$") {
                $i++
            }
            
            $hasChanges = $true
            continue
        }
        
        $newLines += $line
        $i++
    }
    
    if ($hasChanges) {
        Set-Content -Path $filePath -Value $newLines -Encoding UTF8
        Write-Output "✓ $($_.Name) - Tabla removida"
        $count++
    }
}

Write-Output "`nTotal de archivos modificados: $count"
