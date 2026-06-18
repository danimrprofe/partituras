# Script para encontrar archivos con poco contenido
$path = './partituras'
$files = Get-ChildItem -Path $path -Filter '*.txt' -File

$results = @()

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if ($null -eq $content) { continue }
    
    $lines = ($content -split '\n').Count
    $nonEmptyLines = ($content -split '\n' | Where-Object { $_.Trim() -ne '' }).Count
    $fileSize = $content.Length
    
    # Archivos con menos de 300 caracteres o menos de 15 líneas no vacías
    if ($fileSize -lt 300 -or $nonEmptyLines -lt 15) {
        $results += [PSCustomObject]@{
            Archivo = $file.Name
            Tamaño = "{0:N0}" -f $fileSize
            Líneas = $lines
            Contenido = $nonEmptyLines
        }
    }
}

if ($results.Count -gt 0) {
    Write-Host "Encontrados $($results.Count) archivos con poco contenido:`n" -ForegroundColor Yellow
    $results | Sort-Object -Property @{Expression={[int]($_.Tamaño -replace ',','')}; Ascending=$true} | Format-Table -AutoSize
} else {
    Write-Host "No se encontraron archivos con poco contenido" -ForegroundColor Green
}
