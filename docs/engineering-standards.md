# ParchmentUI: Engineering Standards

These standards apply to every change in this repository. Read this document and
[`prd.md`](prd.md) before changing code. Where the two disagree, the PRD decides what is built
and this document decides how.

Items marked *unverified* depend on behavior of the Forever client that has not yet been
confirmed in game. They are settled by the Milestone 0 frame audit and this document is updated
with the result.

## 1. Definition of done

A change is done when all of the following are true:

1. `make check` passes locally (lint, format check, unit tests, TOC check). See section 9.
2. CI is green on the pull request.
3. Any change that affects what the player sees or clicks has been loaded in the live Forever
   client, and the pull request includes before and after screenshots.
4. Any change to a window module has been run against the relevant steps of the acceptance
   checklist in the PRD (section 12), including the combat steps.
5. Documentation is updated in the same pull request when behavior, options or supported
   windows change.

`make check` replaces any build command used in other projects. There is no compile step.

## 2. Language and runtime

- Lua 5.1 as embedded in the game client. No `goto`, no integer division operator, no bitwise
  operators, no `table.unpack` (use `unpack`).
- Target client: WoW: Forever only, Interface 16001, game type `camelot`.
- Use the `C_*` namespaces. Classic globals such as `GetSpellInfo`, `GetItemInfo` and
  `UnitAura` do not exist on this client.
- Never guess that an API exists. Check it against the live client or current documentation,
  and guard optional APIs with a nil check.
- No external libraries (Ace3, LibStub and similar) unless a pull request justifies the
  dependency and it is embedded with its license. The addon is small enough not to need them.

## 3. Repository layout

```
ParchmentUI/                addon root, exactly what ships to players
  ParchmentUI_Camelot.toc
  Core/                     init, saved variables, events, combat queue
  Theme/                    palette, fonts, texture registry
  Skin/                     shared widget skinners
  Layout/                   docking, stacking, scaling
  Windows/                  one file per Blizzard window
  Options/                  settings panel, slash commands
  Locales/
  Art/
  Fonts/
docs/
tests/                      busted specs and the WoW API stub
.github/workflows/
Makefile
.luacheckrc
stylua.toml
.pkgmeta
```

- Nothing outside `ParchmentUI/` ships to players.
- One Blizzard window per file in `Windows/`. A window file must not reference another window
  file.
- Dependencies point one way: `Windows` and `Options` may use `Layout`, `Skin`, `Theme` and
  `Core`. `Layout` and `Skin` may use `Theme` and `Core`. `Core` uses nothing.
- Load order in the TOC follows the same direction: Core, Locales, Theme, Skin, Layout,
  Windows, Options.

## 4. Code style

### 4.1 Formatting

- `stylua` is the only formatter. Its output is not debated in review.
- 4 spaces, 100 column limit, double quotes, Unix line endings, UTF-8 without BOM.

### 4.2 Namespacing and globals

- Every file starts with `local ADDON_NAME, ns = ...` and attaches its API to `ns`.
- The addon creates exactly these globals: `ParchmentUI_DB` (saved variables),
  `SLASH_PARCHMENTUI1`, `SLASH_PARCHMENTUI2`, and the Addon Compartment callback. Anything else
  is a defect.
- Blizzard globals a file reads are listed in `.luacheckrc`, not silenced inline.
- Cache a global in a local only inside a hot path. Do not add blocks of upvalue caching at the
  top of files.

### 4.3 Naming

| Thing | Convention | Example |
|---|---|---|
| Local variables, fields | `camelCase` | `dockOffset` |
| Functions, methods, modules, mixins | `PascalCase` | `ns.Layout.DockRight` |
| Constants | `UPPER_SNAKE_CASE` | `UNROLL_DURATION` |
| Files | `PascalCase.lua` | `Windows/Character.lua` |
| Created frames | prefix `ParchmentUI` if named at all | `ParchmentUIOptionsFrame` |
| Saved variable keys | `camelCase` | `db.windows.character.enabled` |
| Locale keys | `UPPER_SNAKE_CASE` | `L.OPTION_THEME_DARK` |

Prefer anonymous frames. Name a frame only when the game requires it.

### 4.4 Comments

