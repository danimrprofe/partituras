$indexPath = "c:\Users\Dani\Desktop\github\partituras\partituras\index.json"

# Leer el contenido como texto
$content = Get-Content $indexPath -Raw -Encoding UTF8

# Usar regex para agregar youtubeUrl a cada objeto
# Busca ",\n    }" y lo reemplaza con ",\n        \"youtubeUrl\": \"\"\n    }"
$content = $content -replace ',(\s*\n\s*\})', ',"youtubeUrl": ""$1'

# Guardar
Set-Content $indexPath -Value $content -Encoding UTF8

Write-Host "Campo youtubeUrl agregado a todas las canciones"
