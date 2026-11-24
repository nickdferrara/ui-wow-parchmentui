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

## Source review

The Forever interface source for 1.60.1 is published in the `Gethe/wow-ui-source` mirror and was
read on 2026-11-24. It is the code the client runs, so it is stronger evidence than the wiki,
but taint, combat behavior and what is actually on screen still need the live client. Nothing
from that source is copied into this repository.

### Windows

| Window | Frame | Owning addon | Panel area | Size in XML | Structure |
|---|---|---|---|---|---|
| Character Sheet | `CharacterFrame` | `Blizzard_UIPanels_Game`, always loaded | `left`, pushable 3 | 398 wide, width changes with the side pane | Inherits `PortraitFrameBaseTemplate`. Children: `CloseButton`, `LeftPaneHost`, `RightPaneHost`, `RightPaneToggleButton`, `ModeTabs`, `CharacterStatsPane`. |
| Paper doll | `PaperDollFrame` | same | child of `CharacterFrame` | | `ItemsFrame` (`PaperDollItemsFrame`), `CharacterModelScene`, `TitleManagerPane`, `EquipmentManagerPane`, `PaperDollSidebarTabs`. Slots are `ItemButton`s from `PaperDollItemSlotButtonTemplate`. |
| Reputation | `ReputationFrame` | same | child of `CharacterFrame` | | `ScrollBox`, `ScrollBar`, `filterDropdown`, `ReputationDetailFrame`. |
| Skills | `SkillsFrame` | same | child of `CharacterFrame` | | `ScrollBox`, `ScrollBar`, `SkillDetailFrame`. It is a tab of the Character Sheet, not a window of its own. |
| Spellbook and Talents | `PlayerSpellsFrame` | `Blizzard_PlayerSpells`, load on demand | `centerOrLeft`, pushable 3, `checkFit` | 1154 x 883 | Inherits `PortraitFrameTemplate`. Children: `TabSystem`, `SpecFrame`, `TalentsFrame`, `SpellBookFrame`, `MaximizeMinimizeButton`. Has a minimized mode that switches its area to `left`. |
| Group Finder | `LFGParentFrame` | `Blizzard_GroupFinder_VanillaStyle`, load on demand | shown with `ShowUIPanel` | 458 x 535 | `Tab1` to `Tab3`, `ListingTab`, `BrowsingTab`, `WhoListingTab`. Does not inherit a portrait frame template. |
| Legacy System | `LegacySystemFrame` | `Blizzard_LegacySystem`, load on demand | `left`, pushable 1, `checkFit`, width 1005 | 920 x 575 | Inherits `PortraitFrameTemplate`. Three tabs and three pages: `RewardTrackPage`, `ChallengesPage`, `TreePage`. |
| Social | `FriendsFrame` | not reviewed | `left` | | Still listed in the panel table. |
| Merchant, Mail | `MerchantFrame`, `MailFrame` | not reviewed | `left` | | Still listed in the panel table. |

No `protected` attribute and no secure template appears in the XML of the Character Sheet,
paper doll, Skills, Reputation, Spellbook, Group Finder or Legacy System frames. That suggests
these windows are not protected and could be moved in combat, but templates they inherit were
not all read, so `/pui audit` must confirm it.

### How the panel manager positions windows

From `Blizzard_UIParentPanelManager`:

- Panels occupy `left`, `center` and `right` slots, each anchored by `TOPLEFT` to the top left of
  the screen. There is no slot on the right edge. A second panel is placed to the right of the
  first.
- Layout origins are attributes on a frame named `UIPanelLayoutFrame`: `LEFT_OFFSET` (16),
  `TOP_OFFSET` (-116), `CENTER_OFFSET`, `RIGHT_OFFSET`, `PANEl_SPACING_X` (32). They are read
  through `GetUIPanelLayoutAttribute` and written through `SetUIPanelLayoutAttribute`, both
  global functions. `CENTER_OFFSET` and `RIGHT_OFFSET` are recomputed on every layout pass.
  `LEFT_OFFSET` and `TOP_OFFSET` are only ever read.
- Per-panel settings are frame attributes named `UIPanelLayout-<name>`, such as `xoffset`,
  `yoffset`, `width` and `area`, written with the global `SetUIPanelAttribute(frame, name, value)`.
  Blizzard code calls it at run time, for example to change the Character Sheet's width.
- `ShowUIPanel` and `HideUIPanel` hand the frame to a forbidden delegate frame through
  attributes, and the delegate does the anchoring in secure code. They refuse to run for addon
  code in combat and show the "action blocked" message.
- The delegate positions frames by calling the global `UpdateUIPanelPositions`, so a
  `hooksecurefunc` on that function runs after every layout pass.
- `ShowUIPanel` and `HideUIPanel` fire `UIParentPanelManager.ShowUIPanel` and
  `UIParentPanelManager.HideUIPanel` through `EventRegistry`. The Character Sheet also fires
  `CharacterFrame.Show` and `CharacterFrame.Hide`.

### What this means for the design

1. **Docking on the right is not something the panel manager offers.** Both candidate mechanisms
   remain, and the source makes them concrete:
   - *Panel attributes:* set a panel's `xoffset` and `yoffset` so the manager itself places it at
     the right edge, vertically centered. The manager would then keep doing so in combat, with
     no deferral. The risk is whether an attribute written by addon code taints the secure
     layout pass.
   - *Post-layout hook:* hook `UpdateUIPanelPositions` and re-anchor the window afterwards, out
     of combat only. In combat a window would open at the stock position and move when combat
     ends.
2. **Two docked windows side by side (FR-7) work against the manager.** It places the second
   panel to the right of the first and closes panels that do not fit. Putting the second
   window to the left of the first needs the hook approach or a decision to drop FR-7.
3. **The Spellbook and Talents window is not tall and narrow.** It is 1154 by 883 at full size
   and prefers the center of the screen. It cannot be a narrow scroll at the screen edge unless
   it is kept in its minimized mode, and the talent tree may not fit that. This needs a product
   decision.
4. **The Legacy System window is wide too**, at about 1000 units.
5. **Skills is a tab of the Character Sheet.** It comes with the Character Sheet skin and does
   not need its own window module.

## Positioning spike

Goal: prove one P0 window can be docked to the right edge with no taint, in and out of combat.

| Approach | Tried | Taint log clean | Works in combat | Two windows side by side | Notes |
|---|---|---|---|---|---|
| Panel attributes | | | | | |
| Post-layout hook, deferred in combat | | | | | |

Decision: pending.
