# Actualizar index.json
$json = Get-Content 'partituras/index.json' -Raw | ConvertFrom-Json

# Eliminar entradas antiguas
$json = @($json | Where-Object { 
    $_.filename -ne "hero of war.md" -and 
    $_.filename -ne "quan somrius.md" -and 
    $_.filename -ne "tot el que vull per nadal.md"
})

# Convertir a array de objetos si es necesario
$jsonArray = @()
$jsonArray += $json

# Agregar nuevas entradas
$jsonArray += @(
    @{
        artist = "Josep Thió"
        title = "Quan somrius"
        id = "josep-thio-quan-somrius"
        filename = "Josep Thió - Quan somrius.md"
    },
    @{
        artist = "Villancicos"
        title = "Tot el que vull per nadal"
        id = "villancicos-tot-el-que-vull-per-nadal"
        filename = "Villancicos - Tot el que vull per nadal.md"
    }
)

# Actualizar la entrada de Rise Against
$jsonArray | Where-Object { $_.id -eq "rise-against-hero-of-war" } | ForEach-Object {
    $_.filename = "Rise Against - Hero of War.md"
}

# Guardar
$jsonArray | ConvertTo-Json -Depth 20 | Set-Content 'partituras/index.json'
Write-Host "✅ index.json actualizado correctamente" -ForegroundColor Green
