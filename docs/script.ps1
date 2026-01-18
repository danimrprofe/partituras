$files = Get-ChildItem *.md

foreach ($file in $files) {
    # Leemos el texto de forma segura
    $content = [System.IO.File]::ReadAllText($file.FullName)
    
    # Creamos los 3 acentos usando el código ASCII 96 para evitar errores de sintaxis
    $tresAcentos = [char]96 + [char]96 + [char]96
    
    # Si el contenido NO empieza ya por esos acentos...
    if (-not $content.StartsWith($tresAcentos)) {
        
        # Creamos el nuevo bloque: acentos + salto de línea + contenido + salto de línea + acentos
        $nuevoContenido = $tresAcentos + "`n" + $content + "`n" + $tresAcentos
        
        # Guardamos usando la librería de .NET para máxima compatibilidad
        [System.IO.File]::WriteAllText($file.FullName, $nuevoContenido)
        
        Write-Host "Procesado: $($file.Name)" -ForegroundColor Cyan
    } else {
        Write-Host "Saltado (Ya envuelto): $($file.Name)" -ForegroundColor Yellow
    }
}