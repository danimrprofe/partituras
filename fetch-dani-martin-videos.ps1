# Script para buscar videos de YouTube solo para Dani Martin

$indexPath = "./partituras/index.json"
$env:PATH = "$env:PATH;C:\Users\Dani\AppData\Roaming\Python\Python312\Scripts"

# Leer el índice JSON
$json = Get-Content -Path $indexPath -Raw -Encoding UTF8 | ConvertFrom-Json

# Filtrar solo canciones de Dani Martin (con y sin acento)
$daniSongs = $json | Where-Object { $_.artist -like "*Dani Martin*" -or $_.artist -like "*Dani Mart*n*" }

Write-Host "Encontradas $($daniSongs.Count) canciones de Dani Martin" -ForegroundColor Cyan

$urlsAdded = 0
$urlsFailed = 0

foreach ($song in $daniSongs) {
    $searchQuery = "$($song.artist) $($song.title)"
    Write-Host "`nBuscando: $searchQuery..." -ForegroundColor Yellow
    
    try {
        # Usar yt-dlp para buscar y obtener la URL del primer resultado
        $output = & yt-dlp --quiet --no-warnings --no-playlist --print "original_url" -s "ytsearch1:$searchQuery" 2>$null
        
        if ($output -and $output -match "youtube\.com") {
            $song.youtubeUrl = $output.Trim()
            Write-Host "✓ $searchQuery" -ForegroundColor Green
            Write-Host "  URL: $($song.youtubeUrl)" -ForegroundColor Green
            $urlsAdded++
        }
        else {
            Write-Host "✗ No se encontró video para: $searchQuery" -ForegroundColor Red
            $urlsFailed++
        }
    }
    catch {
        Write-Host "✗ Error: $_" -ForegroundColor Red
        $urlsFailed++
    }
    
    Start-Sleep -Milliseconds 800
}

# Guardar el índice actualizado
$json | ConvertTo-Json -Depth 10 | Set-Content -Path $indexPath -Encoding UTF8

Write-Host "
=== RESUMEN ===" -ForegroundColor Cyan
Write-Host "URLs encontradas: $urlsAdded" -ForegroundColor Green
Write-Host "URLs fallidas: $urlsFailed" -ForegroundColor Yellow
Write-Host "Índice actualizado: $indexPath"
