# ParchmentUI: Frame Audit

| | |
|---|---|
| Status | Documentation review done on 2026-11-24. Nothing has been confirmed in the live client yet. |
| Client build | To be recorded |
| Audited on | To be recorded |

This document is the authoritative list of Blizzard frames that ParchmentUI skins on WoW:
Forever. It is filled in from the live client during Milestone 0. Until a row is marked
confirmed, no window module is written against it.

## How to run the audit

1. Install the addon from the current branch into `_forever_/Interface/AddOns/ParchmentUI`.
2. Run `/console scriptErrors 1` and `/console taintLog 1`, then `/reload`.
3. Out of combat, with every window closed, run `/pui audit` and record the output.
4. Open the spellbook and the talent window once so their load-on-demand addons load, then run
   `/pui audit` again.
5. For each window, open it and run `/fstack` to find the frame under the cursor. Record the
   top-level frame, its tabs and its child regions that carry stock art.
6. Run `/pui preview`. A sample scroll should unroll at the right edge. Note whether the
   parchment, the rolled ends and the typeface appear, then try `/pui theme dark`,
   `/pui side left` and `/pui font 150` while it is open.
7. Confirm that both `/pui` and `/parchment` respond. If the addon does not load at all, check
   the TOC questions below first.

## Client facts to confirm

The "Documentation" column records what warcraft.wiki.gg said on 2026-11-24, mainly the
[TOC format](https://warcraft.wiki.gg/wiki/TOC_format) page and the
[Patch 1.60.1 API changes](https://warcraft.wiki.gg/wiki/Patch_1.60.1/API_changes) page. The
"In game" column stays empty until the fact has been seen in the live client. Documentation is
evidence, not confirmation.

| Question | Documentation | In game |
|---|---|---|
| Is `ParchmentUI_Camelot.toc` loaded? | Yes. `_Camelot` is the TOC suffix for the game type. | |
| Is `ParchmentUI_Forever.toc` honored as well? | Yes. `forever` was added as an alias of `camelot` in build 70291, for both the game type and the TOC suffix. A footnote says `Camelot` may be renamed to `Forever` later. | |
| Is `[AllowLoadGameType camelot]` honored per file? | Yes, inline directives are supported on Forever. Clients that do not know `camelot` treat the allow list as satisfied, so it must be paired with `[ExcludeLoadGameType standard, classic]`. The TOC does this. | |
| Interface number reported by the client | `16001` for 1.60.1. The documented range check is above 16000 and below 20000. | |
| `WOW_PROJECT_ID` value | `WOW_PROJECT_CAMELOT` is 18, added in build 70170. | |
| Code base | 1.60.1 "includes all Modern changes up to 12.1.5", so mainline APIs apply unless the change list removes them. | |
| Does `UIPanelWindows` exist, and which area does each window use? | Not documented for Forever. `ShowUIPanel` is not in the removed list. | |
| Does `C_AddOns.IsAddOnLoaded` exist? | Documented as `loadedOrLoading, loaded = C_AddOns.IsAddOnLoaded(name)`. Not in the removed list. | |
| Does `Settings.RegisterAddOnCategory` exist? | Part of the Settings API since 10.0.0, changed in 11.0.2. Not in the removed list. | |
| Is the Addon Compartment present? | Yes. The TOC page marks the `AddonCompartmentFunc` directives as supported on Forever. | |
| Does `SetTextureSliceMargins` exist? | Added to textures in 10.2.0. No widget methods were removed in 1.60.1. | |
| Does calling `ShowUIPanel` from addon code cause problems? | It is protected in combat since 8.2.0: an addon call shows "action blocked". This supports the rule that the addon never opens panels itself. | |

## Frames

The "Notes" column holds what the 1.60.1 API change list implies. It lists functions that were
added and removed, not frames, so each frame name below is still an inference.

| Window | Expected frame | Load on demand | Exists | Protected | Size | Panel area | Notes |
|---|---|---|---|---|---|---|---|
| Character Sheet | `CharacterFrame` | | | | | | `CharacterFrame_GetTab` was added, so the frame is present with changed tabs. |
| Paper doll | `PaperDollFrame` | | | | | | Many `PaperDollFrame_Set...` stat functions and an ammo slot were added. Expect a Classic-style stat layout plus a sidebar. |
| Spellbook and Talents | `PlayerSpellsFrame` | `Blizzard_PlayerSpells` | | | | | Nothing named `PlayerSpells` was removed. New `C_SpellBook` functions mention low spell ranks. |
| Group Finder | `LFGParentFrame` | | | | | | Most likely candidate. `LFGParentFrame`, `LFGListing` and `LFGBrowse` functions were added with `ToggleGroupFinderFrame` and `GroupFinderVanillaStyle_LoadUI`, which suggests it is load on demand. |
| Group Finder | `LFGListingFrame`, `LFGBrowseFrame` | | | | | | Likely the tabs inside `LFGParentFrame`. |
| Group Finder | `LFDFrame`, `PVEFrame`, `GroupFinderFrame` | | | | | | Functions for all three were removed. Do not expect these frames. |
| Skills | `SkillsFrame` | | | | | | `PaperDollFrame_SetWeaponSkill` was added. `ProfessionsBookFrame` functions were removed. |
| Legacy System | `LegacySystemFrame` | Yes, addon name unknown | | | | | `ToggleLegacySystemUI` and `LegacySystemFrame_LoadUI` were added. Forever's replacement for achievements, with Rewards, Challenges and Trees sections. Unlocks with the first Legacy Point, likely at level 25, so audit it on a character that has one. P1 in the PRD. |
| Social | `SocialUIFrame` | | | | | | |
| Social | `FriendsFrame` | | | | | | |
| Merchant | `MerchantFrame` | | | | | | |
| Bank | `BankFrame` | | | | | | |
| Mail | `MailFrame` | | | | | | |
| Quest Log | To be identified | | | | | | |
| Professions crafting | To be identified | | | | | | |
| Auction House | To be identified | | | | | | |

## Positioning spike

Goal: prove one P0 window can be docked to the right edge with no taint, in and out of combat.

| Approach | Tried | Taint log clean | Works in combat | Two windows side by side | Notes |
|---|---|---|---|---|---|
| Panel attributes | | | | | |
| Post-layout hook, deferred in combat | | | | | |

Decision: pending.
