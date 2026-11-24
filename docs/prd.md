# ParchmentUI: Product Requirements Document

| | |
|---|---|
| Repository | `nickdferrara/ui-wow-parchmentui` |
| Addon folder name | `ParchmentUI` |
| Status | Draft |
| Last updated | 2026-11-24 |
| Target client | World of Warcraft: Forever (`_forever_`, Interface 16001) |

## 1. Summary

ParchmentUI is an addon for World of Warcraft: Forever that restyles and repositions the main
Blizzard windows (Character Sheet, Spellbook, Talents, Group Finder and others) so they look and
behave like one family with the Dialogue UI addon: a parchment scroll that unrolls on the right
side of the screen.

Players who use Dialogue UI get an immersive scroll for quests and gossip, then open their
character sheet and are dropped back into the stock grey panels on the left. ParchmentUI closes
that gap.

## 2. Goals

1. Every supported window renders on a parchment scroll surface with consistent fonts, colors,
   borders and spacing.
2. Supported windows open anchored to the right side of the screen, vertically centered, with a
   short unroll animation.
3. All stock functionality of each window keeps working, in and out of combat, with no taint
   errors and no blocked actions.
4. The look sits naturally next to Dialogue UI (light and dark themes) without requiring it.
5. Each window can be switched off individually, so a broken skin after a game patch never locks
   a player out of a window.

## 3. Non-goals

- Replacing quest, gossip or book windows. Dialogue UI already owns those.
- Rebuilding windows from scratch. ParchmentUI skins and re-anchors the Blizzard frames; it does
  not reimplement the paper doll, talent logic or group finder logic.
- Action bars, unit frames, nameplates, minimap, tooltips or chat.
- Any combat information, automation, or anything touching secret values.
- Support for Retail (Midnight) or Classic clients in the first release. The TOC must keep the
  addon from loading there.
- Redistributing any Dialogue UI code, textures or fonts.

## 4. Target platform

Facts below were gathered on 2026-11-24. Items marked *unverified* come from community sources
and must be confirmed in the live client during Milestone 0. Items marked *documented* were
checked against warcraft.wiki.gg on the same date and still need confirming in the client. The
details are in `docs/frame-audit.md`.

| Item | Value |
|---|---|
| Client | WoW: Forever, install folder `_forever_` |
| Interface | `16001` (client 1.60.1) |
| Game type | `camelot`, with `forever` accepted as an alias |
| Code family | Mainline (shared with Midnight), with Forever overrides |
| `WOW_PROJECT_ID` | `WOW_PROJECT_CAMELOT` (18) *documented* |
| Detection rule | Interface in 16000 to 16999. Do not test for `>= 100000`. |

TOC requirements:

- Ship `ParchmentUI_Camelot.toc`. `_Forever.toc` is *documented* as an alias; test both.
- Gate files with `[AllowLoadGameType camelot][ExcludeLoadGameType standard, classic]` so the
  addon stays inert on other clients. The exclusion is needed because clients that do not know
  `camelot` treat the allow list as satisfied.
- `## Interface: 16001`
- `## OptionalDeps: DialogueUI`
- `## SavedVariables: ParchmentUI_DB`

API constraints that shape the design:

- Classic globals such as `GetSpellInfo`, `GetItemInfo` and `UnitAura` do not exist. Use the
  `C_*` namespaces.
- Midnight's secret value rules apply. ParchmentUI never reads unit health, power, auras or
  combat log data.
- Calling `ShowUIPanel`, `ToggleCharacter` and similar functions from addon code has been
  reported to taint. ParchmentUI never opens or closes Blizzard panels itself; it only reacts
  to them with `hooksecurefunc` and `HookScript`.
- Frames with protected children (equipment slots, spell buttons) cannot be moved or resized in
  combat. All layout changes are applied out of combat, and deferred to `PLAYER_REGEN_ENABLED`
  when requested during combat.

## 5. Reference: Dialogue UI

