# Remove duplicate CEJILLA/CAPO lines, keeping only the first one

$count = 0
$totalRemoved = 0

Get-ChildItem -Path ".\partituras\*.txt", ".\partituras\*.md" -ErrorAction SilentlyContinue | ForEach-Object {
    $filePath = $_.FullName
    $lines = @(Get-Content -Path $filePath)
    $newLines = @()
    $firstCapoFound = $false
    
    foreach ($line in $lines) {
        # Check if line is a CEJILLA/CAPO line
        if ($line -match "^CEJILLA|^Capo |^CAPO ") {
            # If this is the first capo line, keep it
            if (-not $firstCapoFound) {
                $newLines += $line
                $firstCapoFound = $true
            }
            # else skip (duplicate)
            else {
                $totalRemoved++
            }
        }
        else {
            $newLines += $line
        }
    }
    
    # Only write if changes were made
    if ($newLines.Count -lt $lines.Count) {
        Set-Content -Path $filePath -Value $newLines -Encoding UTF8
        Write-Output "Limpiado: $($_.Name)"
        $count++
    }
}

Write-Output ""
Write-Output "Total de archivos limpiados: $count"
Write-Output "Total de lineas de capo duplicadas removidas: $totalRemoved"