- Comments explain why, not what. A comment is required wherever code exists to avoid taint,
  work around a client quirk, or defer for combat.
- No commented-out code. No author names, dates or change history in comments.
- Comments, like everything else in the repository, do not mention development tooling,
  assistants or automation vendors.

### 4.5 Functions and errors

- Keep functions short and single purpose. A window's `Skin` function that grows past about 60
  lines is split by region of the window.
- No user-facing string literals in code. All of them go through `ns.L`.
- Do not swallow errors silently. Window modules are called through `xpcall` by Core, which
  logs once and disables that window for the session. Inside a module, let errors propagate.
- Messages to the player go through one `ns.Print` helper, prefixed with the addon name, and
  are rate limited to one per cause per session.

## 5. Working with Blizzard frames

These rules exist to prevent taint and blocked actions. They are not style preferences, and a
pull request that breaks one is not merged.

### 5.1 Never do

- Never replace or overwrite a Blizzard function, method, mixin field or global. Use
  `hooksecurefunc` and `HookScript` only. `SetScript` on a Blizzard frame is forbidden.
- Never call `ShowUIPanel`, `HideUIPanel`, `ToggleCharacter` or any other panel-opening function
  from addon code. The addon reacts to windows opening. It does not open them.
- Never write a field onto a Blizzard frame or table. Keep addon state in a weak-keyed table
  owned by the addon, keyed by frame.
- Never read unit health, power, auras, cooldowns or combat log data. The addon has no need for
  secret values and must not touch them.
- Never call `SetParent`, `SetPoint`, `ClearAllPoints`, `SetSize`, `SetScale`, `Show` or `Hide`
  on a protected frame, or on a frame with protected children, while `InCombatLockdown()` is
  true.

### 5.2 Always do

- Route every layout change through `ns.Combat.RunWhenSafe(fn)`. It runs immediately out of
  combat and queues until `PLAYER_REGEN_ENABLED` otherwise. Queued work is keyed, so the same
  request made twice runs once.
- Hide stock art with `SetAlpha(0)` or `SetTexture(nil)` on the texture region. Do not destroy
  it, and do not `Hide` regions that Blizzard code shows again on update.
- Skin load-on-demand windows from `ADDON_LOADED` for the owning Blizzard addon, and also check
  whether it is already loaded at startup.
- Nil check every Blizzard frame, child key and region before use. A missing frame disables that
  part of the skin. It never raises an error.
- Make every skin idempotent. Running `Skin` twice must not stack textures or hooks. Track
  applied state per frame.
- Animate only regions the addon created, and alpha. Skip animation during combat.

### 5.3 Positioning

The mechanism for docking windows on the right (panel attributes versus a post-layout hook) is
*unverified* and decided by the Milestone 0 spike. Until then, no window module contains its own
positioning code. All of it goes through `ns.Layout`, so the mechanism can change in one place.

### 5.4 Window module contract

Each file in `Windows/` registers one descriptor and contains nothing else at file scope:

```lua
local ADDON_NAME, ns = ...

ns.Windows.Register({
    id = "character",                 -- saved variable key and option id
    frameName = "CharacterFrame",     -- global name of the Blizzard frame
    loadOnDemand = nil,               -- Blizzard addon name, or nil if always loaded
    Skin = function(frame, theme) end,
    Layout = function(frame, dock) end,
})
```

Core decides when `Skin` and `Layout` are called. A module does not register its own events
unless the window needs a refresh hook that Core cannot provide, and that is explained in a
comment.

## 6. Saved variables

- One account-wide table, `ParchmentUI_DB`, with a top-level integer `schemaVersion`.
- Defaults live in one file. Stored data holds only values that differ from the defaults.
- Any change to the shape of stored data adds a numbered migration function and a unit test for
  it. Migrations run in order at `ADDON_LOADED` and are never edited after release.
- Never store frame references, functions or anything derived from game state.

## 7. Assets

- Textures: TGA (32-bit, uncompressed) or BLP, power-of-two dimensions, largest side 1024.
  Borders are built for nine-slice scaling.
- Every texture is registered in `Theme/Textures.lua` and referenced by key. No file paths in
  window modules.
- All artwork is original to this project. Nothing is copied or traced from Dialogue UI, other
  addons or the game's own art files.
