# Actualizar index.json con los nuevos nombres
$json = Get-Content 'partituras/index.json' -Raw | ConvertFrom-Json

# Convertir a array si es necesario
$jsonArray = @()
$jsonArray += $json

# Reemplazar entradas antiguas por nuevas
$jsonArray = @($jsonArray | Where-Object { 
    -not (@("Coque Malla - Sin titulo.txt", 
            "Johnny Cash - Sin titulo.txt", 
            "Los Secretos - Sin titulo.txt", 
            "Leiva - Sin titulo.txt") -contains $_.filename)
})

# Agregar nuevas entradas
$jsonArray += @(
    @{
        artist = "Coque Malla"
        title = "Berlín"
        id = "coque-malla-berlin"
        filename = "Coque Malla - Berlín.txt"
    },
    @{
        artist = "Johnny Cash"
        title = "Hurt"
        id = "johnny-cash-hurt"
        filename = "Johnny Cash - Hurt.txt"
    },
    @{
        artist = "Los Secretos"
        title = "Dejame"
        id = "los-secretos-dejame"
        filename = "Los Secretos - Dejame.txt"
    },
    @{
        artist = "Leiva"
        title = "92"
        id = "leiva-92"
        filename = "Leiva - 92.txt"
    }
)

# Guardar
$jsonArray | ConvertTo-Json -Depth 20 | Set-Content 'partituras/index.json'
Write-Host "✅ index.json actualizado con 4 nuevas canciones" -ForegroundColor Green
