function parseSongFile(fileContent) {
    const lines = fileContent.split('\n');
    const songData = {
        title: '',
        artist: '',
        chords: [],
        lyrics: []
    };

    // Assuming the first line contains the title and artist
    const titleArtistLine = lines[0].split(' - ');
    if (titleArtistLine.length === 2) {
        songData.title = titleArtistLine[1].trim();
        songData.artist = titleArtistArtistLine[0].trim();
    }

    // Process the remaining lines for chords and lyrics
    for (let i = 1; i < lines.length; i++) {
        const line = lines[i].trim();
        if (line) {
            // Check if the line contains chords (assuming chords are uppercase letters)
            if (/^[A-Z\s]+$/.test(line)) {
                songData.chords.push(line);
            } else {
                songData.lyrics.push(line);
            }
        }
    }

    return songData;
}

async function loadSongFile(filePath) {
    const response = await fetch(filePath);
    if (!response.ok) {
        throw new Error('Failed to load song file');
    }
    const fileContent = await response.text();
    return parseSongFile(fileContent);
}