# Script mejorado para encontrar contenido en backup
$emptyFiles = @(
    "m-clan - la-esperanza",
    "m-clan - miedo",
    "m-clan - maggie despierta",
    "m-clan - los periodicos de mañana",
    "m-clan - que esta pasando",
    "m-clan - la calma",
    "m-clan - inmigrante",
    "m-clan - grupos-americanos",
    "m-clan - el tren que nunca cogimos",
    "m-clan - corazon en transito",
    "m-clan - concierto-salvaje",
    "m-clan - chilaba y cachimba",
    "m-clan - caminos secundarios",
    "m-clan - arenas movedizas",
    "m-clan - quedate a dormir",
    "m-clan - roto por dentro",
    "m-clan - souvenir",
    "m-clan - todo lo joven muere hoy",
    "m-clan - traeme tu amor",
    "m-clan - usar y tirar",
    "m-clan - viaje al sur",
    "m-clan - noche de desolacion",
    "m-clan - polvo de estrellas",
    "Countin Crows - Colorblind",
    "Pereza - Si Quieres Bailamos",
    "Pereza - Princesas",
    "Joaquín Sabina - Pájaros De Portugal",
    "Ed Sheeran - photograph",
    "Justin Timberlake - True Colors",
    "Los Piratas - M",
    "Desconocido - CON LAS GANAS"
)

$backupPath = "C:\Users\Dani\Desktop\github\partituras\Partituras - copia"
$backupFiles = Get-ChildItem $backupPath -File | Select-Object Name, FullName, @{Name="Tamaño"; Expression={$_.Length}}

$conContenido = @()
$sinContenido = @()
$noEncontrado = @()

foreach ($searchTerm in $emptyFiles) {
    $found = $backupFiles | Where-Object { $_.Name -match [regex]::Escape($searchTerm) }
    
    if ($found) {
        # Si encuentra una coincidencia
        if ($found.Tamaño -gt 150) {
            $conContenido += [PSCustomObject]@{
                Archivo = $found.Name
                Tamaño = $found.Tamaño
                Ruta = $found.FullName
            }
        } else {
            $sinContenido += [PSCustomObject]@{
                Archivo = $found.Name
                Tamaño = $found.Tamaño
            }
        }
    } else {
        $noEncontrado += $searchTerm
    }
}

if ($conContenido.Count -gt 0) {
    Write-Host "✓ ARCHIVOS CON CONTENIDO EN BACKUP ($($conContenido.Count)):`n" -ForegroundColor Green
    $conContenido | Sort-Object -Property Archivo | Format-Table Archivo, Tamaño -AutoSize
}

if ($sinContenido.Count -gt 0) {
    Write-Host "`n✗ Archivos vacíos EN BACKUP ($($sinContenido.Count)):`n" -ForegroundColor Red
    $sinContenido | Sort-Object -Property Archivo | Format-Table Archivo, Tamaño -AutoSize
}

if ($noEncontrado.Count -gt 0) {
    Write-Host "`n? NO ENCONTRADOS EN BACKUP ($($noEncontrado.Count)):`n" -ForegroundColor Yellow
    $noEncontrado | ForEach-Object { Write-Host "  - $_" }
}

Write-Host "`n" -ForegroundColor Cyan
Write-Host "Resumen: $($conContenido.Count) con contenido | $($sinContenido.Count) vacíos | $($noEncontrado.Count) no encontrados"
