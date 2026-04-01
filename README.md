# Partituras TXT App

## Descripcion

Esta aplicacion web permite buscar y abrir partituras en formato TXT desde una interfaz hecha con Bootstrap.

## Estructura del Proyecto

El proyecto tiene la siguiente estructura de archivos:

```
partituras-txt-app
├── css
│   └── styles.css          # Estilos para la aplicación
├── js
│   ├── app.js              # Lógica principal de la aplicación
│   └── parser.js           # Funciones para parsear archivos de texto
├── partituras
│   ├── artista-01-cancion-01.txt  # Partitura de una canción de un artista
│   └── grupo-01-cancion-02.txt    # Partitura de una canción de un grupo
├── index.html               # Archivo HTML principal
├── songs.html               # Página para mostrar las canciones
└── README.md                # Documentación del proyecto
```

## Instalacion

1. Clona o descarga este proyecto en tu maquina.
2. Abre la carpeta en VS Code.
3. Inicia un servidor local (por ejemplo, con la extension Live Server) y abre `index.html`.

## Uso

- Escribe en el buscador por artista, titulo o nombre de archivo.
- Haz clic en una cancion para abrir la partitura completa en el panel derecho.
- Marca canciones favoritas con la estrella `☆/★` y usa el filtro `Favoritas`.
- Guarda por cancion uno o varios instrumentos habituales, por ejemplo `Guitarra electrica` y `Piano` a la vez.
- Valora como te sale cada cancion con `0-5` estrellas.
- Filtra la lista por instrumento y por canciones que te salgan a partir de cierto nivel. Si una cancion tiene varios instrumentos, aparece en todos los filtros que correspondan.
- Ajusta lectura con `A-`, `Reset`, `A+`.
- Usa transposicion por semitonos con `-1`, `0`, `+1`.
- Activa `Autoscroll` y regula velocidad con el deslizador.
- Atajos: `Alt + Flecha Arriba` y `Alt + Flecha Abajo` para transponer rapido.
- El ejemplo de Vetusta Morla esta incluido en `partituras/Vetusta Morla - De Junio.txt`.

## Sincronizar datos entre ordenadores

Todos tus perfiles (instrumentos, ratings, favoritas, historial de búsqueda) se guardan en el navegador (`localStorage`). Para usar la misma configuración en varios ordenadores:

1. **En el ordenador actual**:
   - Abre la aplicación y personaliza tus canciones (marca instrumentos, rate, favoritas, etc.)
   - Haz clic en el botón **"📥 Exportar"** 
   - Se descargará un archivo JSON con todos tus datos

2. **Comparte los datos**:
   - Puedes subir el JSON a GitHub editando `partituras/song-profiles.json`
   - O simplemente pasar el archivo al otro ordenador

3. **En el otro ordenador**:
   - Haz clic en el botón **"📤 Importar"**
   - Selecciona el archivo JSON descargado
   - Tus datos se cargarán automáticamente

**Nota**: La aplicación carga automáticamente `partituras/song-profiles.json` desde el repositorio al iniciar, así que si subes el archivo a GitHub, todos tus dispositivos lo cargarán.

- La app se usa en `index.html`.
- `songs.html` redirige automaticamente a `index.html` para mantener enlaces antiguos.

## Actualizar el catalogo al agregar partituras

Cuando agregues nuevos archivos `.txt` en la carpeta `partituras`, regenera `partituras/index.json` con el script incluido:

```powershell
./update-song-index.ps1
```

Tambien puedes ejecutarlo desde VS Code con la tarea `Actualizar indice de partituras`.

El script mejora dos cosas respecto al comando manual:

- Limpia acentos y caracteres raros para generar `id` mas estables.
- Interpreta correctamente nombres como `- Con Las Ganas.txt` para que el titulo no arrastre el guion inicial.

## Importar estrellas e instrumentos desde tu CSV

Si tienes un CSV con columnas como `Estrellas`, `PIA`, `GUI`, `Artista` y `Titulo`, puedes reutilizarlo para precargar perfiles por cancion.

El comando importa las coincidencias al fichero `partituras/song-profiles.seed.json`:

```powershell
./update-song-index.ps1 -MetadataCsvPath "C:/Users/Dani/Desktop/canciones.txt"
```

La app carga ese fichero como base al arrancar:

- Las canciones importadas ya aparecen con estrellas e instrumentos marcados.
- Si despues cambias una cancion desde la web, tu cambio manual en `localStorage` tiene prioridad sobre lo importado.
- La importacion intenta casar variantes razonables de nombres, por ejemplo acentos, mayusculas o sufijos tipo `(ver 2)`.

Si prefieres hacerlo manualmente, este es el comando equivalente desde PowerShell en la raiz del proyecto:

