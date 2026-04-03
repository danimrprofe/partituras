# Actualizar index.json - Eliminar referencias a .md duplicados
$json = Get-Content 'partituras/index.json' -Raw | ConvertFrom-Json

# Convertir a array
$jsonArray = @()
$jsonArray += $json

# Eliminar entradas que apuntan a los .md eliminados
$jsonArray = @($jsonArray | Where-Object { 
    -not (@("Andres Calamaro - Te Quiero Igual.md", 
            "Marea - Barniz.md", 
            "Marea - Incandescente.md") -contains $_.filename)
})

# Guardar
$jsonArray | ConvertTo-Json -Depth 20 | Set-Content 'partituras/index.json'
Write-Host "✅ index.json actualizado - Referencias .md eliminadas" -ForegroundColor Green
