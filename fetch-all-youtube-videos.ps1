# Script para obtener URLs de YouTube para TODAS las canciones
# Esta es la versión final que actualiza todas las 543 canciones

$indexPath = "./partituras/index.json"
$env:PATH = "$env:PATH;C:\Users\Dani\AppData\Roaming\Python\Python312\Scripts"

# Leer el índice JSON
$json = Get-Content -Path $indexPath -Raw -Encoding UTF8 | ConvertFrom-Json

Write-Host "Iniciando búsqueda de URLs para todas las canciones..." -ForegroundColor Cyan
Write-Host "Total de canciones: $($json.Count)" -ForegroundColor Cyan

$urlsAdded = 0
$urlsFailed = 0
$urlsAlready = 0

foreach ($i = 0; $i -lt $json.Count; $i++) {
    $song = $json[$i]
    
    # Si ya tiene URL de video específica, saltar
    if ($song.youtubeUrl -match "watch\?v=") {
        $urlsAlready++
        continue
    }
    
    $searchQuery = "$($song.artist) $($song.title)"
    
    # Mostrar progreso cada 50 canciones
    if (($i + 1) % 50 -eq 0) {
        Write-Host "Progreso: $($i + 1)/$($json.Count)" -ForegroundColor Yellow
    }
    
    try {
        # Usar yt-dlp para buscar y obtener la URL del primer resultado
        $output = & yt-dlp --quiet --no-warnings --no-playlist --print "original_url" -s "ytsearch1:$searchQuery" 2>$null
        
        if ($output -and $output -match "youtube\.com") {
            $song.youtubeUrl = $output.Trim()
            $urlsAdded++
        }
        else {
            Write-Host "✗ No se encontró: $searchQuery" -ForegroundColor Red
            $urlsFailed++
        }
    }
    catch {
        Write-Host "✗ Error en $searchQuery : $_" -ForegroundColor Red
        $urlsFailed++
    }
    
    Start-Sleep -Milliseconds 400
}

# Guardar el índice actualizado
$json | ConvertTo-Json -Depth 10 | Set-Content -Path $indexPath -Encoding UTF8

Write-Host "
=== RESUMEN FINAL ===" -ForegroundColor Cyan
Write-Host "URLs nuevas encontradas: $urlsAdded" -ForegroundColor Green
Write-Host "URLs que ya tenían: $urlsAlready" -ForegroundColor Green
Write-Host "URLs fallidas: $urlsFailed" -ForegroundColor Yellow
Write-Host "Total con URL: $($urlsAdded + $urlsAlready)" -ForegroundColor Cyan
Write-Host "Índice actualizado: $indexPath"
