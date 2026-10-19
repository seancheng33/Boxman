# Godot Boxman (Sokoban)

English | [简体中文](readme.md)

A Sokoban game built with Godot 3.5.2, with a bilingual (Chinese/English) UI.

## Introduction

- Art assets from the free game-asset website: https://kenney.nl/
- Classic levels from http://sokoban.cn/, **237 levels** after deduplication
- Keyboard (arrow keys / WASD) controls and mouse-driven menus; press **Z** to undo
- UI language can be switched between **Chinese / English** from the main menu (preference is saved automatically)

## Screenshots

### Main menu

![Main menu](assets/img/主界面.png)

### In game

![In game](assets/level_image/level039.png)

### Level select

![Level select](assets/img/游戏选关.png)

## Controls

- Menus: mouse click
- Movement: arrow keys or 【W、A、S、D】
- Undo: press 【Z】 to take back the last move
- Push all boxes onto the target spots to clear a level. After clearing you can go to the next level or return to the main menu; you can also switch levels with the Prev/Next buttons in game.

## Technical Notes

- Engine: Godot 3.5.2 (GDScript)
- Dev environment: Windows 11 (primary), macOS 12.6.7 (occasionally)
- **Level data**: standard sokoban ASCII text under `levels_txt/` (`#` wall, `@` player, `$` box, `.` goal, `*`/`+` box/player on goal). Levels are generated at runtime by `scene/LevelTemplate.tscn` + `script/level_builder.gd` — **adding a level is just dropping a text file into `levels_txt/`**, no editor work needed.
- **Navigation**: all screens go through the unified `goto_level(index)` entry in `global.gd`
- **Localization**: all UI strings live in the `TEXTS` table in `global.gd`; the language preference is persisted to `user://settings.cfg`
- Export: `export_presets.cfg` includes `include_filter="*.txt"` so exported builds carry the level data

## Level Verification

The `tools/` directory ships with level parsing and solver scripts:

- `tools/parse_levels.py`: legacy tscn → ASCII converter (used for the migration; 237/237 passed lossless verification)
- `tools/solve_levels.py`: A* solver with dead-square/freeze pruning; supports the `SOLVE_LIMIT` env var and per-level arguments
- Results: **227 levels verified solvable**; Level071/131/146 were unsolvable due to transcription errors and have been fixed in the map data; the remaining 10 levels exceeded the solver's 300-second budget (undetermined, not necessarily unsolvable)

## Play Online

You can find the HTML5 version of this game under the "小玩意" (gadgets) section of my website: <http://three-corner.xyz>

## Downloads

The docker image, Windows binaries and HTML5 build are packaged on Baidu Pan. The Windows and HTML5 builds are also available in the `dist` directory of the source repository, or from the releases page.

### Docker image

Link: https://pan.baidu.com/s/1_ukZqLLnVp-5GWDG6Y_wJw?pwd=8888
Code: 8888

### Windows

Link: https://pan.baidu.com/s/1xIEm1tUhqxuSbB-oA55z0A?pwd=8888
Code: 8888

### HTML5

Link: https://pan.baidu.com/s/1YpamQMTw50kkVmW73RHtGQ?pwd=8888
Code: 8888

## Contact

More levels and content are coming. Found a bug or have a suggestion? Email me at aya234@163.com
