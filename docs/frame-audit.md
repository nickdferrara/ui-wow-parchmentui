# ParchmentUI: Frame Audit

| | |
|---|---|
| Status | Not started. Nothing below has been confirmed in the live client. |
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
6. Confirm that both `/pui` and `/parchment` respond. If the addon does not load at all, check
   the TOC questions below first.

## Client facts to confirm

| Question | Source of the current assumption | Result |
|---|---|---|
| Is `ParchmentUI_Camelot.toc` loaded? | Release packager recognises the suffix | |
| Is `ParchmentUI_Forever.toc` honored as well? | Community notes | |
| Is `[AllowLoadGameType camelot]` honored per file? | Community notes | |
| Interface number reported by the client | PRD: 16001 | |
| `WOW_PROJECT_ID` value | PRD: 18 | |
| Does `UIPanelWindows` exist, and which area does each window use? | Mainline code family | |
| Does `C_AddOns.IsAddOnLoaded` exist? | Mainline code family | |
| Does `Settings.RegisterAddOnCategory` exist? | Mainline code family | |
| Is the Addon Compartment present? | Mainline code family | |

## Frames

| Window | Expected frame | Load on demand | Exists | Protected | Size | Panel area | Notes |
|---|---|---|---|---|---|---|---|
| Character Sheet | `CharacterFrame` | | | | | | |
| Paper doll | `PaperDollFrame` | | | | | | |
| Spellbook and Talents | `PlayerSpellsFrame` | `Blizzard_PlayerSpells` | | | | | |
| Group Finder | `LFDFrame` | | | | | | |
| Group Finder | `LFGFrame` | | | | | | |
| Skills | `SkillsFrame` | | | | | | |
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