Source: [CurseForge](https://www.curseforge.com/wow/addons/dialogueui),
[GitHub](https://github.com/Peterodox/YUI-Dialogue). Authors: Peterodox, Raenore.

What we are matching:

- Warm parchment surface with soft, torn or rolled edges instead of a metal window border.
- Tall, narrow panel docked to the right side of the screen, leaving the character visible.
- Dark brown ink text on the light theme, pale text on the dark theme, generous line spacing.
- Light and Dark quest themes, plus Parchment and Metal book styles.
- Adjustable font size, keyboard and gamepad friendly.
- Dialogue UI already supports Forever (its TOC lists Interface 16001 and the Camelot game type).

Licensing: no license was found for Dialogue UI, so it is treated as all rights reserved.
ParchmentUI uses original artwork and openly licensed fonts only. See Open Questions for the
option of asking the authors for permission to reference their textures at runtime.

## 6. Users and key stories

Primary user: a Forever player who runs Dialogue UI and wants the rest of the interface to match.

- As a player, when I press `C`, my character sheet unrolls as a scroll on the right side of the
  screen, and I can still equip, unequip and inspect stats exactly as before.
- As a player, when I open my spellbook or talents, I get the same scroll, in the same place,
  with the same fonts as my quest text.
- As a player, I can open two windows together (for example character and bags) without them
  overlapping in an unusable way.
- As a player, I can pick a light or dark theme, or have it follow my Dialogue UI theme.
- As a player, if one window looks wrong after a patch, I can turn off just that skin and keep
  playing.
- As a player in combat, opening a window never produces an "action blocked" error.

## 7. Functional requirements

### 7.1 Window coverage

Frame names are *unverified* until the Milestone 0 audit, which produces the authoritative list
in `docs/frame-audit.md`.

| Priority | Window | Expected frame | Notes |
|---|---|---|---|
| P0 | Character Sheet | `CharacterFrame`, `PaperDollFrame` | Includes reputation and currency tabs |
| P0 | Spellbook | `PlayerSpellsFrame` | Load on demand (`Blizzard_PlayerSpells`) |
| P0 | Talents | `PlayerSpellsFrame.TalentsFrame` | Uses `C_Traits`; legacy panel unlocks at level 25 |
| P0 | Group Finder / LFG | `LFGParentFrame` | Vanilla-style group finder. `LFDFrame` functions were removed in 1.60.1 *(documented)* |
| P1 | Skills / Professions list | `SkillsFrame` | |
| P1 | Social | `SocialUIFrame`, `FriendsFrame` | Forever replaces part of the Friends window |
| P1 | Quest Log | To be identified | |
| P1 | Legacy System | To be identified | Forever's replacement for achievements, opened by `ToggleLegacySystemUI` *(documented)* |
| P2 | Merchant, Bank, Mail | `MerchantFrame`, `BankFrame`, `MailFrame` | |
| P2 | Professions crafting, Auction House | To be identified | |

### 7.2 Scroll skin

- FR-1: Replace each window's stock background, border, portrait ring and title bar art with the
  parchment surface: rolled top and bottom edges, torn side edges, a title set in the heading
  font.
- FR-2: Restyle child widgets to match: tabs become ribbon or bookmark tabs on the scroll edge,
  buttons become ink-outlined buttons, scroll bars become a thin ink line, inset panels lose
  their metal bevel.
- FR-3: Stock textures are hidden, not destroyed, so a skin can be turned off cleanly with a UI
  reload.
- FR-4: Text colors are remapped for contrast on parchment. Minimum contrast ratio 4.5:1 for body
  text in both themes. Item quality colors keep their hue but are darkened on the light theme.
- FR-5: Themes: Light Parchment, Dark Parchment, and "Match Dialogue UI" (only offered when
  Dialogue UI is loaded).

### 7.3 Positioning

- FR-6: Skinned windows anchor to the right edge of the screen, vertically centered, with a
  configurable horizontal offset.
- FR-7: When two skinned windows are open, the second sits to the left of the first. A third
  replaces the second.
- FR-8: Positioning must work with the Blizzard panel manager, not against it. The exact
  mechanism (panel attributes versus a post-layout hook) is decided by the Milestone 0 spike.
- FR-9: Windows respect UI scale and stay fully on screen at 1280x720 and above, including
  ultrawide. If a window is taller than the screen it is scaled down, never clipped.
- FR-10: If Dialogue UI's window is open at the same time, ParchmentUI windows sit to its left.
- FR-11: Left-side docking is available as an option.

### 7.4 Animation

- FR-12: Opening plays an unroll and fade (default 0.25 s). Closing plays the reverse.
- FR-13: Animations affect alpha and non-protected texture regions only, and are skipped during
  combat.
- FR-14: Animations can be disabled.

### 7.5 Settings

- FR-15: A settings category registered with the game's Settings panel, plus `/parchment` and
  `/pui` slash commands and an Addon Compartment entry.
- FR-16: Options: theme, per-window enable toggles, dock side, horizontal offset, scale, font
  size, animation on or off and speed.
- FR-17: Settings are account wide, stored in `ParchmentUI_DB` with a schema version and
  migration step.
- FR-18: "Reset to defaults" restores everything and prompts for a reload when needed.

### 7.6 Safety and compatibility

- FR-19: No taint: no `ADDON_ACTION_BLOCKED` or `ADDON_ACTION_FORBIDDEN` events attributable to
  ParchmentUI in the acceptance test pass.
- FR-20: Each window skin is an isolated module wrapped in `xpcall`. A failing skin logs one
  message, disables itself for the session, and leaves the stock window working.
- FR-21: Load-on-demand windows are skinned when their addon loads (`ADDON_LOADED`), not at login.
- FR-22: If another known skinning addon is managing a window, ParchmentUI skips that window and
  says so once in chat.

## 8. Non-functional requirements

- Performance: under 2 ms added to opening any window, no `OnUpdate` handlers while idle, memory
  under 2 MB excluding textures.
- Localization: all strings go through a locale table. English ships first.
- Accessibility: font size option from 100% to 150%, contrast targets in FR-4, no information
  carried by color alone.
- Assets: original parchment textures as TGA or BLP with power-of-two dimensions, built for nine
  slice scaling. Fonts under the SIL Open Font License, with license files in the repository.
- Code quality: Lua 5.1 compatible, zero `luacheck` warnings, formatted with `stylua`.

## 9. Technical approach

```
ParchmentUI/
  ParchmentUI_Camelot.toc
  Core/        init, saved variables, event bus, combat-deferred queue
  Theme/       palette, fonts, texture atlas, theme switching
  Skin/        shared widget skinners (tabs, buttons, scroll bars, insets)
  Layout/      right-side dock, stacking, scaling
  Windows/     one file per window: Character.lua, Spellbook.lua, Talents.lua, GroupFinder.lua
  Options/     settings panel and slash commands
  Locales/
  Art/
  Fonts/
docs/          prd.md, engineering-standards.md, frame-audit.md
tests/         busted specs with a stubbed WoW API
```

Each file in `Windows/` registers a descriptor: the frame name, the load-on-demand addon it
belongs to, a `Skin` function and a `Layout` function. Core handles when to call them. This keeps
window modules small and makes FR-20 straightforward.

## 10. Development environment and workflow

Development happens in a hosted cloud development environment connected to the GitHub
repository. The environment is disposable: every session starts from a fresh clone, so anything
worth keeping is committed and pushed.

- **Toolchain**, installed by the environment's setup script: Lua 5.1, LuaRocks, `luacheck`,
  `busted`, `stylua`, and the BigWigs packager for building release zips.
- **Network allowlist**: `github.com`, `raw.githubusercontent.com`, `warcraft.wiki.gg`,
  `www.curseforge.com`, `luarocks.org`. No secrets are needed for development. Release upload
  tokens live in GitHub Actions secrets only.
- **What can be verified in the cloud**: lint, formatting, unit tests against a stubbed WoW API,
  TOC validation, packaging.
- **What cannot**: the cloud environment has no game client. Visual results, taint, combat
  behavior and animation timing are verified by hand in the live Forever client using the
  checklist in section 12. Every pull request that changes visuals includes before and after
  screenshots from the game.
- **Local test loop**: download the packaged zip from the pull request's CI run (or pull the
  branch) into `_forever_/Interface/AddOns/ParchmentUI`, then `/reload`.

Repository conventions:

- Branches: `feat/...`, `fix/...`, `chore/...`, `docs/...`. `main` is protected and always
  releasable.
- Commits follow Conventional Commits.
- Commits, branch names, pull requests, code comments and documentation contain no references
  to development tooling, assistants or automation vendors. Commits are authored under the
  repository owner's identity.
- CI (GitHub Actions) runs `luacheck`, `stylua --check`, `busted` and a packaging dry run on
  every pull request. All four are required to merge.
- Releases are created by pushing a version tag. CI builds the zip and attaches it to a GitHub
  Release. CurseForge and Wago upload is added once the project is published there.

## 11. Milestones

| # | Milestone | Outcome |
|---|---|---|
| M0 | Foundation and spike | Repository, CI and environment in place. Frame audit written from the live client. Positioning spike proves a P0 window can dock right with no taint. |
| M1 | Theme and Character Sheet | Parchment art, fonts, shared widget skinners, Character Sheet fully skinned and docked. |
| M2 | Spellbook and Talents | `PlayerSpellsFrame` skinned, including the talent tree and legacy panel. |
| M3 | Group Finder | LFG window skinned and docked. |
| M4 | Settings and polish | Options panel, themes, animation, Dialogue UI theme matching, multi-window stacking. |
| M5 | Release 1.0 | P0 windows pass the full acceptance checklist. Published. |
| M6 | P1 and P2 windows | Skills, Social, Quest Log, Legacy System, then Merchant, Bank, Mail and the rest. |

## 12. Acceptance checklist (run in the live client per release)

1. Fresh character below level 25 and a character above it: open every supported window. No Lua
   errors with `scriptErrors` enabled.
2. Equip, unequip and swap gear from the Character Sheet. Drag a spell to an action bar. Spend
   and refund a talent point. Queue and leave a group.
3. Repeat step 2 while in combat where the game allows it. Open and close every window in
   combat. No blocked action messages.
4. Check at UI scale 0.65, 1.0 and 1.15, at 1280x720, 1920x1080 and 3440x1440.
5. Open with Dialogue UI installed and active, installed and idle, and not installed.
6. Toggle each per-window option off and on. Reset to defaults.
7. Light and dark themes: all text readable, no stock grey textures showing through.

## 13. Success metrics

- Zero taint or blocked-action reports traceable to ParchmentUI in the first month.
- All P0 windows skinned with no stock textures visible.
- Compatibility fix released within 7 days of any Forever patch that breaks a skin.

## 14. Risks

| Risk | Impact | Mitigation |
|---|---|---|
| Moving or reskinning protected windows causes taint | Blocked actions in combat | M0 spike before any art work. Hooks only, combat-deferred layout, per-window kill switch. |
| Forever frame names and layouts differ from community notes | Rework | Frame audit from the live client is the first deliverable. |
| Forever patches change frames often while the game is new | Broken skins | Isolated window modules, defensive nil checks, fast patch releases. |
| Game type or Interface number changes at a future patch | Addon stops loading | Detection by interface range, TOC reviewed on every patch. |
| Blizzard tightens addon restrictions | Features removed | Cosmetic only, no combat data, no secret values. |
| Art looks too close to Dialogue UI's assets | Licensing complaint | Original artwork only. Credit Dialogue UI as inspiration. |
| No game client in the development environment | Visual bugs slip through | Screenshot requirement on pull requests, manual checklist per release. |

## 15. Open questions

1. Should we ask the Dialogue UI authors for permission to reference their textures at runtime
   when their addon is installed? This would give an exact visual match with no redistribution.
2. Final list of P1 and P2 windows, to be settled after the frame audit.
3. Will the addon be published on CurseForge and Wago, or kept on GitHub only?
4. Is the right-side dock position fixed, or should players be able to drag windows and have the
   position remembered?
5. Does the Forever panel manager allow two side-by-side panels on the right without taint? The
   M0 spike answers this, and FR-7 depends on it.
