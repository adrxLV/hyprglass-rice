import QtQuick
import Quickshell.Services.Mpris
import IslandBackend

Item {
    id: root

    visible: false
    width: 0
    height: 0

    property bool expanded: false
    property string clientId: "island-mpris-default"
    property string registeredLyricsClientId: ""

    property string lastActivePlayerDbusName: ""
    property var playersList: Mpris.players.values !== undefined ? Mpris.players.values : Mpris.players
    property var activePlayer: resolveActivePlayer()

    property string fetchedCoverUrl: ""
    property string _lastCoverQueryKey: ""

    readonly property string rawTitle: activePlayer ? (activePlayer.trackTitle || activePlayer.title || "") : ""

    readonly property string lyricsLookupTitle: parseRawTitle(rawTitle)
    readonly property string lyricsLookupArtist: parseRawArtist(activePlayer, rawTitle)

    readonly property string currentTrack: lyricsLookupTitle !== "" ? lyricsLookupTitle : (rawTitle !== "" ? rawTitle : "Unknown")
    readonly property string currentArtist: lyricsLookupArtist !== "" ? lyricsLookupArtist : "Unknown"
    readonly property string directArtUrl: parseRawArtUrl(activePlayer)
    readonly property string currentArtUrl: directArtUrl !== "" ? directArtUrl : fetchedCoverUrl

    onCurrentTrackChanged: {
        fetchedCoverUrl = "";
        _lastCoverQueryKey = "";
        checkCoverArtFallback();
    }
    onCurrentArtistChanged: {
        fetchedCoverUrl = "";
        _lastCoverQueryKey = "";
        checkCoverArtFallback();
    }
    onDirectArtUrlChanged: {
        if (directArtUrl !== "") {
            fetchedCoverUrl = "";
        } else {
            checkCoverArtFallback();
        }
    }

    function checkCoverArtFallback() {
        if (directArtUrl !== "") {
            fetchedCoverUrl = "";
            return;
        }
        fetchCoverArtIfNeeded(currentTrack, currentArtist);
    }

    function fetchCoverArtIfNeeded(track, artist) {
        if (!track || track === "Unknown" || !artist || artist === "Unknown") {
            fetchedCoverUrl = "";
            return;
        }
        const queryKey = artist + " - " + track;
        if (_lastCoverQueryKey === queryKey) return;
        _lastCoverQueryKey = queryKey;

        const url = "https://itunes.apple.com/search?term=" + encodeURIComponent(artist + " " + track) + "&entity=song&limit=1";
        const req = new XMLHttpRequest();
        req.open("GET", url, true);
        req.onreadystatechange = function() {
            if (req.readyState === XMLHttpRequest.DONE && req.status === 200) {
                try {
                    const res = JSON.parse(req.responseText);
                    if (res.results && res.results.length > 0) {
                        let art = res.results[0].artworkUrl100 || res.results[0].artworkUrl60;
                        if (art) {
                            fetchedCoverUrl = art.replace("100x100bb", "600x600bb");
                        }
                    }
                } catch(e) {}
            }
        };
        req.send();
    }

    function parseRawTitle(title) {
        if (!title) return "";
        let clean = String(title).trim();
        if (clean.indexOf(" • ") !== -1) return clean.split(" • ")[0].trim();
        if (clean.indexOf(" - ") !== -1) return clean.split(" - ")[0].trim();
        if (clean.indexOf(" — ") !== -1) return clean.split(" — ")[0].trim();
        return clean;
    }

    function parseRawArtist(player, title) {
        if (!player) return "";
        let artist = player.artist;
        if (artist) {
            if (Array.isArray(artist)) {
                let joined = artist.filter(a => String(a).trim() !== "").join(", ");
                if (joined !== "") return joined;
            } else if (String(artist).trim() !== "") {
                return String(artist).trim();
            }
        }
        if (player.metadata) {
            let metaArtist = player.metadata["xesam:artist"] 
                          || player.metadata["xesam:albumArtist"] 
                          || player.metadata["artist"] 
                          || player.metadata["albumArtist"];
            if (metaArtist) {
                if (Array.isArray(metaArtist)) {
                    let joined = metaArtist.filter(a => String(a).trim() !== "").join(", ");
                    if (joined !== "") return joined;
                } else if (String(metaArtist).trim() !== "") {
                    return String(metaArtist).trim();
                }
            }
        }
        if (title) {
            let clean = String(title).trim();
            if (clean.indexOf(" • ") !== -1) {
                let parts = clean.split(" • ");
                if (parts.length >= 2 && parts[1].trim() !== "") return parts[1].trim();
            }
            if (clean.indexOf(" - ") !== -1) {
                let parts = clean.split(" - ");
                if (parts.length >= 2 && parts[1].trim() !== "") return parts[1].trim();
            }
            if (clean.indexOf(" — ") !== -1) {
                let parts = clean.split(" — ");
                if (parts.length >= 2 && parts[1].trim() !== "") return parts[1].trim();
            }
        }
        return "";
    }

    function parseRawArtUrl(player) {
        if (!player) return "";
        let url = player.trackArtUrl || player.artUrl || "";
        if (url && String(url).trim() !== "") return String(url).trim();
        if (player.metadata) {
            let metaUrl = player.metadata["mpris:artUrl"] 
                       || player.metadata["artUrl"] 
                       || player.metadata["xesam:artUrl"] 
                       || player.metadata["xesam:coverArt"]
                       || player.metadata["art_url"];
            if (metaUrl && String(metaUrl).trim() !== "") return String(metaUrl).trim();
        }
        return "";
    }
    readonly property string inlineLyricsRaw: {
        if (!activePlayer || !activePlayer.metadata) return "";
        let inlineLyrics = activePlayer.metadata["xesam:asText"];
        if (!inlineLyrics) inlineLyrics = activePlayer.metadata["xesam:comment"];
        if (Array.isArray(inlineLyrics)) return inlineLyrics.join("\n");
        return inlineLyrics ? String(inlineLyrics) : "";
    }
    readonly property string displayText: lyricsBridge.displayText

    property string plainLyric: ""
    property string _lastParsedInlineLyricsRaw: ""
    property real trackProgress: 0
    property string timePlayed: "0:00"
    property string timeTotal: "0:00"

    onActivePlayerChanged: {
        syncLyricsBackend();
        Qt.callLater(function() {
            const nextDbusName = root.activePlayer && root.activePlayer.dbusName
                ? root.activePlayer.dbusName
                : "";
            if (root.lastActivePlayerDbusName !== nextDbusName)
                root.lastActivePlayerDbusName = nextDbusName;
        });
    }

    onInlineLyricsRawChanged: updatePlainLyric()
    onClientIdChanged: syncLyricsBackend()

    Component.onCompleted: {
        updatePlainLyric();
        syncLyricsBackend();
    }
    Component.onDestruction: {
        if (registeredLyricsClientId !== "")
            SysBackend.setLyricsClientActive(registeredLyricsClientId, false);
    }

    function syncLyricsBackend() {
        const nextClientId = String(clientId || "island-mpris-default");
        if (registeredLyricsClientId !== "" && registeredLyricsClientId !== nextClientId)
            SysBackend.setLyricsClientActive(registeredLyricsClientId, false);

        registeredLyricsClientId = nextClientId;
        SysBackend.setLyricsClientActive(registeredLyricsClientId, activePlayer !== null);
    }

    function formatTime(value) {
        const numberValue = Number(value);
        if (isNaN(numberValue) || numberValue <= 0) return "0:00";

        let totalSeconds = 0;
        if (numberValue < 10000) totalSeconds = Math.floor(numberValue);
        else if (numberValue < 100000000) totalSeconds = Math.floor(numberValue / 1000);
        else totalSeconds = Math.floor(numberValue / 1000000);

        const minutes = Math.floor(totalSeconds / 60);
        const seconds = Math.floor(totalSeconds % 60);
        return minutes + ":" + (seconds < 10 ? "0" : "") + seconds;
    }

    function cleanLyricLineText(text) {
        return String(text === undefined || text === null ? "" : text)
            .replace(/\s+/g, " ")
            .trim();
    }

    function extractFirstPlainLyric(rawLyrics) {
        const source = String(rawLyrics === undefined || rawLyrics === null ? "" : rawLyrics);
        let lineStart = 0;

        for (let index = 0; index <= source.length; index++) {
            if (index < source.length && source[index] !== "\n" && source[index] !== "\r")
                continue;

            const row = source.slice(lineStart, index).trim();
            if (row !== "" && !/^\[[a-zA-Z]+:.*\]$/.test(row)) {
                const lineText = cleanLyricLineText(row.replace(/\[(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?\]/g, ""));
                if (lineText !== "")
                    return lineText;
            }

            if (source[index] === "\r" && source[index + 1] === "\n")
                index++;

            lineStart = index + 1;
        }

        return "";
    }

    function updatePlainLyric() {
        if (inlineLyricsRaw === _lastParsedInlineLyricsRaw)
            return;

        _lastParsedInlineLyricsRaw = inlineLyricsRaw;
        plainLyric = extractFirstPlainLyric(inlineLyricsRaw);
    }

    function syncProgress(positionOverride) {
        let player = root.activePlayer;
        if (!player) {
            root.trackProgress = 0;
            root.timePlayed = "0:00";
            root.timeTotal = "0:00";
            return;
        }

        const currentPosition = positionOverride === undefined
            ? Number(player.position) || 0
            : Number(positionOverride) || 0;
        let totalLength = Number(player.length) || 0;
        if (totalLength <= 0 && player.metadata && player.metadata["mpris:length"])
            totalLength = Number(player.metadata["mpris:length"]);

        if (totalLength > 0) {
            root.trackProgress = Math.max(0, Math.min(1, currentPosition / totalLength));
            root.timePlayed = root.formatTime(currentPosition);
            root.timeTotal = root.formatTime(totalLength);
        } else {
            root.trackProgress = 0;
            root.timePlayed = root.formatTime(currentPosition);
            root.timeTotal = "0:00";
        }
    }

    function syncToTrackStart(player) {
        if (player && player.canSeek && player.positionSupported)
            player.position = 0;

        syncProgress(0);
    }

    function previous() {
        let player = root.activePlayer;
        if (!player) return;

        player.previous();
        syncToTrackStart(player);
    }

    function playerHasTrackInfo(player) {
        if (!player) return false;
        if ((player.trackTitle || player.title || "") !== "") return true;
        if (!player.metadata) return false;
        return Boolean(
            player.metadata["xesam:title"]
            || player.metadata["mpris:trackid"]
            || player.metadata["xesam:url"]
        );
    }

    function findPlayerByDbusName(dbusName) {
        if (!playersList || !dbusName) return null;
        for (let index = 0; index < playersList.length; index++) {
            if (playersList[index].dbusName === dbusName)
                return playersList[index];
        }
        return null;
    }

    function resolveActivePlayer() {
        if (!playersList || playersList.length === 0) return null;

        for (let index = 0; index < playersList.length; index++) {
            if (playersList[index].playbackState === MprisPlaybackState.Playing)
                return playersList[index];
        }

        const rememberedPlayer = findPlayerByDbusName(lastActivePlayerDbusName);
        if (rememberedPlayer && (playerHasTrackInfo(rememberedPlayer) || rememberedPlayer.canControl))
            return rememberedPlayer;

        for (let index = 0; index < playersList.length; index++) {
            if (playersList[index].playbackState === MprisPlaybackState.Paused && playerHasTrackInfo(playersList[index]))
                return playersList[index];
        }

        for (let index = 0; index < playersList.length; index++) {
            if (playersList[index].canControl)
                return playersList[index];
        }

        return playersList[0];
    }

    QtObject {
        id: lyricsBridge

        readonly property string title: root.currentTrack
        readonly property string currentLyric: SysBackend && SysBackend.lyricsCurrentLyric !== undefined
            ? SysBackend.lyricsCurrentLyric
            : ""
        readonly property bool isSynced: SysBackend && SysBackend.lyricsIsSynced !== undefined
            ? SysBackend.lyricsIsSynced
            : false
        readonly property string backendStatus: SysBackend && SysBackend.lyricsBackendStatus !== undefined
            ? SysBackend.lyricsBackendStatus
            : "idle"
        readonly property string plainLyric: root.plainLyric
        readonly property string displayText: {
            if (title === "") return "No music playing";
            if (backendStatus === "missing" || backendStatus === "error") return "no lyrics";
            if (isSynced && currentLyric !== "") return currentLyric;
            if (plainLyric !== "") return plainLyric;
            return title;
        }
    }

    Timer {
        id: progressPoller

        interval: 500
        running: root.activePlayer !== null && root.expanded
        repeat: true

        onTriggered: root.syncProgress()
    }
}
