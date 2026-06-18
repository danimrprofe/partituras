# Script para integrar las 24 canciones de Leiva con instrumentos y técnicas manuales

$profilesPath = "c:\Users\Dani\Desktop\github\partituras\partituras\song-profiles.json"

# Data de canciones manuales de Leiva
$leivaManual = @{
    "leiva-la-llamada" = @{
        "instruments" = @("guitarra-acustica")
        "techniques" = @()
    }
    "leiva-los-cantantes" = @{
        "instruments" = @("guitarra-electrica")
        "techniques" = @()
    }
    "leiva-terriblemente-cruel" = @{
        "instruments" = @("guitarra-electrica")
        "techniques" = @()
    }
    "leiva-cerca" = @{
        "instruments" = @("guitarra-electrica")
        "techniques" = @()
    }
    "leiva-afuera-en-la-ciudad" = @{
        "instruments" = @("guitarra-electrica")
        "techniques" = @()
    }
    "leiva-vertigo" = @{
        "instruments" = @("guitarra-electrica")
        "techniques" = @("palm-mute")
    }
    "leiva-mirada-perdida" = @{
        "instruments" = @("guitarra-electrica")
        "techniques" = @("palm-mute")
    }
    "leiva-francesita" = @{
        "instruments" = @("guitarra-electrica")
        "techniques" = @("fingerpicking")
    }
    "leiva-polvora" = @{
        "instruments" = @("piano")
        "techniques" = @()
    }
    "leiva-eme" = @{
        "instruments" = @("guitarra-acustica")
        "techniques" = @()
    }
    "leiva-92" = @{
        "instruments" = @("guitarra-electrica")
        "techniques" = @()
    }
    "leiva-miedo" = @{
        "instruments" = @("guitarra-electrica")
        "techniques" = @()
    }
    "leiva-aunque-sea-un-rato" = @{
        "instruments" = @("guitarra-acustica", "piano")
        "techniques" = @()
    }
    "leiva-extasis" = @{
        "instruments" = @("guitarra-electrica")
        "techniques" = @()
    }
    "leiva-vis-a-vis" = @{
        "instruments" = @("guitarra-acustica")
        "techniques" = @()
    }
    "leiva-guerra-mundial" = @{
        "instruments" = @("guitarra-electrica")
        "techniques" = @()
    }
    "leiva-sincericidio" = @{
        "instruments" = @("guitarra-electrica")
        "techniques" = @()
    }
    "leiva-la-lluvia-en-los-zapatos" = @{
        "instruments" = @("guitarra-electrica")
        "techniques" = @("fingerpicking")
    }
    "leiva-lobos" = @{
        "instruments" = @("guitarra-electrica")
        "techniques" = @()
    }
    "leiva-costa-de-oaxaca" = @{
        "instruments" = @("piano", "guitarra-acustica")
        "techniques" = @()
    }
    "leiva-godzilla" = @{
        "instruments" = @("guitarra-electrica")
        "techniques" = @("fingerpicking")
    }
    "leiva-stranger-things" = @{
        "instruments" = @("guitarra-electrica")
        "techniques" = @("fingerpicking")
    }
    "leiva-histericos" = @{
        "instruments" = @("guitarra-acustica")
        "techniques" = @()
    }
    "leiva-peligrosamente-dark" = @{
        "instruments" = @("guitarra-acustica")
        "techniques" = @()
    }
}

# Cargar JSON existente
$existingProfiles = Get-Content $profilesPath -Raw | ConvertFrom-Json

# Convertir a hashtable para fácil manipulación
$profiles = @{}
$existingProfiles.PSObject.Properties | ForEach-Object {
    $profiles[$_.Name] = $_.Value
}

# Integrar información manual de Leiva
$leivaManual.GetEnumerator() | ForEach-Object {
    $songId = $_.Key
    $leivaData = $_.Value
    
    if ($profiles.ContainsKey($songId)) {
        # Actualizar con instruments y techniques
        $profiles[$songId].instruments = $leivaData.instruments
        $profiles[$songId].techniques = $leivaData.techniques
    } else {
        # Crear nuevo perfil
        $profiles[$songId] = @{
            instruments = $leivaData.instruments
            techniques = $leivaData.techniques
            rating = 0
            tuning = ""
        }
    }
}

# Convertir a JSON y guardar
$output = [ordered]@{}
$profiles.GetEnumerator() | Sort-Object Name | ForEach-Object {
    $output[$_.Key] = $_.Value
}

$json = $output | ConvertTo-Json -Depth 10
$json | Out-File -Encoding UTF8 -FilePath $profilesPath

Write-Host "✓ Integración completada!"
Write-Host "Se actualizaron/agregaron 24 canciones de Leiva"
Write-Host "Total de canciones en profiles: $($output.Count)"
