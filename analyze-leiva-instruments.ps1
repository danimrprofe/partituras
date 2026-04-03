# Script para analizar instrumentos predominantes de Leiva

$leivaFolder = "c:\Users\Dani\Desktop\github\partituras\partituras"
$leivaFiles = Get-ChildItem $leivaFolder -File -Filter "Leiva*" | Where-Object { $_.Extension -match '\.(txt|md)$' }

$instruments = @{}

foreach ($file in $leivaFiles) {
    $content = Get-Content $file.FullName -Raw
    
    # Extraer songId del nombre (basándose en el patrón usado en el índice)
    $songId = ($file.BaseName `
        -replace '[^\w\s-]', '' `
        -replace '\s+', '-' `
        -replace '^-|-$', '' `
        -replace '-+', '-' `
        -replace 'Leiva-', 'leiva-').ToLowerInvariant()
    
    # Detectar si hay patrones de acordes de guitarra
    # Concordes típicos: Em, Am, Dm, G, D, A, C, etc.
    $guitarChordsPattern = '\b(?:Em|Am|Dm|G|D|A|C|B|E|F|Gm|Bb|Eb)\b'
    $guitarCount = ([regex]::Matches($content, $guitarChordsPattern, "IgnoreCase")).Count
    
    # Detectar si hay patrones de notación de teclado/piano
    $pianoPattern = '(?:Do|Re|Mi|Fa|Sol|La|Si|C[0-9]|D[0-9]|E[0-9])'
    $pianoCount = ([regex]::Matches($content, $pianoPattern, "IgnoreCase")).Count
    
    # Decidir instrumento
    if ($guitarCount -gt 5) {
        $instrument = "guitarra-acustica"
    } elseif ($pianoCount -gt 5) {
        $instrument = "piano"
    } else {
        # Default a guitarra acústica para Leiva
        $instrument = "guitarra-acustica"
    }
    
    $instruments[$songId] = @{
        instruments = @($instrument)
        rating = 0
        tuning = ""
    }
}

# Convertir a JSON y mostrar
$json = $instruments | ConvertTo-Json -Depth 3
Write-Output $json | Out-File -Encoding UTF8 -FilePath "c:\Users\Dani\Desktop\github\partituras\leiva-instruments.json"

Write-Host "Se analizaron $($instruments.Count) canciones de Leiva"
Write-Host "Archivo guardado en: leiva-instruments.json"
