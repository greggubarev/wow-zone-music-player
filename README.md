# WoW Zone Music Player

This addon plays local Perfect World and Morrowind music in WoW Retail and WoW Forever. The two collections have separate zone selections, track orders, and shuffle histories. The starter package contains no soundtrack files.

## Install

1. Put the 14 Perfect World MP3 files listed in `Tracks.lua` into `Audio/PerfectWorld/`.
2. Put the 21 Morrowind MP3 files listed in `MorrowindTracks.lua` into `Audio/Morrowind/`. They must be named `mw_01.mp3` through `mw_21.mp3`. If you have the 21-track soundtrack archive, `./PrepareMorrowind.ps1 -ArchivePath 'C:\path\to\soundtrack.rar' -OutputDirectory './Audio/Morrowind' -FfmpegPath 'C:\path\to\ffmpeg.exe'` can prepare them. FFmpeg is required for FLAC tracks.
3. Run `./Install.ps1`. It installs the addon and any complete collection into `_retail_` and `_forever_`. Alternatively, provide `-PerfectWorldRoot 'C:\path\to\PWI_en'` and/or `-MorrowindMusicRoot 'C:\path\to\morrowind-audio'` to copy music from elsewhere.
4. Restart WoW. Make sure the game's Music volume is enabled.

For other WoW locations, pass `-WowClientRoots @('C:\path\to\_retail_', 'C:\path\to\_forever_')` to `Install.ps1`. A collection tab shows `Files missing` until all its tracks are installed. The two audio folders are separate: Shuffle and automatic zone selection never mix their tracks.

If you previously installed `PerfectWorldZoneMusic`, remove that old addon folder before using this renamed version. Your saved player settings use the same SavedVariables name.

## Controls

The round minimap button opens the main window with left click, switches power with right click, and shows or hides the mini bar with middle click. Drag it along the minimap rim.

The main window has Perfect World and Morrowind tabs. Choose a tab to switch collections. Its icon controls match the mini bar: Power, Previous, Play/Pause, Next, Repeat, Shuffle, and Auto zone selection. Hover over an icon for its English tooltip. Click a track in the list to play it manually; the page arrows show the rest of the Morrowind soundtrack. Manual playback continues across zone changes until you select Auto.

Previous, Next, and Shuffle use only tracks from the selected tab. In Auto zone mode, each zone theme rotates through several compatible tracks without repeating either of the last two selections. After each song, an ambient interval of 30–90 seconds separates it from the next song. Short Morrowind stingers remain available in the manual list but are not used in automatic zone rotation. Nearby zones that share a theme do not restart the current song. Manual mode plays songs continuously in the current collection. Repeat loops the current song and takes precedence over the interval. A collection switch clears shuffle history and selects that collection's zone theme.

The mini bar is optional. It shows estimated time remaining during a song and a countdown during an ambient interval. Drag its left grip to move it; right click the grip to reset its position.

Optional commands: `/pwm on`, `off`, `pause`, `prev`, `next`, `auto`, `repeat`, `shuffle`, `mini`, `pwi`, `morrowind`, `show`, `hide`, and `map`.

Keep any package containing the music for personal use unless you have permission to redistribute the tracks. The [official Morrowind soundtrack](https://store.steampowered.com/app/451410/) and [Morrowind GOTY](https://www.gog.com/en/game/the_elder_scrolls_iii_morrowind_goty_edition) are available from their publishers.
