document.addEventListener("DOMContentLoaded", () => {
    const searchInput = document.getElementById("searchInput");
    const searchSuggestions = document.getElementById("searchSuggestions");
    const songList = document.getElementById("songList");
    const songCount = document.getElementById("songCount");
    const songView = document.getElementById("songView");
    const emptyState = document.getElementById("emptyState");
    const songTitle = document.getElementById("songTitle");
    const songMeta = document.getElementById("songMeta");
    const songBody = document.getElementById("songBody");
    const capoContainer = document.getElementById("capoContainer");
    const songCapo = document.getElementById("songCapo");
    const bpmContainer = document.getElementById("bpmContainer");
    const songBpm = document.getElementById("songBpm");
    const techniquesContainer = document.getElementById("techniquesContainer");
    const songTechniques = document.getElementById("songTechniques");
    const musicalInfoContainer = document.getElementById("musicalInfoContainer");
    const keyContainer = document.getElementById("keyContainer");
    const songKey = document.getElementById("songKey");
    const timeSignatureContainer = document.getElementById("timeSignatureContainer");
    const songTimeSignature = document.getElementById("songTimeSignature");

    const fontDown = document.getElementById("fontDown");
    const fontReset = document.getElementById("fontReset");
    const fontUp = document.getElementById("fontUp");

    const transposeDown = document.getElementById("transposeDown");
    const transposeReset = document.getElementById("transposeReset");
    const transposeUp = document.getElementById("transposeUp");
    const transposeBadge = document.getElementById("transposeBadge");

    const autoscrollToggle = document.getElementById("autoscrollToggle");
    const autoscrollSpeed = document.getElementById("autoscrollSpeed");

    const filterAll = document.getElementById("filterAll");
    const filterFavorites = document.getElementById("filterFavorites");
    const resetFilters = document.getElementById("resetFilters");
    const instrumentFilter = document.getElementById("instrumentFilter");
    const ratingFilter = document.getElementById("ratingFilter");
    const tuningFilter = document.getElementById("tuningFilter");
    const capoFilter = document.getElementById("capoFilter");
    const techniqueFilter = document.getElementById("techniqueFilter");
    const keyFilter = document.getElementById("keyFilter");
    const timeSignatureFilter = document.getElementById("timeSignatureFilter");
    const songTuning = document.getElementById("songTuning");
    const favoritesBadge = document.getElementById("favoritesBadge");
    const profileBadge = document.getElementById("profileBadge");

    const songInstrumentGroup = document.getElementById("songInstrumentGroup");
    const songInstrumentInputs = Array.from(document.querySelectorAll('input[name="songInstrument"]'));
    const songRating = document.getElementById("songRating");
    const songRatingLabel = document.getElementById("songRatingLabel");

    const sortByArtist = document.getElementById("sortByArtist");
    const sortByTitle = document.getElementById("sortByTitle");
    const sortByRating = document.getElementById("sortByRating");
    const sortButtons = [sortByArtist, sortByTitle, sortByRating];
    const clearSearchHistoryBtn = document.getElementById("clearSearchHistory");
    const protocolNotice = document.getElementById("protocolNotice");

    const exportProfilesBtn = document.getElementById("exportProfilesBtn");
    const importProfilesBtn = document.getElementById("importProfilesBtn");
    const importProfilesFile = document.getElementById("importProfilesFile");

    if (
        !songList ||
        !searchInput ||
        !searchSuggestions ||
        !songCount ||
        !songBody ||
        !songTitle ||
        !songMeta ||
        !songView ||
        !emptyState ||
        !capoContainer ||
        !songCapo ||
        !bpmContainer ||
        !songBpm ||
        !techniquesContainer ||
        !songTechniques ||
        !musicalInfoContainer ||
        !keyContainer ||
        !songKey ||
        !timeSignatureContainer ||
        !songTimeSignature ||
        !fontDown ||
        !fontReset ||
        !fontUp ||
        !transposeDown ||
        !transposeReset ||
        !transposeUp ||
        !transposeBadge ||
        !autoscrollToggle ||
        !autoscrollSpeed ||
        !filterAll ||
        !filterFavorites ||
        !resetFilters ||
        !instrumentFilter ||
        !ratingFilter ||
        !tuningFilter ||
        !capoFilter ||
        !techniqueFilter ||
        !keyFilter ||
        !timeSignatureFilter ||
        !songTuning ||
        !favoritesBadge ||
        !profileBadge ||
        !songInstrumentGroup ||
        songInstrumentInputs.length === 0 ||
        !songRating ||
        !songRatingLabel ||
        !exportProfilesBtn ||
        !importProfilesBtn ||
        !importProfilesFile
    ) {
        return;
    }

    const STORAGE_KEYS = {
        favorites: "partituras:favorites",
        fontSize: "partituras:font-size",
        filterMode: "partituras:filter-mode",
        instrumentFilter: "partituras:instrument-filter",
        ratingFilter: "partituras:rating-filter",
        tuningFilter: "partituras:tuning-filter",
        capoFilter: "partituras:capo-filter",
        techniqueFilter: "partituras:technique-filter",
        keyFilter: "partituras:key-filter",
        timeSignatureFilter: "partituras:time-signature-filter",
        songProfiles: "partituras:song-profiles",
        searchHistory: "partituras:search-history",
        sortColumn: "partituras:sort-column",
        sortDirection: "partituras:sort-direction"
    };

    const SEED_PROFILES_URL = "partituras/song-profiles.seed.json";

    const INSTRUMENT_LABELS = {
        "sin-definir": "Sin definir",
        "guitarra-electrica": "Guitarra electrica",
        "guitarra-acustica": "Guitarra acustica",
        piano: "Piano"
    };

    const TUNING_LABELS = {
        "": "Sin definir",
        "estandar": "Estandar",
        "medio-tono-abajo": "Medio tono abajo",
        "tono-abajo": "Tono abajo",
        "drop-d": "Drop D",
        "drop-c": "Drop C"
    };

    const RATING_LABELS = {
        0: "Sin valorar",
        1: "Muy floja",
        2: "Sale regular",
        3: "Sale bastante bien",
        4: "Sale bien",
        5: "Sale muy bien"
    };

    const TECHNIQUE_LABELS = {
        "palm-mute": "Palm Mute",
        "fingerpicking": "Fingerpicking",
        "tabs": "Tabs",
        "barre-chords": "Cejilla",
        "strumming": "Rasgueos"
    };

    const TECHNIQUE_COLORS = {
        "palm-mute": "#e2e8f0",
        "fingerpicking": "#fce7f3",
        "tabs": "#dcccff",
        "barre-chords": "#fecaca",
        "strumming": "#fef08a"
    };

    const NOTE_TO_INDEX = {
        C: 0,
        "C#": 1,
        Db: 1,
        D: 2,
        "D#": 3,
        Eb: 3,
        E: 4,
        F: 5,
        "F#": 6,
        Gb: 6,
        G: 7,
        "G#": 8,
        Ab: 8,
        A: 9,
        "A#": 10,
        Bb: 10,
        B: 11
    };

    const SHARP_NOTES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];
    const FLAT_NOTES = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"];

    let songs = [];
    let activeSongId = "";
    let activeSongRawText = "";
    let activeSongCapo = "";
    let activeSongFilename = "";
    let transposeShift = 0;
    let autoscrollTimer = null;
    let fontSizeRem = 0.92;
    let seedSongProfiles = {};
    let searchSuggestionItems = [];
    let activeSuggestionIndex = -1;
    let sortColumn = loadSortColumn();  // artist, title, rating
    let sortDirection = loadSortDirection();  // asc, desc

    const favoriteIds = new Set(loadFavoriteIds());
    const songProfiles = loadSongProfiles();
    let filterMode = loadFilterMode();
    let instrumentFilterValue = loadInstrumentFilter();
    let ratingFilterValue = loadRatingFilter();
    let tuningFilterValue = loadTuningFilter();
    let capoFilterValue = loadCapoFilter();
    let techniqueFilterValue = loadTechniqueFilter();
    let keyFilterValue = loadKeyFilter();
    let timeSignatureFilterValue = loadTimeSignatureFilter();

    const normalize = (value) =>
        value
            .toLowerCase()
            .normalize("NFD")
            .replace(/[\u0300-\u036f]/g, "");

    function extractCapoInfo(rawText) {
        if (!rawText) {
            return { capo: "", cleanText: rawText };
        }

        const lines = rawText.split("\n");
        const cleanLines = [];
        const capoCandidates = [];
        const capoOrdinals = {
            primer: "1",
            primero: "1",
            segundo: "2",
            tercer: "3",
            tercero: "3",
            cuarto: "4",
            quinto: "5",
            sexto: "6",
            septimo: "7",
            octavo: "8",
            noveno: "9",
            decimo: "10",
            undecimo: "11",
            duodecimo: "12"
        };

        lines.forEach((line, index) => {
            const trimmed = line.trim();
            const normalizedTrimmed = normalize(trimmed);
            const upperTrimmed = trimmed.toUpperCase();
            const hasCapoPrefix = upperTrimmed.startsWith("CEJILLA/CAPO:") ||
                                  upperTrimmed.startsWith("CEJILLA:") ||
                                  upperTrimmed.startsWith("CAPO:");
            const hasCapoKeyword = /\bcapo\s+[0-9]/i.test(trimmed);
            const hasCapoOrdinal = /\b(?:con\s+)?(?:cejilla|capo)\s+en\s+el\s+(primer|primero|segundo|tercer|tercero|cuarto|quinto|sexto|septimo|octavo|noveno|decimo|undecimo|duodecimo)\s+traste\b/i.test(normalizedTrimmed);

            if (hasCapoPrefix || hasCapoKeyword || hasCapoOrdinal) {
                let candidate = "";

                const match = trimmed.match(/(?:CEJILLA\/CAPO|CEJILLA|CAPO)\s*:\s*(.+)/i) ||
                              trimmed.match(/\bcapo\s+(.+?)(?:\s*$|\.|\||para)/i);
                if (match) {
                    candidate = match[1].trim();
                } else {
                    const ordinalMatch = normalizedTrimmed.match(/\b(?:con\s+)?(?:cejilla|capo)\s+en\s+el\s+(primer|primero|segundo|tercer|tercero|cuarto|quinto|sexto|septimo|octavo|noveno|decimo|undecimo|duodecimo)\s+traste\b/i);
                    if (ordinalMatch) {
                        candidate = capoOrdinals[ordinalMatch[1].toLowerCase()] || "";
                    }
                }

                if (candidate) {
                    capoCandidates.push(candidate);
                }
            } else {
                cleanLines.push(line);
            }
        });

        const positiveCapo = capoCandidates.find((candidate) => {
            const parsed = parseCapoValue(candidate);
            return parsed !== null && parsed > 0;
        });
        const fallbackCapo = capoCandidates.find((candidate) => parseCapoValue(candidate) !== null) || "";
        const capoText = positiveCapo || fallbackCapo;

        return {
            capo: capoText,
            cleanText: cleanLines.join("\n")
        };
    }

    function highlightSections(text) {
        if (!text) {
            return text;
        }

        const lines = text.split("\n");
        const sectionPattern = /^\s*(\[?(?:INTRO|VERSO|ESTROFA|ESTRIBILLO|PUENTE|BRIDGE|OUTRO)\]?)\s*$/i;

        return lines.map((line) => {
            if (sectionPattern.test(line)) {
                const sectionName = line.trim();
                return `\n>>> ${sectionName} <<<\n`;
            }
            return line;
        }).join("\n");
    }

    const CACHE_BUSTER = `v=${Date.now()}`;

    const withCacheBuster = (path) => {
        const separator = path.includes("?") ? "&" : "?";
        return `${path}${separator}${CACHE_BUSTER}`;
    };

    const fileUrl = (filename) => withCacheBuster(`partituras/${encodeURIComponent(filename)}`);

    function loadFavoriteIds() {
        try {
            const raw = localStorage.getItem(STORAGE_KEYS.favorites);
            if (!raw) {
                return [];
            }
            const parsed = JSON.parse(raw);
            return Array.isArray(parsed) ? parsed : [];
        } catch {
            return [];
        }
    }

    function saveFavoriteIds() {
        localStorage.setItem(STORAGE_KEYS.favorites, JSON.stringify(Array.from(favoriteIds)));
    }

    function normalizeInstrumentList(value) {
        if (Array.isArray(value)) {
            return value.filter((instrument, index, array) => {
                return INSTRUMENT_LABELS[instrument] && array.indexOf(instrument) === index;
            });
        }

        if (typeof value === "string" && INSTRUMENT_LABELS[value] && value !== "sin-definir") {
            return [value];
        }

        return [];
    }

    function normalizeProfileData(profile) {
        const normalizedProfile = profile && typeof profile === "object" ? profile : {};
        const rawTuning = normalizedProfile.tuning ?? "";
        const capo = normalizedProfile.capo ?? "";
        const bpm = normalizedProfile.bpm ?? "";
        const key = normalizedProfile.key ?? "";
        const timeSignature = normalizedProfile.timeSignature ?? "";
        const techniques = Array.isArray(normalizedProfile.techniques) ? normalizedProfile.techniques.filter(Boolean) : [];
        const chords = Array.isArray(normalizedProfile.chords) ? normalizedProfile.chords.filter(Boolean) : [];
        
        return {
            instruments: normalizeInstrumentList(normalizedProfile.instruments ?? normalizedProfile.instrument),
            rating: Number.isInteger(normalizedProfile.rating) ? Math.max(0, Math.min(5, normalizedProfile.rating)) : 0,
            tuning: Object.prototype.hasOwnProperty.call(TUNING_LABELS, rawTuning) ? rawTuning : "",
            capo: String(capo).trim(),
            bpm: String(bpm).trim(),
            key: String(key).trim(),
            timeSignature: String(timeSignature).trim(),
            techniques: techniques,
            chords: chords
        };
    }

    function loadSongProfiles() {
        try {
            const raw = localStorage.getItem(STORAGE_KEYS.songProfiles);
            if (!raw) {
                return {};
            }

            const parsed = JSON.parse(raw);
            if (!parsed || typeof parsed !== "object") {
                return {};
            }

            return Object.fromEntries(Object.entries(parsed).map(([songId, profile]) => {
                return [songId, normalizeProfileData(profile)];
            }));
        } catch {
            return {};
        }
    }

    function saveSongProfiles() {
        localStorage.setItem(STORAGE_KEYS.songProfiles, JSON.stringify(songProfiles));
    }

    async function loadSharedProfiles() {
        try {
            const response = await fetch("partituras/song-profiles.json");
            if (response.ok) {
                const data = await response.json();
                if (data && typeof data === "object") {
                    seedSongProfiles = Object.fromEntries(
                        Object.entries(data).map(([songId, profile]) => [
                            songId,
                            normalizeProfileData(profile)
                        ])
                    );
                }
            }
        } catch {
            // Si no existe el archivo, simplemente no cargamos nada
        }
    }

    function exportProfilesToJson() {
        const exportData = {
            songProfiles,
            favorites: Array.from(favoriteIds),
            fontSize: fontSizeRem,
            searchHistory: loadSearchHistory(),
            exportDate: new Date().toISOString()
        };
        return JSON.stringify(exportData, null, 2);
    }

    function downloadJSON(filename, jsonContent) {
        const element = document.createElement("a");
        element.setAttribute("href", "data:application/json;charset=utf-8," + encodeURIComponent(jsonContent));
        element.setAttribute("download", filename);
        element.style.display = "none";
        document.body.appendChild(element);
        element.click();
        document.body.removeChild(element);
    }

    function importProfilesFromJson(jsonContent) {
        try {
            const data = JSON.parse(jsonContent);
            if (!data || typeof data !== "object") {
                alert("Formato de archivo inválido.");
                return false;
            }

            // Restaurar perfiles de canciones
            if (data.songProfiles && typeof data.songProfiles === "object") {
                Object.entries(data.songProfiles).forEach(([songId, profile]) => {
                    songProfiles[songId] = normalizeProfileData(profile);
                });
                saveSongProfiles();
            }

            // Mensaje informativo sobre nuevo formato
            if (data.songProfiles && Object.keys(data.songProfiles).length > 0) {
                console.log("Perfiles importados con soporte para: capo, BPM, técnicas, clave y compás");
            }

            // Restaurar favoritas
            if (Array.isArray(data.favorites)) {
                favoriteIds.clear();
                data.favorites.forEach((id) => favoriteIds.add(id));
                saveFavoriteIds();
            }

            // Restaurar historial de búsqueda
            if (Array.isArray(data.searchHistory)) {
                try {
                    localStorage.setItem(STORAGE_KEYS.searchHistory, JSON.stringify(data.searchHistory));
                } catch {
                    // Ignorar si no se puede guardar
                }
            }

            // Actualizar UI
            updateProfileBadge();
            updateFavoritesBadge();
            renderSongList(searchInput.value);

            alert("Datos importados correctamente.");
            return true;
        } catch (error) {
            alert("Error al importar: " + error.message);
            return false;
        }
    }

    function loadFilterMode() {
        const raw = localStorage.getItem(STORAGE_KEYS.filterMode);
        return raw === "favorites" ? "favorites" : "all";
    }

    function saveFilterMode() {
        localStorage.setItem(STORAGE_KEYS.filterMode, filterMode);
    }

    function loadInstrumentFilter() {
        const raw = localStorage.getItem(STORAGE_KEYS.instrumentFilter);
        return raw && INSTRUMENT_LABELS[raw] ? raw : "all";
    }

    function saveInstrumentFilter() {
        localStorage.setItem(STORAGE_KEYS.instrumentFilter, instrumentFilterValue);
    }

    function loadRatingFilter() {
        const raw = Number(localStorage.getItem(STORAGE_KEYS.ratingFilter));
        if (!Number.isInteger(raw) || raw < 0 || raw > 5) {
            return 0;
        }
        return raw;
    }

    function saveRatingFilter() {
        localStorage.setItem(STORAGE_KEYS.ratingFilter, String(ratingFilterValue));
    }

    function loadTuningFilter() {
        const raw = localStorage.getItem(STORAGE_KEYS.tuningFilter);
        const valid = ["all", "estandar", "medio-tono-abajo", "tono-abajo", "drop-d", "drop-c", "sin-definir"];
        return valid.includes(raw) ? raw : "all";
    }

    function saveTuningFilter() {
        localStorage.setItem(STORAGE_KEYS.tuningFilter, tuningFilterValue);
    }

    function loadCapoFilter() {
        const raw = localStorage.getItem(STORAGE_KEYS.capoFilter);
        const valid = ["all", "sin-cejilla", "1-2", "3-plus", "sin-definir"];
        return valid.includes(raw) ? raw : "all";
    }

    function saveCapoFilter() {
        localStorage.setItem(STORAGE_KEYS.capoFilter, capoFilterValue);
    }

    function loadTechniqueFilter() {
        const raw = localStorage.getItem(STORAGE_KEYS.techniqueFilter);
        return raw || "all";
    }

    function saveTechniqueFilter() {
        localStorage.setItem(STORAGE_KEYS.techniqueFilter, techniqueFilterValue);
    }

    function loadKeyFilter() {
        const raw = localStorage.getItem(STORAGE_KEYS.keyFilter);
        return raw || "all";
    }

    function saveKeyFilter() {
        localStorage.setItem(STORAGE_KEYS.keyFilter, keyFilterValue);
    }

    function loadTimeSignatureFilter() {
        const raw = localStorage.getItem(STORAGE_KEYS.timeSignatureFilter);
        return raw || "all";
    }

    function saveTimeSignatureFilter() {
        localStorage.setItem(STORAGE_KEYS.timeSignatureFilter, timeSignatureFilterValue);
    }

    function resetAllFilters() {
        filterMode = "all";
        instrumentFilterValue = "all";
        ratingFilterValue = 0;
        tuningFilterValue = "all";
        capoFilterValue = "all";
        techniqueFilterValue = "all";
        keyFilterValue = "all";
        timeSignatureFilterValue = "all";

        searchInput.value = "";
        hideSearchSuggestions();

        instrumentFilter.value = instrumentFilterValue;
        ratingFilter.value = String(ratingFilterValue);
        tuningFilter.value = tuningFilterValue;
        capoFilter.value = ensureSelectValue(capoFilter, capoFilterValue, "all");
        techniqueFilter.value = ensureSelectValue(techniqueFilter, techniqueFilterValue, "all");
        keyFilter.value = ensureSelectValue(keyFilter, keyFilterValue, "all");
        timeSignatureFilter.value = ensureSelectValue(timeSignatureFilter, timeSignatureFilterValue, "all");

        saveFilterMode();
        saveInstrumentFilter();
        saveRatingFilter();
        saveTuningFilter();
        saveCapoFilter();
        saveTechniqueFilter();
        saveKeyFilter();
        saveTimeSignatureFilter();

        updateFilterButtons();
        renderSongList("");
        updateFilterCounters();
    }

    function loadSortColumn() {
        const raw = localStorage.getItem(STORAGE_KEYS.sortColumn);
        const valid = ["artist", "title", "rating"];
        return valid.includes(raw) ? raw : "artist";
    }

    function loadSortDirection() {
        const raw = localStorage.getItem(STORAGE_KEYS.sortDirection);
        return raw === "desc" ? "desc" : "asc";
    }

    function saveSortSettings() {
        localStorage.setItem(STORAGE_KEYS.sortColumn, sortColumn);
        localStorage.setItem(STORAGE_KEYS.sortDirection, sortDirection);
    }

    function ensureSelectValue(select, value, fallback = "all") {
        const exists = Array.from(select.options).some((option) => option.value === value);
        return exists ? value : fallback;
    }

    function populateSelect(select, values, labelResolver) {
        const preservedValue = select.value;
        const defaults = Array.from(select.querySelectorAll("option")).filter((option) => {
            return option.value === "all" || option.value === "sin-definir";
        });

        select.innerHTML = "";
        defaults.forEach((option) => select.appendChild(option));

        values.forEach((value) => {
            const option = document.createElement("option");
            option.value = value;
            option.textContent = labelResolver(value);
            select.appendChild(option);
        });

        select.value = ensureSelectValue(select, preservedValue, "all");
    }

    function parseCapoValue(rawCapo) {
        if (rawCapo === null || rawCapo === undefined || rawCapo === "") {
            return null;
        }

        if (typeof rawCapo === "number" && Number.isFinite(rawCapo)) {
            const val = Math.round(rawCapo);
            return val > 0 && val <= 12 ? val : null; // Capo válido: 1-12
        }

        const match = String(rawCapo).match(/\d+/);
        if (!match) {
            return null;
        }

        const parsed = Number(match[0]);
        if (!Number.isFinite(parsed)) return null;
        
        // Solo aceptar capo entre 1 y 12 (rango válido de guitarra)
        return parsed > 0 && parsed <= 12 ? parsed : null;
    }

    function extractChords(rawText) {
        if (!rawText) return [];
        
        // Regex para detectar acordes: A, C#m, Bb7, Dm7/G, etc
        const chordPattern = /\b([A-G](?:[#b])?(?:maj|min|m|M|7|9|sus|add|dim|aug)?[0-9]*(?:\/[A-G](?:[#b])?)?)\b/g;
        const matches = rawText.match(chordPattern) || [];
        
        // Excluir palabras que podrían ser falsas positivas
        const excludeWords = /^(and|add|but|lab|mag|meg|the|may|ban|bad|bad|bag|bar|bat|bed|ben|bit|bob|bog|boy|bus|but|dam|dan|dec|del|den|dig|div|doc|dog|don|due|duh|dud|feb|fed|few|fig|fin|fit|fog|for|gap|gas|gay|get|god|got|gum|gun|gym|had|ham|has|hat|hay|hem|her|hid|him|hip|his|hit|hog|hot|how|how|hub|hue|hug|hum|i'm|icy|ill|ink|inn|ion|its|jab|jam|jar|jaw|jay|jet|job|jog|joy|jug|key|kid|kin|kit|lab|lad|lag|lap|law|lay|leg|let|lid|lie|lip|lit|log|lot|low|mac|mad|mag|man|map|mar|mat|max|may|men|met|mid|mix|mob|mom|mop|mud|mug|nag|nap|net|new|nod|nor|not|now|nut|oak|oar|odd|off|oil|old|one|ore|our|out|owe|owl|own|pad|pal|pan|par|pat|paw|pay|pea|peg|pen|per|pet|pie|pig|pin|pit|pod|pop|pot|pow|pry|pub|pup|put|rad|rag|ram|ran|rap|rat|raw|ray|red|rid|rig|rim|rip|rob|rod|roe|rot|row|rub|rug|run|rut|sad|sag|sat|saw|say|sea|see|set|sex|she|shy|sin|sip|sir|sis|sit|six|ski|sky|sly|sob|sop|spa|spy|sub|sum|sun|tab|tad|tag|tan|tap|tar|tat|tax|tea|ten|the|tie|tin|tip|tmp|toe|ton|too|tow|toy|try|tub|tug|two|urn|use|van|vet|vow|wad|wag|war|was|wax|way|web|wed|wee|wet|who|why|wig|win|wit|woe|won|woo|yes|yet|you|zip|zoo)$/i;
        
        // Contar frequencia de cada acorde (normalizado)
        const chordFrequency = {};
        matches.forEach(chord => {
            if (!chord.match(excludeWords)) {
                // Normalizar: AM -> Am, FM -> Fm, CM7 -> Cm7, etc
                const normalized = chord.replace(/M/g, 'm');
                
                chordFrequency[normalized] = (chordFrequency[normalized] || 0) + 1;
            }
        });
        
        // Ordenar por frequencia (más repetidos primero)
        const sortedChords = Object.entries(chordFrequency)
            .sort((a, b) => b[1] - a[1])  // Orden descendente por frequencia
            .map(entry => entry[0]);      // Extraer solo los acordes
        
        return sortedChords;
    }

    function populateDynamicFilters() {
        const availableTechniques = Array.from(
            new Set(
                songs
                    .flatMap((song) => (Array.isArray(song.techniques) ? song.techniques : []))
                    .filter(Boolean)
            )
        ).sort((a, b) => {
            const labelA = TECHNIQUE_LABELS[a] || a;
            const labelB = TECHNIQUE_LABELS[b] || b;
            return labelA.localeCompare(labelB, "es");
        });

        const availableKeys = Array.from(
            new Set(
                songs
                    .map((song) => (typeof song.key === "string" ? song.key.trim() : ""))
                    .filter(Boolean)
            )
        ).sort((a, b) => a.localeCompare(b, "es"));

        const availableTimeSignatures = Array.from(
            new Set(
                songs
                    .map((song) => (typeof song.timeSignature === "string" ? song.timeSignature.trim() : ""))
                    .filter(Boolean)
            )
        ).sort((a, b) => a.localeCompare(b, "es"));

        populateSelect(techniqueFilter, availableTechniques, (value) => TECHNIQUE_LABELS[value] || value);
        populateSelect(keyFilter, availableKeys, (value) => value);
        populateSelect(timeSignatureFilter, availableTimeSignatures, (value) => value);
    }

    function loadFontSize() {
        const raw = Number(localStorage.getItem(STORAGE_KEYS.fontSize));
        if (!Number.isFinite(raw)) {
            return 0.92;
        }
        return Math.max(0.72, Math.min(1.4, raw));
    }

    function saveFontSize() {
        localStorage.setItem(STORAGE_KEYS.fontSize, String(fontSizeRem));
    }

    function setSongFontSize() {
        songBody.style.fontSize = `${fontSizeRem.toFixed(2)}rem`;
    }

    function updateProtocolNotice() {
        if (!protocolNotice) {
            return;
        }

        const isLocalFile = window.location.protocol === "file:";
        protocolNotice.classList.toggle("d-none", !isLocalFile);
    }

    function hideSearchSuggestions() {
        searchSuggestionItems = [];
        activeSuggestionIndex = -1;
        searchSuggestions.innerHTML = "";
        searchSuggestions.classList.add("d-none");
        searchInput.setAttribute("aria-expanded", "false");
        searchInput.removeAttribute("aria-activedescendant");
    }

    function updateSuggestionHighlight() {
        const buttons = Array.from(searchSuggestions.querySelectorAll(".search-suggestion"));
        buttons.forEach((button, index) => {
            button.classList.toggle("is-active", index === activeSuggestionIndex);
        });

        if (activeSuggestionIndex >= 0 && buttons[activeSuggestionIndex]) {
            const activeId = buttons[activeSuggestionIndex].id;
            searchInput.setAttribute("aria-activedescendant", activeId);
            buttons[activeSuggestionIndex].scrollIntoView({ block: "nearest" });
        } else {
            searchInput.removeAttribute("aria-activedescendant");
        }
    }

    function buildSearchSuggestions(rawQuery) {
        const query = normalize(rawQuery.trim());
        if (!query) {
            // Mostrar historial de búsquedas si no hay búsqueda activa
            const history = loadSearchHistory();
            if (history.length > 0) {
                return history.slice(0, 6).map((item) => ({
                    type: "history",
                    label: item,
                    meta: "Búsqueda anterior",
                    value: item
                }));
            }
            return [];
        }

        const matchingSongs = songs.filter((song) => matchesCurrentFilters(song, query));
        const songSuggestions = matchingSongs.slice(0, 6).map((song) => ({
            type: "song",
            label: song.title,
            meta: song.artist,
            value: song.title,
            songId: song.id
        }));

        const seenArtists = new Set();
        const artistSuggestions = [];
        matchingSongs.forEach((song) => {
            const artistKey = normalize(song.artist);
            if (!artistKey.includes(query) || seenArtists.has(artistKey)) {
                return;
            }

            seenArtists.add(artistKey);
            artistSuggestions.push({
                type: "artist",
                label: song.artist,
                meta: "Artista",
                value: song.artist
            });
        });

        return [...artistSuggestions.slice(0, 4), ...songSuggestions].slice(0, 8);
    }

    function loadSearchHistory() {
        try {
            const raw = localStorage.getItem(STORAGE_KEYS.searchHistory);
            return raw ? JSON.parse(raw) : [];
        } catch {
            return [];
        }
    }

    function saveSearchHistory(query) {
        if (!query || query.trim().length === 0) return;
        const clean = query.trim();
        let history = loadSearchHistory();
        // Eliminar duplicados y mover el más reciente arriba
        history = history.filter((item) => normalize(item) !== normalize(clean));
        history.unshift(clean);
        // Mantener solo los últimos 15
        history = history.slice(0, 15);
        try {
            localStorage.setItem(STORAGE_KEYS.searchHistory, JSON.stringify(history));
        } catch {
            // Ignorar errores de localStorage
        }
    }

    function clearSearchHistory() {
        localStorage.removeItem(STORAGE_KEYS.searchHistory);
        hideSearchSuggestions();
    }

    function renderSearchSuggestions(rawQuery) {
        const nextSuggestions = buildSearchSuggestions(rawQuery);
        searchSuggestionItems = nextSuggestions;
        activeSuggestionIndex = -1;
        searchSuggestions.innerHTML = "";

        if (nextSuggestions.length === 0) {
            hideSearchSuggestions();
            return;
        }

        nextSuggestions.forEach((suggestion, index) => {
            const button = document.createElement("button");
            button.type = "button";
            button.className = "search-suggestion";
            button.id = `search-suggestion-${index}`;
            button.setAttribute("role", "option");
            button.dataset.index = String(index);

            const label = document.createElement("span");
            label.className = "search-suggestion-label";
            label.textContent = suggestion.label;

            const meta = document.createElement("span");
            meta.className = "search-suggestion-meta";
            meta.textContent = suggestion.meta;
            if (suggestion.type === "history") {
                meta.classList.add("history-meta");
            }

            button.appendChild(label);
            button.appendChild(meta);

            button.addEventListener("pointerdown", (event) => {
                event.preventDefault();
                applySuggestion(index);
            });

            searchSuggestions.appendChild(button);
        });

        searchSuggestions.classList.remove("d-none");
        searchInput.setAttribute("aria-expanded", "true");
    }

    function applySuggestion(index) {
        const suggestion = searchSuggestionItems[index];
        if (!suggestion) {
            return;
        }

        searchInput.value = suggestion.value;
        saveSearchHistory(suggestion.value);
        renderSongList(suggestion.value);
        hideSearchSuggestions();

        if (suggestion.type === "song" && suggestion.songId) {
            const song = findSongById(suggestion.songId);
            if (song) {
                loadSong(song);
            }
        }
    }

    function updateFavoritesBadge() {
        favoritesBadge.textContent = `Favoritas: ${favoriteIds.size}`;
    }

    function updateProfileBadge() {
        const songIds = new Set([...Object.keys(seedSongProfiles), ...Object.keys(songProfiles)]);
        let completedProfiles = 0;

        songIds.forEach((songId) => {
            const profile = getSongProfile(songId);
            if (profile.instruments.length > 0 || profile.rating > 0) {
                completedProfiles += 1;
            }
        });

        profileBadge.textContent = `Perfiles: ${completedProfiles}`;
    }

    function getSongProfile(songId) {
        if (Object.prototype.hasOwnProperty.call(songProfiles, songId)) {
            return normalizeProfileData(songProfiles[songId]);
        }

        return normalizeProfileData(seedSongProfiles[songId]);
    }

    function saveSongProfileWithDetectedChords(songId, nextProfile) {
        const currentSong = findSongById(songId);
        const detectedChords = (currentSong && currentSong.detectedChords) ? currentSong.detectedChords : [];
        
        const profileToSave = {
            ...nextProfile,
            chords: nextProfile.chords || detectedChords
        };
        
        saveSongProfile(songId, profileToSave);
    }

    function saveSongProfile(songId, nextProfile) {
        const rawTuning = nextProfile.tuning ?? "";
        songProfiles[songId] = {
            instruments: normalizeInstrumentList(nextProfile.instruments),
            rating: Number.isInteger(nextProfile.rating) ? Math.max(0, Math.min(5, nextProfile.rating)) : 0,
            tuning: Object.prototype.hasOwnProperty.call(TUNING_LABELS, rawTuning) ? rawTuning : "",
            capo: String(nextProfile.capo ?? "").trim(),
            bpm: String(nextProfile.bpm ?? "").trim(),
            key: String(nextProfile.key ?? "").trim(),
            timeSignature: String(nextProfile.timeSignature ?? "").trim(),
            techniques: Array.isArray(nextProfile.techniques) ? nextProfile.techniques.filter(Boolean) : [],
            chords: Array.isArray(nextProfile.chords) ? nextProfile.chords.filter(Boolean) : []
        };

        saveSongProfiles();
        updateProfileBadge();
    }

    function formatRatingStars(rating) {
        const active = "★".repeat(rating);
        const empty = "☆".repeat(5 - rating);
        return `${active}${empty}`;
    }

    function renderActiveSongProfile() {
        if (!activeSongId) {
            songInstrumentInputs.forEach((input) => {
                input.checked = false;
            });
            songRatingLabel.textContent = RATING_LABELS[0];
            renderRatingButtons(0);
            songTuning.value = "";
            return;
        }

        const profile = getSongProfile(activeSongId);
        songInstrumentInputs.forEach((input) => {
            input.checked = profile.instruments.includes(input.value);
        });
        songRatingLabel.textContent = RATING_LABELS[profile.rating];
        renderRatingButtons(profile.rating);
        songTuning.value = profile.tuning;
    }

    function renderRatingButtons(currentRating) {
        songRating.innerHTML = "";

        for (let value = 1; value <= 5; value += 1) {
            const button = document.createElement("button");
            button.type = "button";
            button.className = "rating-star";
            button.textContent = value <= currentRating ? "★" : "☆";
            button.classList.toggle("is-active", value <= currentRating);
            button.setAttribute("aria-label", `Valorar con ${value} estrellas`);
            button.addEventListener("click", () => {
                if (!activeSongId) {
                    return;
                }

                const profile = getSongProfile(activeSongId);
                const nextRating = profile.rating === value ? 0 : value;
                saveSongProfileWithDetectedChords(activeSongId, {
                    instruments: profile.instruments,
                    rating: nextRating,
                    tuning: profile.tuning,
                    capo: profile.capo,
                    bpm: profile.bpm,
                    key: profile.key,
                    timeSignature: profile.timeSignature,
                    techniques: profile.techniques
                });
                renderActiveSongProfile();
                renderSongList(searchInput.value);
            });
            songRating.appendChild(button);
        }
    }

    function updateFilterButtons() {
        const isFavorites = filterMode === "favorites";

        filterAll.classList.toggle("btn-dark", !isFavorites);
        filterAll.classList.toggle("btn-outline-dark", isFavorites);

        filterFavorites.classList.toggle("btn-dark", isFavorites);
        filterFavorites.classList.toggle("btn-outline-dark", !isFavorites);
    }

    function findSongById(id) {
        return songs.find((song) => song.id === id) || null;
    }

    function matchesCurrentFilters(song, query) {
        const profile = getSongProfile(song.id);
        const hasNoInstrument = profile.instruments.length === 0;

        if (filterMode === "favorites" && !favoriteIds.has(song.id)) {
            return false;
        }

        if (instrumentFilterValue !== "all") {
            if (instrumentFilterValue === "sin-definir") {
                if (!hasNoInstrument) {
                    return false;
                }
            } else if (!profile.instruments.includes(instrumentFilterValue)) {
                return false;
            }
        }

        if (profile.rating < ratingFilterValue) {
            return false;
        }

        if (tuningFilterValue !== "all") {
            if (tuningFilterValue === "sin-definir") {
                if (profile.tuning !== "") {
                    return false;
                }
            } else if (profile.tuning !== tuningFilterValue) {
                return false;
            }
        }

        if (!query) {
            return true;
        }

        const instrumentText = hasNoInstrument
            ? INSTRUMENT_LABELS["sin-definir"]
            : profile.instruments.map((instrument) => INSTRUMENT_LABELS[instrument]).join(" ");
        const tuningText = TUNING_LABELS[profile.tuning] || TUNING_LABELS[""];
        const haystack = normalize(`${song.artist} ${song.title} ${song.filename} ${instrumentText} ${tuningText}`);
        return haystack.includes(query);
    }

    function renderSongList(filterText = "") {
        const query = normalize(filterText.trim());
        let filteredSongs = songs.filter((song) => matchesCurrentFilters(song, query));

        // Aplicar ordenamiento
        filteredSongs = sortSongs(filteredSongs);

        songList.innerHTML = "";
        songCount.textContent = String(filteredSongs.length);

        if (activeSongId) {
            const activeSong = findSongById(activeSongId);
            if (!activeSong || !matchesCurrentFilters(activeSong, query)) {
                activeSongId = "";
                hideSongPanel();
            }
        }

        if (filteredSongs.length === 0) {
            const emptyItem = document.createElement("div");
            emptyItem.className = "text-center opacity-75 p-4";
            emptyItem.textContent = filterMode === "favorites"
                ? "No hay favoritas con ese filtro."
                : "No hay canciones que coincidan con la busqueda y los filtros.";
            songList.appendChild(emptyItem);
            return;
        }

        filteredSongs.forEach((song) => {
            const profile = getSongProfile(song.id);
            const instrumentTags = profile.instruments.length === 0
                ? [`<span class="song-tag">${INSTRUMENT_LABELS["sin-definir"]}</span>`]
                : profile.instruments.map((instrument) => `<span class="song-tag">${INSTRUMENT_LABELS[instrument]}</span>`);
            const tuningTag = profile.tuning ? `<span class="song-tag tuning-tag">${TUNING_LABELS[profile.tuning]}</span>` : "";
            const techniqueTags = song.techniques && song.techniques.length > 0
                ? song.techniques.map((tech) => {
                    const label = TECHNIQUE_LABELS[tech] || tech;
                    const badgeClass = tech === "barre-chords" ? "technique-tag technique-tag-barre" : "technique-tag";
                    return `<span class="${badgeClass}">${label}</span>`;
                }).join("")
                : "";
            
            // Mostrar acordes detectados (limitados a 4 principales)
            const detectedChords = song.detectedChords && Array.isArray(song.detectedChords) 
                ? song.detectedChords.slice(0, 4).join(", ") 
                : "";
            const chordTag = detectedChords 
                ? `<span class="song-tag chord-tag" title="Acordes: ${song.detectedChords.join(', ')}">${detectedChords}</span>`
                : "";
            
            const row = document.createElement("div");
            row.className = "song-row";

            const button = document.createElement("button");
            button.type = "button";
            button.className = "list-group-item list-group-item-action song-item";
            button.dataset.songId = song.id;
            if (song.id === activeSongId) {
                button.classList.add("active");
            }

            button.innerHTML = `
                <div class="song-item-main">
                    <div class="fw-semibold">${song.title}</div>
                    <div class="song-meta">${song.artist}</div>
                    <div class="song-tags">
                        ${chordTag}
                        ${instrumentTags.join("")}
                        ${tuningTag}
                        ${techniqueTags}
                        <span class="song-tag rating-tag">${formatRatingStars(profile.rating)}</span>
                    </div>
                </div>
            `;

            const favoriteButton = document.createElement("button");
            favoriteButton.type = "button";
            favoriteButton.className = "btn btn-sm favorite-toggle";
            favoriteButton.setAttribute("aria-label", `Marcar favorita ${song.title}`);
            favoriteButton.textContent = favoriteIds.has(song.id) ? "★" : "☆";
            favoriteButton.classList.toggle("is-favorite", favoriteIds.has(song.id));

            favoriteButton.addEventListener("click", (event) => {
                event.stopPropagation();
                toggleFavorite(song.id);
            });

            button.addEventListener("click", () => loadSong(song));

            row.appendChild(button);
            row.appendChild(favoriteButton);
            songList.appendChild(row);
        });
    }

    function sortSongs(songsToSort) {
        const sorted = [...songsToSort];
        
        sorted.sort((a, b) => {
            let aValue, bValue;
            
            if (sortColumn === "artist") {
                aValue = normalize(a.artist);
                bValue = normalize(b.artist);
            } else if (sortColumn === "title") {
                aValue = normalize(a.title);
                bValue = normalize(b.title);
            } else if (sortColumn === "rating") {
                const profileA = getSongProfile(a.id);
                const profileB = getSongProfile(b.id);
                aValue = profileA.rating;
                bValue = profileB.rating;
            } else {
                return 0;
            }
            
            if (aValue < bValue) return sortDirection === "asc" ? -1 : 1;
            if (aValue > bValue) return sortDirection === "asc" ? 1 : -1;
            return 0;
        });
        
        return sorted;
    }

    function countSongsForFilter(propertyName, filterValue) {
        return songs.filter((song) => {
            const profile = getSongProfile(song.id);
            
            switch (propertyName) {
                case "capo":
                    if (filterValue === "all") return true;
                    if (filterValue === "sin-cejilla") {
                        const capoValue = parseCapoValue(song.capo);
                        return capoValue === null || capoValue <= 0;
                    }
                    if (filterValue === "1-2") {
                        const capoValue = parseCapoValue(song.capo);
                        return capoValue !== null && capoValue >= 1 && capoValue <= 2;
                    }
                    if (filterValue === "3-plus") {
                        const capoValue = parseCapoValue(song.capo);
                        return capoValue !== null && capoValue >= 3;
                    }
                    return false;
                case "tuning":
                    if (filterValue === "all") return true;
                    if (filterValue === "sin-definir") return profile.tuning === "";
                    return profile.tuning === filterValue;
                case "technique":
                    if (filterValue === "all") return true;
                    if (filterValue === "sin-definir") return !song.techniques || song.techniques.length === 0;
                    return song.techniques && song.techniques.includes(filterValue);
                default:
                    return true;
            }
        }).length;
    }

    function updateFilterCounters() {
        // Actualizar contador de cejilla
        const capoOptions = [
            { value: "sin-cejilla", label: "Sin cejilla" },
            { value: "1-2", label: "Cejilla 1-2" },
            { value: "3-plus", label: "Cejilla 3+" }
        ];
        
        capoOptions.forEach((opt) => {
            const count = countSongsForFilter("capo", opt.value);
            const option = Array.from(capoFilter.options).find((o) => o.value === opt.value);
            if (option) {
                option.textContent = `${opt.label} (${count})`;
            }
        });
        
        // Actualizar contador de afinación
        const tuningOptions = [
            { value: "estandar", label: "Estandar" },
            { value: "medio-tono-abajo", label: "Medio tono abajo" },
            { value: "tono-abajo", label: "Tono abajo" },
            { value: "drop-d", label: "Drop D" },
            { value: "drop-c", label: "Drop C" },
            { value: "sin-definir", label: "Sin definir" }
        ];
        
        tuningOptions.forEach((opt) => {
            const count = countSongsForFilter("tuning", opt.value);
            const option = Array.from(tuningFilter.options).find((o) => o.value === opt.value);
            if (option) {
                option.textContent = `${opt.label} (${count})`;
            }
        });
    }

    function toggleFavorite(songId) {
        if (favoriteIds.has(songId)) {
            favoriteIds.delete(songId);
        } else {
            favoriteIds.add(songId);
        }

        saveFavoriteIds();
        updateFavoritesBadge();

        if (filterMode === "favorites") {
            const activeSongIsFavorite = activeSongId && favoriteIds.has(activeSongId);
            if (!activeSongIsFavorite) {
                activeSongId = "";
                hideSongPanel();
            }
        }

        renderSongList(searchInput.value);
    }

    function stopAutoscroll() {
        if (autoscrollTimer) {
            window.clearInterval(autoscrollTimer);
            autoscrollTimer = null;
        }
        autoscrollToggle.textContent = "Iniciar";
        autoscrollToggle.classList.remove("btn-danger");
        autoscrollToggle.classList.add("btn-outline-secondary");
    }

    function startAutoscroll() {
        stopAutoscroll();
        const speed = Number(autoscrollSpeed.value);
        autoscrollTimer = window.setInterval(() => {
            songBody.scrollTop += speed;
        }, 200);

        autoscrollToggle.textContent = "Parar";
        autoscrollToggle.classList.remove("btn-outline-secondary");
        autoscrollToggle.classList.add("btn-danger");
    }

    function updateTransposeBadge() {
        const sign = transposeShift > 0 ? "+" : "";
        transposeBadge.textContent = `Transposicion: ${sign}${transposeShift}`;
    }

    function normalizeShift(shift) {
        if (shift > 6) {
            return shift - 12;
        }
        if (shift < -6) {
            return shift + 12;
        }
        return shift;
    }

    function transposeNote(note, shift, preferFlats) {
        const index = NOTE_TO_INDEX[note];
        if (index === undefined) {
            return note;
        }

        const moved = (index + shift + 12) % 12;
        const chromatic = preferFlats ? FLAT_NOTES : SHARP_NOTES;
        return chromatic[moved];
    }

    function transposeChordToken(token, shift) {
        const chordPattern = /^([A-G](?:#|b)?)(maj|min|m|sus|dim|aug|add)?([0-9+#b()]*)?(?:\/([A-G](?:#|b)?))?$/;
        const match = token.match(chordPattern);
        if (!match) {
            return token;
        }

        const [, root, quality = "", extension = "", bass] = match;
        const useFlats = root.includes("b") || (bass && bass.includes("b"));

        const newRoot = transposeNote(root, shift, useFlats);
        const newBass = bass ? transposeNote(bass, shift, useFlats) : "";

        return `${newRoot}${quality}${extension}${newBass ? `/${newBass}` : ""}`;
    }

    function applyTransposition(rawText) {
        if (!rawText) {
            return "";
        }

        if (transposeShift === 0) {
            return rawText;
        }

        return rawText
            .split("\n")
            .map((line) =>
                line
                    .split(/(\s+)/)
                    .map((chunk) => {
                        if (/^\s+$/.test(chunk)) {
                            return chunk;
                        }

                        const clean = chunk.replace(/^[|.,;:()\[\]{}]+|[|.,;:()\[\]{}]+$/g, "");
                        if (!clean) {
                            return chunk;
                        }

                        const transposed = transposeChordToken(clean, transposeShift);
                        if (transposed === clean) {
                            return chunk;
                        }

                        return chunk.replace(clean, transposed);
                    })
                    .join("")
            )
            .join("\n");
    }

    function highlightSections(text) {
        if (!text) {
            return text;
        }

        const SECTION_LABELS = {
            intro: "INTRO",
            verse: "VERSO",
            verso: "VERSO",
            estrofa: "ESTROFA",
            chorus: "ESTRIBILLO",
            estribillo: "ESTRIBILLO",
            "pre-chorus": "PRE-ESTRIBILLO",
            "pre-estribillo": "PRE-ESTRIBILLO",
            bridge: "PUENTE",
            puente: "PUENTE",
            outro: "OUTRO",
            solo: "SOLO",
            interlude: "INTERLUDIO",
            coda: "CODA"
        };

        const parseSectionLabel = (line) => {
            const raw = line.trim();
            if (!raw) {
                return "";
            }

            const cleaned = raw
                .replace(/^[\-*>#\s]+/, "")
                .replace(/^[_*`]+|[_*`]+$/g, "")
                .replace(/^\[(.+)\]$/, "$1")
                .trim();

            if (!cleaned) {
                return "";
            }

            const normalized = normalize(cleaned).replace(/\s+/g, " ").trim();
            const match = normalized.match(/^(intro|verse|verso|estrofa|chorus|estribillo|pre[- ]?chorus|pre[- ]?estribillo|bridge|puente|outro|solo|interlude|coda)(?:\s+(\d+))?$/i);
            if (!match) {
                return "";
            }

            const key = match[1].toLowerCase().replace(/\s+/g, "-");
            const number = match[2] ? ` ${match[2]}` : "";
            const baseLabel = SECTION_LABELS[key] || cleaned.toUpperCase();
            return `${baseLabel}${number}`;
        };

        const lines = text.split("\n");

        return lines.map((line) => {
            const sectionName = parseSectionLabel(line);
            if (sectionName) {
                return `|||SECTION_START|||${sectionName}|||SECTION_END|||`;
            }
            return line;
        }).join("\n");
    }

    function stripMarkdownMarkup(text) {
        if (!text) {
            return text;
        }

        const lines = text.split("\n");
        const result = [];
        let inCodeBlock = false;

        for (const line of lines) {
            // Eliminar marcadores de conflicto git
            if (/^(<{7}|={7}|>{7})/.test(line)) {
                continue;
            }

            // Detectar y eliminar líneas de valla de código (```)
            if (/^\s*`{3,}\s*$/.test(line)) {
                inCodeBlock = !inCodeBlock;
                continue;
            }

            // Eliminar líneas de regla horizontal (---, ***, ___)
            if (/^\s*[-*_]{3,}\s*$/.test(line)) {
                continue;
            }

            // Eliminar encabezados Markdown (# Título) quedándonos solo con el texto
            if (/^#{1,3}\s+/.test(line)) {
                const heading = line.replace(/^#{1,3}\s+/, "").trim();
                if (heading) {
                    result.push(heading);
                }
                continue;
            }

            // Quitar marcado **negrita** e *cursiva* pero preservar el texto
            const cleaned = line
                .replace(/\*\*\*(.+?)\*\*\*/g, "$1")
                .replace(/\*\*(.+?)\*\*/g, "$1")
                .replace(/\*(.+?)\*/g, "$1")
                .replace(/__(.+?)__/g, "$1")
                .replace(/_(.+?)_/g, "$1");

            result.push(cleaned);
        }

        return result.join("\n");
    }

    function renderSongBody() {
        const isMd = activeSongFilename.toLowerCase().endsWith(".md");
        const { cleanText } = extractCapoInfo(activeSongRawText);
        const stripped = isMd ? stripMarkdownMarkup(cleanText) : cleanText;
        const highlighted = highlightSections(stripped);
        const transposed = applyTransposition(highlighted);
        
        // Escapar HTML para seguridad, luego reemplazar marcadores con HTML
        songBody.innerHTML = transposed
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/\|\|\|SECTION_START\|\|\|(.+?)\|\|\|SECTION_END\|\|\|/g, '<span class="song-section">$1</span>');
    }

    function hideSongPanel() {
        emptyState.classList.remove("d-none");
        songView.classList.add("d-none");
        songBody.textContent = "";
        songTitle.textContent = "";
        songMeta.textContent = "";
        activeSongRawText = "";
        activeSongCapo = "";
        activeSongFilename = "";
        capoContainer.classList.add("d-none");
        bpmContainer.classList.add("d-none");
        techniquesContainer.classList.add("d-none");
        musicalInfoContainer.classList.add("d-none");
        renderActiveSongProfile();
        stopAutoscroll();
    }

    async function loadSong(song) {
        try {
            const response = await fetch(fileUrl(song.filename));
            if (!response.ok) {
                throw new Error(`HTTP ${response.status}`);
            }

            activeSongRawText = await response.text();
            
            // Detectar acordes del texto
            song.detectedChords = extractChords(activeSongRawText);
            
            // Reset capo ANTES d'extraer
            activeSongCapo = "";
            
            const { capo } = extractCapoInfo(activeSongRawText);
            const resolvedCapoValue = parseCapoValue(capo || song.capo);
            activeSongCapo = resolvedCapoValue && resolvedCapoValue > 0 ? String(resolvedCapoValue) : "";
            activeSongId = song.id;
            activeSongFilename = song.filename;

            songTitle.textContent = song.title;
            songMeta.textContent = song.artist;
            
            // Mostrar u ocultar la cejilla
            if (activeSongCapo) {
                songCapo.textContent = `Cejilla: ${activeSongCapo}`;
                capoContainer.classList.remove("d-none");
            } else {
                capoContainer.classList.add("d-none");
            }
            
            // Mostrar BPM si existe
            if (song.bpm) {
                songBpm.textContent = `${song.bpm} BPM`;
                bpmContainer.classList.remove("d-none");
            } else {
                bpmContainer.classList.add("d-none");
            }
            
            // Mostrar técnicas si existen
            if (song.techniques && song.techniques.length > 0) {
                songTechniques.innerHTML = song.techniques
                    .map((tech) => {
                        const label = TECHNIQUE_LABELS[tech] || tech;
                        const badgeClass = tech === "barre-chords" ? "text-bg-danger" : "text-bg-secondary";
                        return `<span class="badge ${badgeClass}">${label}</span>`;
                    })
                    .join("");
                techniquesContainer.classList.remove("d-none");
            } else {
                techniquesContainer.classList.add("d-none");
            }
            
            // Mostrar Tonalidad y Compás
            let hasMusicInfo = false;
            if (song.key) {
                songKey.textContent = song.key;
                keyContainer.classList.remove("d-none");
                hasMusicInfo = true;
            } else {
                keyContainer.classList.add("d-none");
            }
            
            if (song.timeSignature) {
                songTimeSignature.textContent = song.timeSignature;
                timeSignatureContainer.classList.remove("d-none");
                hasMusicInfo = true;
            } else {
                timeSignatureContainer.classList.add("d-none");
            }
            
            if (hasMusicInfo) {
                musicalInfoContainer.classList.remove("d-none");
            } else {
                musicalInfoContainer.classList.add("d-none");
            }
            
            renderSongBody();
            renderActiveSongProfile();

            emptyState.classList.add("d-none");
            songView.classList.remove("d-none");
            songBody.scrollTop = 0;

            const url = new URL(window.location.href);
            url.searchParams.set("song", song.id);
            window.history.replaceState({}, "", url);

            renderSongList(searchInput.value);
        } catch (error) {
            hideSongPanel();
            emptyState.querySelector(".card-body").innerHTML = `
                <div>
                    <h2 class="h4 mb-2">No se pudo abrir la cancion</h2>
                    <p class="mb-0 opacity-75">Si abriste el HTML con doble clic, prueba con un servidor local (por ejemplo Live Server en VS Code).</p>
                </div>
            `;

            console.error("Error loading song:", error);
        }
    }

    async function loadSongsIndex() {
        const response = await fetch(withCacheBuster("partituras/index.json"));
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }

        const data = await response.json();
        if (!Array.isArray(data)) {
            throw new Error("Invalid index format");
        }

        songs = data.map((song) => {
            const techniques = Array.isArray(song.techniques) ? song.techniques.filter(Boolean) : [];
            const capoValue = parseCapoValue(song.capo);
            const hasPositiveCapo = capoValue !== null && capoValue > 0;
            const normalizedTechniques = hasPositiveCapo
                ? techniques
                : techniques.filter((technique) => technique !== "barre-chords");

            return {
                ...song,
                techniques: normalizedTechniques
            };
        });
    }

    async function loadSeedSongProfiles() {
        try {
            const response = await fetch(withCacheBuster(SEED_PROFILES_URL));
            if (response.status === 404) {
                seedSongProfiles = {};
                return;
            }

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}`);
            }

            const data = await response.json();
            if (!data || typeof data !== "object" || Array.isArray(data)) {
                throw new Error("Invalid seed profile format");
            }

            seedSongProfiles = Object.fromEntries(
                Object.entries(data).map(([songId, profile]) => [songId, normalizeProfileData(profile)])
            );
        } catch (error) {
            seedSongProfiles = {};
            console.warn("Seed profiles not available:", error);
        }
    }

    function applyInitialQuerySelection() {
        const url = new URL(window.location.href);
        const songId = url.searchParams.get("song");
        if (!songId) {
            return;
        }

        const fromQuery = findSongById(songId);
        if (fromQuery) {
            loadSong(fromQuery);
        }
    }

    function setTranspose(value) {
        transposeShift = normalizeShift(value);
        updateTransposeBadge();
        renderSongBody();
    }

    function updateSortButtonStates() {
        const arrow = sortDirection === "asc" ? " ↑" : " ↓";
        
        sortButtons.forEach((btn) => {
            if (!btn) return;
            const btnSort = btn.dataset.sort;
            
            if (btnSort === sortColumn) {
                btn.classList.remove("btn-outline-secondary");
                btn.classList.add("btn-secondary");
                const label = btn.textContent.replace(/ [↑↓]$/, "");
                btn.textContent = label + arrow;
            } else {
                btn.classList.remove("btn-secondary");
                btn.classList.add("btn-outline-secondary");
                const label = btn.textContent.replace(/ [↑↓]$/, "");
                btn.textContent = label;
            }
        });
    }

    function bindEvents() {
        // Event listeners para ordenamiento
        if (sortByArtist) {
            sortByArtist.addEventListener("click", () => {
                if (sortColumn === "artist") {
                    sortDirection = sortDirection === "asc" ? "desc" : "asc";
                } else {
                    sortColumn = "artist";
                    sortDirection = "asc";
                }
                saveSortSettings();
                updateSortButtonStates();
                renderSongList(searchInput.value);
            });
        }

        if (sortByTitle) {
            sortByTitle.addEventListener("click", () => {
                if (sortColumn === "title") {
                    sortDirection = sortDirection === "asc" ? "desc" : "asc";
                } else {
                    sortColumn = "title";
                    sortDirection = "asc";
                }
                saveSortSettings();
                updateSortButtonStates();
                renderSongList(searchInput.value);
            });
        }

        if (sortByRating) {
            sortByRating.addEventListener("click", () => {
                if (sortColumn === "rating") {
                    sortDirection = sortDirection === "asc" ? "desc" : "asc";
                } else {
                    sortColumn = "rating";
                    sortDirection = "asc";
                }
                saveSortSettings();
                updateSortButtonStates();
                renderSongList(searchInput.value);
            });
        }

        if (clearSearchHistoryBtn) {
            clearSearchHistoryBtn.addEventListener("click", () => {
                clearSearchHistory();
            });
        }

        exportProfilesBtn.addEventListener("click", () => {
            const jsonContent = exportProfilesToJson();
            const filename = `partituras-perfiles-${new Date().toISOString().split("T")[0]}.json`;
            downloadJSON(filename, jsonContent);
        });

        importProfilesBtn.addEventListener("click", () => {
            importProfilesFile.click();
        });

        importProfilesFile.addEventListener("change", (event) => {
            const file = event.target.files?.[0];
            if (!file) return;

            const reader = new FileReader();
            reader.onload = (e) => {
                const content = e.target?.result;
                if (typeof content === "string") {
                    importProfilesFromJson(content);
                }
                // Reset el input para permitir seleccionar el mismo archivo de nuevo
                importProfilesFile.value = "";
            };
            reader.readAsText(file);
        });

        searchInput.addEventListener("input", (event) => {
            renderSongList(event.target.value);
            renderSearchSuggestions(event.target.value);
        });

        searchInput.addEventListener("focus", () => {
            renderSearchSuggestions(searchInput.value);
        });

        searchInput.addEventListener("keydown", (event) => {
            if (event.key === "Enter") {
                if (activeSuggestionIndex >= 0) {
                    event.preventDefault();
                    applySuggestion(activeSuggestionIndex);
                } else if (searchInput.value.trim()) {
                    // Guardar búsqueda cuando presiona Enter sin sugerencia
                    saveSearchHistory(searchInput.value);
                    hideSearchSuggestions();
                }
                return;
            }

            if (searchSuggestionItems.length === 0) {
                return;
            }

            if (event.key === "ArrowDown") {
                event.preventDefault();
                activeSuggestionIndex = (activeSuggestionIndex + 1) % searchSuggestionItems.length;
                updateSuggestionHighlight();
                return;
            }

            if (event.key === "ArrowUp") {
                event.preventDefault();
                activeSuggestionIndex = activeSuggestionIndex <= 0
                    ? searchSuggestionItems.length - 1
                    : activeSuggestionIndex - 1;
                updateSuggestionHighlight();
                return;
            }

            if (event.key === "Escape") {
                hideSearchSuggestions();
            }
        });

        document.addEventListener("click", (event) => {
            if (event.target === searchInput || searchSuggestions.contains(event.target)) {
                return;
            }

            hideSearchSuggestions();
        });

        filterAll.addEventListener("click", () => {
            filterMode = "all";
            saveFilterMode();
            updateFilterButtons();
            renderSongList(searchInput.value);
            updateFilterCounters();
        });

        filterFavorites.addEventListener("click", () => {
            filterMode = "favorites";
            saveFilterMode();
            updateFilterButtons();
            renderSongList(searchInput.value);
            updateFilterCounters();
        });

        resetFilters.addEventListener("click", () => {
            resetAllFilters();
        });

        instrumentFilter.addEventListener("change", (event) => {
            instrumentFilterValue = event.target.value;
            saveInstrumentFilter();
            renderSongList(searchInput.value);
        });

        ratingFilter.addEventListener("change", (event) => {
            ratingFilterValue = Number(event.target.value);
            saveRatingFilter();
            renderSongList(searchInput.value);
        });

        tuningFilter.addEventListener("change", (event) => {
            tuningFilterValue = event.target.value;
            saveTuningFilter();
            renderSongList(searchInput.value);
            updateFilterCounters();
        });

        capoFilter.addEventListener("change", (event) => {
            capoFilterValue = event.target.value;
            saveCapoFilter();
            renderSongList(searchInput.value);
            updateFilterCounters();
        });

        techniqueFilter.addEventListener("change", (event) => {
            techniqueFilterValue = event.target.value;
            saveTechniqueFilter();
            renderSongList(searchInput.value);
        });

        keyFilter.addEventListener("change", (event) => {
            keyFilterValue = event.target.value;
            saveKeyFilter();
            renderSongList(searchInput.value);
        });

        timeSignatureFilter.addEventListener("change", (event) => {
            timeSignatureFilterValue = event.target.value;
            saveTimeSignatureFilter();
            renderSongList(searchInput.value);
        });

        songInstrumentGroup.addEventListener("change", () => {
            if (!activeSongId) {
                return;
            }

            const profile = getSongProfile(activeSongId);
            const instruments = songInstrumentInputs
                .filter((input) => input.checked)
                .map((input) => input.value);

            saveSongProfileWithDetectedChords(activeSongId, {
                instruments,
                rating: profile.rating,
                tuning: profile.tuning,
                capo: profile.capo,
                bpm: profile.bpm,
                key: profile.key,
                timeSignature: profile.timeSignature,
                techniques: profile.techniques
            });
            renderActiveSongProfile();
            renderSongList(searchInput.value);
        });

        songTuning.addEventListener("change", () => {
            if (!activeSongId) {
                return;
            }

            const profile = getSongProfile(activeSongId);
            saveSongProfileWithDetectedChords(activeSongId, {
                instruments: profile.instruments,
                rating: profile.rating,
                tuning: songTuning.value,
                capo: profile.capo,
                bpm: profile.bpm,
                key: profile.key,
                timeSignature: profile.timeSignature,
                techniques: profile.techniques
            });
            renderSongList(searchInput.value);
        });

        fontDown.addEventListener("click", () => {
            fontSizeRem = Math.max(0.72, fontSizeRem - 0.08);
            setSongFontSize();
            saveFontSize();
        });

        fontUp.addEventListener("click", () => {
            fontSizeRem = Math.min(1.4, fontSizeRem + 0.08);
            setSongFontSize();
            saveFontSize();
        });

        fontReset.addEventListener("click", () => {
            fontSizeRem = 0.92;
            setSongFontSize();
            saveFontSize();
        });

        transposeDown.addEventListener("click", () => {
            setTranspose(transposeShift - 1);
        });

        transposeUp.addEventListener("click", () => {
            setTranspose(transposeShift + 1);
        });

        transposeReset.addEventListener("click", () => {
            setTranspose(0);
        });

        autoscrollToggle.addEventListener("click", () => {
            if (!activeSongRawText) {
                return;
            }

            if (autoscrollTimer) {
                stopAutoscroll();
            } else {
                startAutoscroll();
            }
        });

        autoscrollSpeed.addEventListener("input", () => {
            if (autoscrollTimer) {
                startAutoscroll();
            }
        });

        document.addEventListener("keydown", (event) => {
            if (event.key === "/" && event.target !== searchInput) {
                event.preventDefault();
                searchInput.focus();
                return;
            }

            if (!event.altKey || !activeSongRawText) {
                return;
            }

            if (event.key === "ArrowUp") {
                event.preventDefault();
                setTranspose(transposeShift + 1);
            }

            if (event.key === "ArrowDown") {
                event.preventDefault();
                setTranspose(transposeShift - 1);
            }
        });
    }

    async function init() {
        try {
            updateProtocolNotice();
            await loadSongsIndex();
            await loadSeedSongProfiles();
            await loadSharedProfiles();
            populateDynamicFilters();
            fontSizeRem = loadFontSize();
            saveSongProfiles();
            instrumentFilter.value = instrumentFilterValue;
            ratingFilter.value = String(ratingFilterValue);
            tuningFilter.value = tuningFilterValue;
            capoFilterValue = ensureSelectValue(capoFilter, capoFilterValue, "all");
            techniqueFilterValue = ensureSelectValue(techniqueFilter, techniqueFilterValue, "all");
            keyFilterValue = ensureSelectValue(keyFilter, keyFilterValue, "all");
            timeSignatureFilterValue = ensureSelectValue(timeSignatureFilter, timeSignatureFilterValue, "all");
            capoFilter.value = capoFilterValue;
            techniqueFilter.value = techniqueFilterValue;
            keyFilter.value = keyFilterValue;
            timeSignatureFilter.value = timeSignatureFilterValue;
            setSongFontSize();
            updateFavoritesBadge();
            updateProfileBadge();
            updateFilterButtons();
            updateTransposeBadge();
            renderActiveSongProfile();
            renderSongList();
            updateFilterCounters();
            updateSortButtonStates();
            bindEvents();
            applyInitialQuerySelection();
        } catch (error) {
            songList.innerHTML = "";
            songCount.textContent = "0";

            const emptyItem = document.createElement("div");
            emptyItem.className = "text-center opacity-75 p-4";
            emptyItem.textContent = "No se pudo cargar el indice de canciones.";
            songList.appendChild(emptyItem);

            emptyState.querySelector(".card-body").innerHTML = `
                <div>
                    <h2 class="h4 mb-2">Indice no disponible</h2>
                    <p class="mb-0 opacity-75">Abre la web con servidor local y verifica que exista el archivo partituras/index.json.</p>
                </div>
            `;

            console.error("Error loading songs index:", error);
        }
    }

    init();
});