- Fonts must be under the SIL Open Font License or an equivalent, with the license file next to
  the font. Any font must cover the Latin Extended range. Other scripts fall back to the client
  font for that locale.
- Source files for artwork (layered originals) are kept out of `ParchmentUI/` so they do not
  ship.

## 8. Testing

### 8.1 Automated

- Framework: `busted`, with a minimal WoW API stub in `tests/stub/`.
- Unit tests cover logic that does not need a real client: saved variable defaults and
  migrations, the combat queue, dock and stacking math, theme and palette resolution, locale
  fallback, window registry behavior including the failure path.
- The stub implements only what tests need. Do not grow it into a client emulator, and do not
  write tests that only assert the stub was called.
- A TOC check verifies that every file listed exists, every Lua file under `ParchmentUI/` is
  listed, and the Interface number matches the value in this document.

### 8.2 Manual

- Visual results, taint and combat behavior can only be verified in game. The acceptance
  checklist in the PRD is the manual test plan.
- Test with `/console scriptErrors 1` and `/console taintLog 1`. A new entry naming
  ParchmentUI in `Logs/taint.log` blocks the merge.
- Bug fixes for in-game defects state the reproduction steps and the client build number in the
  pull request.

## 9. Tooling

| Command | Does |
|---|---|
| `make lint` | `luacheck ParchmentUI tests` |
| `make format` | `stylua ParchmentUI tests` |
| `make format-check` | `stylua --check ParchmentUI tests` |
| `make test` | `busted` |
| `make toc-check` | validates the TOC against the file tree |
| `make check` | all of the above except `format` |
| `make package` | builds the release zip into `.release/` |

- `luacheck` runs with the `lua51` standard and zero warnings allowed. Inline `luacheck: ignore`
  needs a comment giving the reason.
- Tool versions are pinned in CI and in the environment setup so results match everywhere.

## 10. Git workflow

- `main` is protected, always releasable, and only changed by pull request.
- Branch names: `feat/<topic>`, `fix/<topic>`, `chore/<topic>`, `docs/<topic>`,
  `refactor/<topic>`, `test/<topic>`. Lowercase, hyphenated.
- Commits follow [Conventional Commits](https://www.conventionalcommits.org/):
  `type(scope): summary`. Summary in the imperative, lowercase, no trailing period, 72
  characters or fewer.
- Scopes: `core`, `theme`, `skin`, `layout`, `options`, `locale`, `art`, `ci`, `docs`, or a
  window id such as `character`, `spellbook`, `talents`, `groupfinder`.
- A breaking change to saved variables or options uses `!` and a `BREAKING CHANGE:` footer.
- Commits are authored under the repository owner's identity, with no co-author or attribution
  trailers.
- Commits, branch names, pull request titles and descriptions, code and documentation contain
  no references to development tooling, assistants or automation vendors.
- One logical change per pull request. Squash merge, with the pull request title as the commit
  message.

Examples:

```
feat(character): skin paper doll background and tabs
fix(layout): defer dock update until combat ends
chore(ci): pin luacheck version
```

## 11. Pull requests

A pull request description contains:

1. What changed and why, in a few sentences.
2. How it was tested: `make check` result, and for visual or behavioral changes the client
   build number and the checklist steps run.
3. Before and after screenshots for anything visual.
4. Any new *unverified* assumption about the client, so it can be tracked.

Review checks, in order: section 5 rules, the module contract, tests for new logic, then style.

## 12. Versioning and release

- Semantic Versioning. `MAJOR` for breaking saved variable or option changes, `MINOR` for new
  windows or features, `PATCH` for fixes and client compatibility updates.
- The TOC `## Version` is injected from the git tag at packaging time. It is not edited by hand.
- A release is made by pushing a tag `vX.Y.Z` on `main`. CI packages the zip and publishes a
  GitHub Release with notes generated from the commit history.
- After every Forever client patch: confirm the Interface number, rerun the acceptance
  checklist, and ship a `PATCH` release even if only the TOC changed.

## 13. Security and privacy

- No secrets in the repository. Upload tokens exist only as CI secrets.
- The addon sends nothing over addon channels or chat without a direct player action, and
  collects no data about the player.
- Third-party code and assets are added only with a compatible license and a license file.