```powershell
$files = Get-ChildItem -Path "partituras" -File -Filter "*.txt" | Sort-Object Name
$songs = foreach ($f in $files) {
	$base = [System.IO.Path]::GetFileNameWithoutExtension($f.Name)
	$parts = $base -split ' - ', 2
	if ($parts.Count -eq 2) { $artist = $parts[0].Trim(); $title = $parts[1].Trim() }
	else { $artist = 'Desconocido'; $title = $base.Trim() }
	$id = ($base.ToLowerInvariant() -replace '[^a-z0-9]+','-').Trim('-')
	if ([string]::IsNullOrWhiteSpace($id)) { $id = [guid]::NewGuid().ToString('N') }
	[pscustomobject]@{ id=$id; artist=$artist; title=$title; filename=$f.Name }
}
$songs | ConvertTo-Json -Depth 3 | Set-Content -Path "partituras/index.json" -Encoding UTF8
```

## Estado actual y bitacora (2026-04-01)

### Resumen de lo realizado

- Se amplio el indexado para incluir canciones en `.md` ademas de `.txt`.
- Se mejoro la deteccion de secciones para reconocer variantes en markdown y texto libre.
- Se mejoro la visualizacion de archivos `.md` en la app para limpiar marcado (`#`, `**`, bloques de codigo y restos de conflictos).
- Se creo y ejecuto normalizacion masiva de catalogo en `normalize-partitura-txt.ps1` para:
  - anadir cabecera canonica `# PARTITURA v1` en archivos `.txt` sin cabecera,
  - unificar etiquetas de secciones (por ejemplo `Verse` -> `ESTROFA`, `Chorus` -> `ESTRIBILLO`, `Bridge` -> `PUENTE`).
- **[1 de abril] BUG ARREGLADO**: Typo en `js/parser.js` linea 13 - variable `titleArtistArtistLine` (variable replicada) corregida a `titleArtistLine`. Este bug impedia que el parser extrajera correctamente el artista del archivo de partitura.
- **[1 de abril] FEATURE NOVA**: Detector automático de acordes - Ahora cada canción muestra sus acordes principales (C#m, G#m, etc) en forma de badges en la lista. Esto permite ver de un vistazo qué acordes tiene cada canción antes de abrirla. Los acordes se ordenan por frequencia (más tocados primero) y se normalizan (AM → Am, F#M → F#m).
- **[1 de abril] BUG ARREGLADO**: Capo value validation - La función `parseCapoValue` ahora solo acepta capo entre 1-12 (rango válido de guitarra). Evita valores inválidos como "capo 23" que aparecían por error en la detección. Se agregó reset de `activeSongCapo` al cargar nueva canción para limpiar valores anteriores.

### Estado del catalogo tras la normalizacion

- Total de `.txt`: 514
- Archivos `.txt` normalizados en la pasada: 397
- Archivos `.txt` vacios detectados (no normalizables mientras esten vacios):
  - `partituras/Coldplay - adventure of a lifetime2.txt`
  - `partituras/Coldplay - yellow2.txt`
  - `partituras/Ed Sheeran - perfect.txt`
  - `partituras/Ed Sheeran - thinking out loud.txt`

### Incidencias conocidas

- En este entorno no existe el comando `pwsh`; usar `powershell` para ejecutar scripts.
- En alguna ejecucion, `partituras/song-profiles.seed.json` quedo bloqueado por otro proceso y no se pudo reescribir en ese momento.

### Comandos de referencia

Regenerar indice:

```powershell
powershell -ExecutionPolicy Bypass -File ./update-song-index.ps1
```

Normalizar catalogo `.txt`:

```powershell
powershell -ExecutionPolicy Bypass -File ./normalize-partitura-txt.ps1
```

Simulacion sin escribir cambios:

```powershell
powershell -ExecutionPolicy Bypass -File ./normalize-partitura-txt.ps1 -WhatIf
```

### Cambios futuros recomendados

- Limpieza de doble cabecera en archivos que ya traian metadatos propios.
- Unificar la cabecera en formato canonico final (decidir si usar acentos o ASCII y mantener un unico criterio).
- Rellenar o eliminar los 4 `.txt` vacios para evitar ruido en busqueda e indice.
- Revisar nombres de archivo anomales (`Artista -.txt`, sufijos numericos, duplicados) y estandarizar.
- Actualizar la tarea de VS Code `Actualizar indice de partituras` para no depender de `pwsh`.
- **[MEJORA]: Rastrear partituras más accedidas** - Registrar cada apertura de canción en localStorage con timestamp y mostrar sugerencias (top 5-10) de canciones más consultadas recientemente en la página principal. Util para acceder rapido a las canciones que tocas habitualmente.

## Contribuciones

Las contribuciones son bienvenidas. Si deseas mejorar la aplicación, por favor abre un issue o envía un pull request.

## Licencia

Este proyecto está bajo la Licencia MIT.
