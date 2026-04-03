# Script para integrar información de instrumentos de Leiva en song-profiles.json

$profilesPath = "c:\Users\Dani\Desktop\github\partituras\partituras\song-profiles.json"
$leivaPath = "c:\Users\Dani\Desktop\github\partituras\leiva-instruments.json"

# Cargar JSON existente
$existingProfiles = Get-Content $profilesPath -Raw | ConvertFrom-Json
$leivaInstruments = Get-Content $leivaPath -Raw | ConvertFrom-Json

# Convertir a hashtable para fácil manipulación
$profiles = @{}
$existingProfiles.PSObject.Properties | ForEach-Object {
    $profiles[$_.Name] = $_.Value
}

# Integrar información de Leiva
$leivaInstruments.PSObject.Properties | ForEach-Object {
    $songId = $_.Name
    $leivaData = $_.Value
    
    if ($profiles.ContainsKey($songId)) {
        # Actualizar instrumento si existe
        $profiles[$songId].instruments = $leivaData.instruments
    } else {
        # Crear nuevo perfil si no existe
        $profiles[$songId] = $leivaData
    }
}

# Convertir a JSON y guardar
$output = [ordered]@{}
$profiles.GetEnumerator() | Sort-Object Name | ForEach-Object {
    $output[$_.Key] = $_.Value
}

$json = $output | ConvertTo-Json -Depth 10
$json | Out-File -Encoding UTF8 -FilePath $profilesPath

Write-Host "Integración completada!"
Write-Host "Se actualizaron/agregaron $($leivaInstruments.PSObject.Properties.Count) canciones de Leiva"
Write-Host "Total de canciones en profiles: $($output.Count)"
