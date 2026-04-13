# Script para comparar archivos vacíos entre dos carpetas

$emptyFiles = @(
    "m-clan - la-esperanza.txt",
    "m-clan - miedo.txt",
    "m-clan - maggie despierta.txt",
    "m-clan - los periodicos de mañana.txt",
    "m-clan - que esta pasando.txt",
    "m-clan - la calma.txt",
    "m-clan - inmigrante.txt",
    "m-clan - grupos-americanos.txt",
    "m-clan - el tren que nunca cogimos.txt",
    "m-clan - corazon en transito.txt",
    "m-clan - concierto-salvaje.txt",
    "m-clan - chilaba y cachimba.txt",
    "m-clan - caminos secundarios.txt",
    "m-clan - arenas movedizas.txt",
    "m-clan - quedate a dormir.txt",
    "m-clan - roto por dentro.txt",
    "m-clan - souvenir.txt",
    "m-clan - todo lo joven muere hoy.txt",
    "m-clan - traeme tu amor.txt",
    "m-clan - usar y tirar.txt",
    "m-clan - viaje al sur.txt",
    "m-clan - noche de desolacion.txt",
    "m-clan - polvo de estrellas.txt",
    "Countin Crows - Colorblind.txt",
    "Pereza - Si Quieres Bailamos.txt",
    "Pereza - Princesas.txt",
    "Joaquín Sabina - Pájaros De Portugal.txt",
    "Ed Sheeran - photograph.txt",
    "Justin Timberlake - True Colors.txt",
    "Los Piratas - M.txt"
)

$backupPath = "C:\Users\Dani\Desktop\github\partituras\Partituras - copia"
$currentPath = "./partituras"

$conContenido = @()
$sinContenido = @()

foreach ($filename in $emptyFiles) {
    $backupFile = Join-Path $backupPath $filename
    $currentFile = Join-Path $currentPath $filename
    
    $currentSize = 0
    $backupSize = 0
    $backupLines = 0
    
    if (Test-Path $currentFile) {
        $currentContent = Get-Content $currentFile -Raw -ErrorAction SilentlyContinue
        $currentSize = $currentContent.Length
    }
    
    if (Test-Path $backupFile) {
        $backupContent = Get-Content $backupFile -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        $backupSize = $backupContent.Length
        $backupLines = ($backupContent -split '\n').Count
        
        $item = [PSCustomObject]@{
            Archivo = $filename
            TamañoActual = $currentSize
            TamañoBackup = $backupSize
            LíneasBackup = $backupLines
        }
        
        if ($backupSize -gt 150) {
            $conContenido += $item
        } else {
            $sinContenido += $item
        }
    }
}

if ($conContenido.Count -gt 0) {
    Write-Host "✓ Archivos encontrados CON contenido en backup ($($conContenido.Count)):`n" -ForegroundColor Green
    $conContenido | Sort-Object -Property Archivo | Format-Table Archivo, TamañoBackup, LíneasBackup -AutoSize
}

if ($sinContenido.Count -gt 0) {
    Write-Host "`n✗ Archivos encontrados pero SIN contenido ($($sinContenido.Count)):`n" -ForegroundColor Red
    $sinContenido | Sort-Object -Property Archivo | Format-Table Archivo, TamañoBackup -AutoSize
}

Write-Host "`n" -ForegroundColor Cyan
Write-Host "Total con contenido: $($conContenido.Count)" -ForegroundColor Green
Write-Host "Total sin contenido: $($sinContenido.Count)" -ForegroundColor Red
