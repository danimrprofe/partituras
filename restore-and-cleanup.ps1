# Script para copiar archivos del backup y eliminar m-clan vacíos

$backupPath = "C:\Users\Dani\Desktop\github\partituras\Partituras - copia"
$currentPath = ".\partituras"

# Archivos a copiar del backup
$archivosACopiar = @(
    "Countin Crows - Colorblind.txt",
    "Extremoduro - Standby.txt",
    "Joaquín Sabina - Pájaros De Portugal.txt",
    "Justin Timberlake - True Colors.txt",
    "Pereza - Princesas.txt",
    "Pereza - Si Quieres Bailamos.txt",
    "Sidecars - La Tormenta.txt"
)

# m-clan vacíos a eliminar
$archivosAEliminar = @(
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
    "m-clan - polvo de estrellas.txt"
)

Write-Host "=== COPIANDO ARCHIVOS DEL BACKUP ===" -ForegroundColor Cyan
$copiados = 0
foreach ($archivo in $archivosACopiar) {
    $origen = Join-Path $backupPath $archivo
    $destino = Join-Path $currentPath $archivo
    
    if (Test-Path $origen) {
        Copy-Item -Path $origen -Destination $destino -Force
        Write-Host "✓ $archivo" -ForegroundColor Green
        $copiados++
    } else {
        Write-Host "✗ NO ENCONTRADO: $archivo" -ForegroundColor Red
    }
}

Write-Host "`n=== ELIMINANDO ARCHIVOS m-clan VACÍOS ===" -ForegroundColor Yellow
$eliminados = 0
foreach ($archivo in $archivosAEliminar) {
    $ruta = Join-Path $currentPath $archivo
    
    if (Test-Path $ruta) {
        Remove-Item -Path $ruta -Force
        Write-Host "✓ Eliminado: $archivo" -ForegroundColor Red
        $eliminados++
    } else {
        Write-Host "- No existe: $archivo" -ForegroundColor Gray
    }
}

Write-Host "`n=== RESUMEN ===" -ForegroundColor Cyan
Write-Host "Archivos copiados: $copiados" -ForegroundColor Green
Write-Host "Archivos eliminados: $eliminados" -ForegroundColor Red
Write-Host "Total cambiado: $($copiados + $eliminados)"
