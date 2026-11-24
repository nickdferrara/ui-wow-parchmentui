# ParchmentUI

An addon for World of Warcraft: Forever that restyles the main game windows as parchment
scrolls docked to the side of the screen, so they sit naturally next to
[Dialogue UI](https://www.curseforge.com/wow/addons/dialogueui).

Status: Milestone 0 (foundation). No game window is skinned yet. `/pui preview` shows a sample
scroll with the current artwork, typeface and docking.

- [Product requirements](docs/prd.md)
- [Engineering standards](docs/engineering-standards.md)
- [Frame audit](docs/frame-audit.md)

## Development

Requires Lua 5.1, `luacheck`, `busted` and `stylua`.

```
make check     lint, format check, unit tests and TOC check
make format    format the source with stylua
make package   build the release zip into .release/
```

## Trying it in game

Copy the `ParchmentUI` folder into `_forever_/Interface/AddOns/` and `/reload`. Commands:
`/pui preview`, `/pui options`, `/pui <setting> <value>`, `/pui window <name> on|off`,
`/pui status`, `/pui audit`, `/pui reset`.

## Artwork

The textures in `ParchmentUI/Art` are placeholders drawn by `art/generate_textures.py`. They
are near-white with an alpha channel and are tinted with theme colors in game. To regenerate:

```
python3 art/generate_textures.py
```

## Credits

- Typeface: [EB Garamond](https://github.com/octaviopardo/EBGaramond12) by Georg Duffner and
  Octavio Pardo, under the SIL Open Font License 1.1. The license is in `ParchmentUI/Fonts/OFL.txt`.
- Visual inspiration: Dialogue UI by Peterodox and Raenore. No code or artwork from it is used.
