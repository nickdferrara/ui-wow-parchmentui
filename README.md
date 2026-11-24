# ParchmentUI

An addon for World of Warcraft: Forever that restyles the main game windows as parchment
scrolls docked to the side of the screen, so they sit naturally next to
[Dialogue UI](https://www.curseforge.com/wow/addons/dialogueui).

Status: Milestone 0 (foundation). No window is skinned yet.

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
`/pui status`, `/pui audit`, `/pui reset`.
