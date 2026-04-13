# Script para buscar videos de YouTube y guardar sus URLs exactas
# Requiere yt-dlp instalado: choco install yt-dlp o pip install yt-dlp

$indexPath = "./partituras/index.json"

# Agregar yt-dlp al PATH
$env:PATH = "$env:PATH;C:\Users\Dani\AppData\Roaming\Python\Python312\Scripts"

# Verificar si yt-dlp está disponible
$ytDlpAvailable = $null -ne (Get-Command yt-dlp -ErrorAction SilentlyContinue)

if (-not $ytDlpAvailable) {
    Write-Host "yt-dlp no está instalado. Instalando..."
    try {
        pip install yt-dlp
        $ytDlpAvailable = $true
    }
    catch {
        Write-Host "Error al instalar yt-dlp. Intenta: pip install yt-dlp"
        exit 1
    }
}

# Leer el índice JSON
$json = Get-Content -Path $indexPath -Raw -Encoding UTF8 | ConvertFrom-Json
$urlsAdded = 0
$urlsFailed = 0

foreach ($song in $json) {
    # Si ya tiene URL de video específica, saltar
    if ($song.youtubeUrl -match "watch\?v=") {
        continue
    }
    
    $searchQuery = "$($song.artist) $($song.title)"
    Write-Host "Buscando: $searchQuery..." -ForegroundColor Yellow
    
    try {
        # Usar yt-dlp para buscar y obtener la URL del primer resultado
        # --quiet: sin output innecesario
        # --no-warnings: sin warnings
        # --print: imprime la URL
        $output = & yt-dlp --quiet --no-warnings --no-playlist --print "original_url" -s "ytsearch1:$searchQuery" 2>$null
        
        if ($output -and $output -match "youtube\.com") {
            $song.youtubeUrl = $output.Trim()
            Write-Host "✓ $searchQuery -> $($song.youtubeUrl)" -ForegroundColor Green
            $urlsAdded++
        }
        else {
            Write-Host "✗ No se encontró video para: $searchQuery" -ForegroundColor Red
            $urlsFailed++
        }
    }
    catch {
        Write-Host "✗ Error buscando $searchQuery : $_" -ForegroundColor Red
        $urlsFailed++
    }
    
    # Pequeña pausa para no sobrecargar YouTube
    Start-Sleep -Milliseconds 500
}

# Guardar el índice actualizado
$json | ConvertTo-Json -Depth 10 | Set-Content -Path $indexPath -Encoding UTF8

Write-Host "
=== RESUMEN ===" -ForegroundColor Cyan
Write-Host "URLs encontradas: $urlsAdded" -ForegroundColor Green
Write-Host "URLs fallidas: $urlsFailed" -ForegroundColor Yellow
Write-Host "Índice actualizado: $indexPath"
