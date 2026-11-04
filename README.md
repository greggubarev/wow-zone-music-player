# WoW Zone Music Player

This addon plays local Perfect World and Morrowind music in WoW Retail and WoW Forever. The two collections have separate zone selections, track orders, and shuffle histories.

## Install by copying the addon folder

1. Copy the entire `WoWZoneMusicPlayer` folder into either `World of Warcraft/_retail_/Interface/AddOns/` or `World of Warcraft/_forever_/Interface/AddOns/`. You can copy it into both. The `.toc` file must end up at `Interface/AddOns/WoWZoneMusicPlayer/WoWZoneMusicPlayer.toc`.
4. Restart WoW. Make sure the game's Music volume is enabled.

No script is needed for the copy method. The two audio folders are separate: Shuffle and automatic zone selection never mix their tracks.

Optional: `./PrepareMorrowind.ps1 -ArchivePath 'C:\path\to\soundtrack.rar' -OutputDirectory './Audio/Morrowind' -FfmpegPath 'C:\path\to\ffmpeg.exe'` prepares the 21-track archive (FFmpeg is required for FLAC tracks). `./Install.ps1` can copy the addon and available collections into both default WoW clients. Pass `-PerfectWorldRoot 'C:\path\to\PWI_en'` or `-MorrowindMusicRoot 'C:\path\to\morrowind-audio'` to use external audio folders. For other WoW locations, pass `-WowClientRoots @('C:\path\to\_retail_', 'C:\path\to\_forever_')`.

## Controls

The round minimap button opens the main window with left click, switches power with right click, and shows or hides the mini bar with middle click. Drag it along the minimap rim.

The main window has Perfect World and Morrowind tabs. Choose a tab to switch collections. Its icon controls match the mini bar: Power, Previous, Play/Pause, Next, Repeat, Shuffle, and Auto zone selection. Hover over an icon for its English tooltip. Click a track in the list to play it manually; the page arrows show the rest of the Morrowind soundtrack. Manual playback continues across zone changes until you select Auto.

Previous, Next, and Shuffle use only tracks from the selected tab. In Auto zone mode, each zone theme rotates through several compatible tracks without repeating either of the last two selections. After each song, an ambient interval of 30–90 seconds separates it from the next song. Short Morrowind stingers remain available in the manual list but are not used in automatic zone rotation. Nearby zones that share a theme do not restart the current song. Manual mode plays songs continuously in the current collection. Repeat loops the current song and takes precedence over the interval. A collection switch clears shuffle history and selects that collection's zone theme.

The mini bar is optional. It shows estimated time remaining during a song and a countdown during an ambient interval. Drag its left grip to move it; right click the grip to reset its position.

Optional commands: `/pwm on`, `off`, `pause`, `prev`, `next`, `auto`, `repeat`, `shuffle`, `mini`, `pwi`, `morrowind`, `show`, `hide`, and `map`.

Keep any package containing music for personal use unless you have permission to redistribute the tracks. Perfect World music is available in the [official PWI client](https://www.arcgames.com/en/store/pwi). The [official Morrowind soundtrack](https://store.steampowered.com/app/451410/) and [Morrowind GOTY](https://www.gog.com/en/game/the_elder_scrolls_iii_morrowind_goty_edition) are available from their publishers.
