document.addEventListener("DOMContentLoaded", () => {
    const searchInput = document.getElementById("searchInput");
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
    const instrumentFilter = document.getElementById("instrumentFilter");
    const ratingFilter = document.getElementById("ratingFilter");
    const tuningFilter = document.getElementById("tuningFilter");
    const songTuning = document.getElementById("songTuning");
    const favoritesBadge = document.getElementById("favoritesBadge");
    const profileBadge = document.getElementById("profileBadge");

    const songInstrumentGroup = document.getElementById("songInstrumentGroup");
    const songInstrumentInputs = Array.from(document.querySelectorAll('input[name="songInstrument"]'));
    const songRating = document.getElementById("songRating");
    const songRatingLabel = document.getElementById("songRatingLabel");

    if (
        !songList ||
        !searchInput ||
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
        !instrumentFilter ||
        !ratingFilter ||
        !tuningFilter ||
        !songTuning ||
        !favoritesBadge ||
        !profileBadge ||
        !songInstrumentGroup ||
        songInstrumentInputs.length === 0 ||
        !songRating ||
        !songRatingLabel
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
        songProfiles: "partituras:song-profiles"
    };

    const SEED_PROFILES_URL = "partituras/song-profiles.seed.json";

    const INSTRUMENT_LABELS = {
        "sin-definir": "Sin definir",
        "guitarra-electrica": "Guitarra electrica",
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
    let transposeShift = 0;
    let autoscrollTimer = null;
    let fontSizeRem = 0.92;
    let seedSongProfiles = {};

    const favoriteIds = new Set(loadFavoriteIds());
    const songProfiles = loadSongProfiles();
    let filterMode = loadFilterMode();
    let instrumentFilterValue = loadInstrumentFilter();
    let ratingFilterValue = loadRatingFilter();
    let tuningFilterValue = loadTuningFilter();

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
        let capoLine = "";
        let capoLineIndex = -1;
        const cleanLines = [];

        lines.forEach((line, index) => {
            const trimmed = line.trim().toUpperCase();
            const hasCapoPrefix = trimmed.startsWith("CEJILLA/CAPO:") ||
                                  trimmed.startsWith("CEJILLA:") ||
                                  trimmed.startsWith("CAPO:");
            const hasCapoKeyword = /\bcapo\s+[0-9]/i.test(line);

            if ((hasCapoPrefix || hasCapoKeyword) && capoLineIndex === -1) {
                capoLine = line.trim();
                capoLineIndex = index;
            } else if (index !== capoLineIndex) {
                cleanLines.push(line);
            }
        });

        let capoText = "";
        if (capoLine) {
            const match = capoLine.match(/(?:CEJILLA\/CAPO|CEJILLA|CAPO)\s*:\s*(.+)/i) ||
                          capoLine.match(/\bcapo\s+(.+?)(?:\s*$|\.|\||para)/i);
            if (match) {
                capoText = match[1].trim();
            }
        }

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

    const fileUrl = (filename) => `partituras/${encodeURIComponent(filename)}`;

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
        return {
            instruments: normalizeInstrumentList(normalizedProfile.instruments ?? normalizedProfile.instrument),
            rating: Number.isInteger(normalizedProfile.rating) ? Math.max(0, Math.min(5, normalizedProfile.rating)) : 0,
            tuning: Object.prototype.hasOwnProperty.call(TUNING_LABELS, rawTuning) ? rawTuning : ""
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

    function saveSongProfile(songId, nextProfile) {
        const rawTuning = nextProfile.tuning ?? "";
        songProfiles[songId] = {
            instruments: normalizeInstrumentList(nextProfile.instruments),
            rating: Number.isInteger(nextProfile.rating) ? Math.max(0, Math.min(5, nextProfile.rating)) : 0,
            tuning: Object.prototype.hasOwnProperty.call(TUNING_LABELS, rawTuning) ? rawTuning : ""
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
                saveSongProfile(activeSongId, {
                    instruments: profile.instruments,
                    rating: nextRating
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
        const filteredSongs = songs.filter((song) => matchesCurrentFilters(song, query));

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
                        ${instrumentTags.join("")}
                        ${tuningTag}
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
        }, 80);

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

        const lines = text.split("\n");
        const sectionPattern = /^\s*(\[?(?:INTRO|VERSO|ESTROFA|ESTRIBILLO|PUENTE|BRIDGE|OUTRO)\]?)\s*$/i;

        return lines.map((line) => {
            if (sectionPattern.test(line)) {
                // Usar un marcador especial para identificar secciones después
                const sectionName = line.trim();
                return `|||SECTION_START|||${sectionName}|||SECTION_END|||`;
            }
            return line;
        }).join("\n");
    }

    function renderSongBody() {
        const { cleanText } = extractCapoInfo(activeSongRawText);
        const highlighted = highlightSections(cleanText);
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
            const { capo } = extractCapoInfo(activeSongRawText);
            activeSongCapo = capo;
            activeSongId = song.id;

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
        const response = await fetch("partituras/index.json");
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }

        const data = await response.json();
        if (!Array.isArray(data)) {
            throw new Error("Invalid index format");
        }

        songs = data;
    }

    async function loadSeedSongProfiles() {
        try {
            const response = await fetch(SEED_PROFILES_URL);
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

    function bindEvents() {
        searchInput.addEventListener("input", (event) => {
            renderSongList(event.target.value);
        });

        filterAll.addEventListener("click", () => {
            filterMode = "all";
            saveFilterMode();
            updateFilterButtons();
            renderSongList(searchInput.value);
        });

        filterFavorites.addEventListener("click", () => {
            filterMode = "favorites";
            saveFilterMode();
            updateFilterButtons();
            renderSongList(searchInput.value);
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
        });

        songInstrumentGroup.addEventListener("change", () => {
            if (!activeSongId) {
                return;
            }

            const profile = getSongProfile(activeSongId);
            const instruments = songInstrumentInputs
                .filter((input) => input.checked)
                .map((input) => input.value);

            saveSongProfile(activeSongId, {
                instruments,
                rating: profile.rating
            });
            renderActiveSongProfile();
            renderSongList(searchInput.value);
        });

        songTuning.addEventListener("change", () => {
            if (!activeSongId) {
                return;
            }

            const profile = getSongProfile(activeSongId);
            saveSongProfile(activeSongId, {
                instruments: profile.instruments,
                rating: profile.rating,
                tuning: songTuning.value
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
            await loadSongsIndex();
            await loadSeedSongProfiles();
            fontSizeRem = loadFontSize();
            saveSongProfiles();
            instrumentFilter.value = instrumentFilterValue;
            ratingFilter.value = String(ratingFilterValue);
            tuningFilter.value = tuningFilterValue;
            setSongFontSize();
            updateFavoritesBadge();
            updateProfileBadge();
            updateFilterButtons();
            updateTransposeBadge();
            renderActiveSongProfile();
            renderSongList();
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
