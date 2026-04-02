#!/usr/bin/env pwsh
<#
.SYNOPSIS
Unifica formato de secciones en partituras.

.DESCRIPTION
Convierte formatos antiguos [Verse], [Chorus], etc al estándar:
INTRO, ESTROFA, PRE-ESTRIBILLO, ESTRIBILLO, PUENTE, SOLO, FINAL

.PARAMETER FilePath
Ruta del archivo (opcional)
#>

param([string]$FilePath)

function Unify-SectionFormat {
    param([string]$text)
    
    $result = $text
    
    # Conversiones con case-insensitive
    $replacements = @(
        @{ pattern = '\[verse\s*1\]'; replacement = 'ESTROFA 1' },
        @{ pattern = '\[verse\s*2\]'; replacement = 'ESTROFA 2' },
        @{ pattern = '\[verse\s*3\]'; replacement = 'ESTROFA 3' },
        @{ pattern = '\[verse\s*4\]'; replacement = 'ESTROFA 4' },
        @{ pattern = '\[verse\s*5\]'; replacement = 'ESTROFA 5' },
        @{ pattern = '\[verse\s*6\]'; replacement = 'ESTROFA 6' },
        @{ pattern = '\[verse\s*7\]'; replacement = 'ESTROFA 7' },
        @{ pattern = '\[verse\s*8\]'; replacement = 'ESTROFA 8' },
        @{ pattern = '\[verse\]'; replacement = 'ESTROFA' },
        
        @{ pattern = '\[chorus\s*[0-9]?\]'; replacement = 'ESTRIBILLO' },
        @{ pattern = '\[hook\s*[0-9]?\]'; replacement = 'ESTRIBILLO' },
        
        @{ pattern = '\[pre-chorus\]'; replacement = 'PRE-ESTRIBILLO' },
        @{ pattern = '\[pre-hook\s*[0-9]?\]'; replacement = 'PRE-ESTRIBILLO' },
        
        @{ pattern = '\[bridge\]'; replacement = 'PUENTE' },
        @{ pattern = '\[intro\s*[^\]]*\]'; replacement = 'INTRO' },
        @{ pattern = '\[outro\s*[^\]]*\]'; replacement = 'FINAL' },
        @{ pattern = '\[(instrumental|instrument|solo)\s*[^\]]*\]'; replacement = 'SOLO' }
    )
    
    foreach ($rep in $replacements) {
        $result = [regex]::Replace($result, $rep.pattern, $rep.replacement, 'IgnoreCase')
    }
    
    return $result
}

function Process-File {
    param([string]$path)
    
    Write-Host "Procesando: $(Split-Path -Leaf $path)" -ForegroundColor Cyan
    
    try {
        $content = Get-Content $path -Encoding UTF8 -Raw
        $unified = Unify-SectionFormat $content
        
        if ($content -ne $unified) {
            $unified | Set-Content $path -Encoding UTF8 -NoNewline
            Write-Host "  ✓ Actualizado" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "  - Sin cambios" -ForegroundColor Gray
            return $false
        }
    }
    catch {
        Write-Host "  ✗ Error: $_" -ForegroundColor Red
        return $false
    }
}

# MAIN
if ($FilePath) {
    if (Test-Path $FilePath) { 
        Process-File $FilePath 
    }
    else { 
        Write-Host "Archivo no encontrado" -ForegroundColor Red 
    }
}
else {
    $folder = Join-Path $PSScriptRoot "partituras"
    if (-not (Test-Path $folder)) {
        $folder = $PSScriptRoot
    }
    
    if (-not (Test-Path $folder)) { 
        Write-Host "Carpeta /partituras no encontrada" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Unificando formatos en: $folder`n" -ForegroundColor Yellow
    
    $files = @(
        Get-ChildItem -Path $folder -Filter "*.txt" -File
        Get-ChildItem -Path $folder -Filter "*.md" -File
    )
    
    $changedCount = 0
    foreach ($file in $files) {
        if (Process-File $file.FullName) { 
            $changedCount++ 
        }
    }
    
    Write-Host "`n✓ Completado: $changedCount/$($files.Count) archivos actualizados" -ForegroundColor Green
}
