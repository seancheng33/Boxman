# Godot Boxman (Sokoban)

English | [简体中文](readme.md)

A Sokoban game built with Godot 3.5.2, with a bilingual (Chinese/English) UI.

## Introduction

- Art assets from the free game-asset website: https://kenney.nl/
- Classic levels from http://sokoban.cn/, **237 levels** after deduplication
- **Unlock-based progression**: the first 5 levels are open from the start; clearing a level unlocks the next one; progress is saved automatically
- Keyboard (arrow keys / WASD) controls and mouse-driven menus; press **Z** to undo the last move
- Levels rotate through **color themes** (brown / red / blue / green / gray) per chapter; a box sitting on a target spot switches to the dark variant of its color
- UI language can be switched between **Chinese / English** from the main menu (preference is saved automatically)

## Play Online

Open the play URL directly: <http://three-corner.xyz/static/boxman/Boxman.html>

> Note: the HTML5 build stores progress in the browser (IndexedDB); switching browsers or clearing site data resets progress.

## Screenshots

### Main menu

![Main menu](assets/img/主界面.png)

### In game

![In game](assets/img/游戏内.png)

### Level select (live preview)

![Level select](assets/img/游戏选关.png)

## Controls

- Menus: mouse click
- Movement: arrow keys or 【W、A、S、D】
- Undo: press 【Z】 to take back the last move
- Push boxes onto **all target spots** to clear a level (a few levels have more boxes than targets — the extras are decoys and don't need to be parked)
- After clearing you can go to the next level or return to the main menu; you can also switch levels with the Prev/Next buttons in game (unlocked levels only)

## Technical Notes

- Engine: Godot 3.5.2 (GDScript)
- Dev environment: Windows 11 (primary), macOS (occasionally)
- **Level data**: standard sokoban ASCII text under `levels_txt/` (`#` wall, `@` player, `$` box, `.` goal, `*`/`+` box/player on goal). Levels are generated at runtime by `scene/LevelTemplate.tscn` + `script/level_builder.gd` — **adding a level is just dropping a text file into `levels_txt/`**, no editor work needed.
- **Game state**: unlock progress, cleared levels and the last played level are persisted to `progress.cfg`; **on Windows / macOS it lives next to the game executable** (portable save — copy the whole folder to carry your progress; falls back to the system `user://` if the folder is not writable), IndexedDB on HTML5
- **Navigation**: all screens go through the unified `goto_level(index)` entry in `global.gd`
- **Localization**: all UI strings live in the `TEXTS` table in `global.gd`; the language preference is persisted next to `progress.cfg` (portable location on desktop, `user://settings.cfg` on HTML5/editor)
- **Level select**: paged number grid + SubViewport live preview of the selected level (always in sync with the real level, inherits the color theme); no pre-rendered screenshots involved
- Export: `export_presets.cfg` includes `include_filter="*.txt"` so exported builds carry the level data
- **Exe icon**: `application/modify_resources=true` with `application/icon="res://icon.ico"` (multi-size ICO, 16-256px). Godot 3.x rewrites PE resources via [rcedit](https://github.com/electron/rcedit); place `rcedit-x64.exe` next to the editor binary, or point *Editor Settings -> Export -> Windows -> rcedit* at it (export fails outright if it is not found)

## Level Verification

The `tools/` directory ships with level parsing and solver scripts:

- `tools/parse_levels.py`: legacy tscn → ASCII converter (used for the migration; 237/237 passed lossless verification)
- `tools/solve_levels.py`: A* solver with dead-square/freeze pruning; supports the `SOLVE_LIMIT` env var and per-level arguments
- `tools/level_shot.gd`: level screenshot helper (`SCENE_PATH` / `BOXMAN_LEVEL` / `SHOT_PATH` env vars) for visual verification of UI and themes
- Results: **227 levels verified solvable**; Level071/131/146 were unsolvable due to transcription errors and have been fixed in the map data; the remaining 10 levels exceeded the solver's 300-second budget (undetermined, not necessarily unsolvable)

## Downloads

Windows and HTML5 builds are available on the **Releases** page (the HTML5 build needs a local static server after unzipping — opening `Boxman.html` directly via file:// fails on CORS).

## Contact

More levels and content are coming. Found a bug or have a suggestion? Email me at aya234@163.com

## Changelog

### v1.2.1

- **Portable save**: on Windows / macOS progress is stored next to the game executable (`progress.cfg`) — copy the folder to carry your progress; automatic fallback to the system directory when not writable, HTML5 unchanged
- **Level select**: level buttons doubled in size (144x104), 5x5 = 25 per page; locked levels show a red padlock icon

### v1.2.0

- **Unlock-based progression**: first 5 levels open, clearing unlocks the next; locked levels grayed out and cleared levels marked green on the level select screen
- **Level select revamp**: 237 screenshot buttons replaced by a paged number grid + live level preview (inherits the color theme); opens at the last played level
- **Color themes**: 5 themes (brown / red / blue / green / gray) rotate every 20 levels; boxes turn to the dark variant on target spots
- **Fixes**: in-game level label clipping; upside-down level select preview; dark state lost when a box moves between adjacent targets; Prev/Next buttons could reach locked levels
- **UI**: new visual design for the main menu and about page; Z-key undo added to the about text
- **Size**: 474 pre-rendered level screenshots retired, exported builds are significantly smaller
