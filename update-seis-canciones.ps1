# Actualizar index.json con los 6 nuevos títulos
$json = Get-Content 'partituras/index.json' -Raw | ConvertFrom-Json

# Convertir a array
$jsonArray = @()
$jsonArray += $json

# Eliminar entradas antiguas
$jsonArray = @($jsonArray | Where-Object { 
    -not (@("Dani Martín - Sin titulo.txt", 
            "El Canto Del Loco - Sin titulo.txt", 
            "Jarabe De Palo - Sin titulo.txt", 
            "Lenny Kravitz - Sin titulo.txt",
            "Los Piratas - Sin titulo.txt",
            "Matchbox Twenty - Sin titulo.txt") -contains $_.filename)
})

# Agregar nuevas entradas
$jsonArray += @(
    @{
        artist = "Dani Martín"
        title = "Cuatro Likes"
        id = "dani-martin-cuatro-likes"
        filename = "Dani Martín - Cuatro Likes.txt"
    },
    @{
        artist = "El Canto Del Loco"
        title = "Besos"
        id = "el-canto-del-loco-besos"
        filename = "El Canto Del Loco - Besos.txt"
    },
    @{
        artist = "Jarabe De Palo"
        title = "Vecina"
        id = "jarabe-de-palo-vecina"
        filename = "Jarabe De Palo - Vecina.txt"
    },
    @{
        artist = "Lenny Kravitz"
        title = "Again"
        id = "lenny-kravitz-again"
        filename = "Lenny Kravitz - Again.txt"
    },
    @{
        artist = "Los Piratas"
        title = "M"
        id = "los-piratas-m"
        filename = "Los Piratas - M.txt"
    },
    @{
        artist = "Matchbox Twenty"
        title = "Unwell"
        id = "matchbox-twenty-unwell"
        filename = "Matchbox Twenty - Unwell.txt"
    }
)

# Guardar
$jsonArray | ConvertTo-Json -Depth 20 | Set-Content 'partituras/index.json'
Write-Host "✅ index.json actualizado con 6 nuevas canciones" -ForegroundColor Green
