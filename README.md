# WoW Zone Music Player

This addon plays local Perfect World, Morrowind, and Lineage II music in WoW Retail and WoW Forever. Each game has its own zone themes and track list. The All Mix tab can shuffle across all three games. The repository contains code and interface artwork, but no game soundtracks.

## Install or update

1. [Download the current code ZIP](https://github.com/greggubarev/wow-zone-music-player/archive/refs/heads/main.zip) and rename its extracted folder to `WoWZoneMusicPlayer`.
2. For a new installation, add your own MP3 files to `Audio/PerfectWorld/`, `Audio/Morrowind/`, and `Audio/Lineage2/`. `Tracks.lua`, `MorrowindTracks.lua`, and `Lineage2Tracks.lua` list the required filenames.
3. Copy `WoWZoneMusicPlayer` into `World of Warcraft/_retail_/Interface/AddOns/` or `World of Warcraft/_forever_/Interface/AddOns/`. When updating an existing installation, merge the folders and replace code files; keep the existing Perfect World and Morrowind audio folders. The `.toc` file must end up at `Interface/AddOns/WoWZoneMusicPlayer/WoWZoneMusicPlayer.toc`.
4. Restart WoW. Make sure the game's Music volume is enabled.

No script is needed if your MP3 files already have the required names. The Lineage II soundtrack archive used for this collection contains 53 tracks numbered 01–54, with number 47 absent. To name its files for the addon, run `./PrepareLineage2.ps1 -ArchivePath 'C:\path\to\lineage_2_01. After the Storm.zip'`. The script writes `l2_01.mp3` through `l2_54.mp3`, except `l2_47.mp3`, to `Audio/Lineage2/`.

Optional: `./PrepareMorrowind.ps1 -ArchivePath 'C:\path\to\soundtrack.rar' -OutputDirectory './Audio/Morrowind' -FfmpegPath 'C:\path\to\ffmpeg.exe'` prepares the 21-track archive (FFmpeg is required for FLAC tracks). `./Install.ps1` copies code and complete collections into both default WoW clients without removing existing audio. Pass `-PerfectWorldRoot`, `-MorrowindMusicRoot`, or `-Lineage2MusicRoot` to use external music folders. For other WoW locations, pass `-WowClientRoots @('C:\path\to\_retail_', 'C:\path\to\_forever_')`.

## Controls

The round minimap button opens the main window with left click, switches power with right click, and shows or hides the mini bar with middle click. Drag it along the minimap rim.

The main window has PWI, TES III, Lineage II, and All Mix tabs with distinct game emblems. Choose a tab to switch collections. Its icon controls match the mini bar: Power, Previous, Play/Pause, Next, Repeat, Shuffle, and Auto zone selection. Hover over an icon for its English tooltip. Click a track in the list to play it manually; the page arrows show more tracks. Manual playback continues across zone changes until you select Auto.

Previous, Next, and Shuffle use tracks from the selected tab. All Mix automatically enables Shuffle and draws from every available collection. In Auto zone mode, each game tab rotates through several compatible tracks without repeating either of the last two selections. All Mix uses one combined pool across the three games. After each song, an ambient interval of 30–90 seconds separates it from the next song. Short Morrowind and Lineage II cues remain in the manual list but are not used in automatic rotation. Nearby zones that share a theme do not restart the current song. Manual mode plays songs continuously. Repeat loops the current song and takes precedence over the interval. A collection switch clears shuffle history.

In Perfect World mode, capital cities rotate only city themes. If the wrong theme plays in a zone, use `/pwm map` to show the map ID, zone name, selected theme, and playback mode.

The mini bar is optional. It shows estimated time remaining during a song and a countdown during an ambient interval. Drag its left grip to move it; right click the grip to reset its position.

Optional commands: `/pwm on`, `off`, `pause`, `prev`, `next`, `auto`, `repeat`, `shuffle`, `mini`, `pwi`, `morrowind`, `lineage2`, `mix`, `show`, `hide`, and `map`.

Keep any package containing music for personal use unless you have permission to redistribute the tracks. Perfect World music is available in the [official PWI client](https://www.arcgames.com/en/store/pwi). The [official Morrowind soundtrack](https://store.steampowered.com/app/451410/) and [Morrowind GOTY](https://www.gog.com/en/game/the_elder_scrolls_iii_morrowind_goty_edition) are available from their publishers.
