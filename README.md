# Dive Bar

**One frame for every bar you actually watch.**

A cast bar here, a swing timer addon there, an XP bar along the bottom edge, and a stack of Blizzard timers wherever they happen to land. Dive Bar replaces that clutter with one clean, consistent frame: your cast bar, swing timers, and experience line together, styled the same way and in the same place. Fewer addons to keep up to date, fewer bars to track, and more attention left for the fight.

Dive Bar is built for and tested on **WoW Forever**. The code also supports Classic Era, but Era gets far less testing.

## Features

- **A cast bar you can read at a glance.** Spell icon, spell name, and cast time are each optional, and latency is shown on the bar so you know when the next cast can start.
- **Swing timers built in.** Melee and ranged or wand swings each get their own timer, with an optional single-weapon mode. You don't need a separate swing timer addon.
- **An experience line that does more.** Rested XP and XP from quests you've completed but not turned in are both shown on the line, along with a time-to-level badge. XP per hour can appear in the tooltip.
- **Every other timer, in the same frame.** Breath, fatigue, and Feign Death appear in Dive Bar when they're running, then get out of the way.
- **A look that fits your UI.** Choose the Forever, Flat, or Classic theme, with optional rounded corners, and tune the size, padding, and opacity.
- **No doubled-up bars.** Turn each default Blizzard bar on or off through your active Edit Mode layout, so Dive Bar replaces the old bars instead of sitting next to them.
- **Profiles for your alts.** Give each character its own setup, or share one across all of them.
- A minimap button and an options window with a live preview of each bar.

## Installation

### CurseForge

Install with the CurseForge app (coming soon).

### Manual

1. Download the latest `DiveBar-*.zip` from [Releases](https://github.com/hashwagon/DiveBar/releases).
2. Extract it into the Forever client's AddOns folder so that you end up with `AddOns/DiveBar/DiveBar.toc`:
   - Windows: `C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns`
   - macOS: `/Applications/World of Warcraft/_forever_/Interface/AddOns`
3. Restart the game, or type `/reload` if you're already in game.

## Usage

Type `/divebar`, or click the minimap button, to open the options.

| Command | Effect |
| --- | --- |
| `/divebar` | Open or close the options window |
| `/divebar lock` / `unlock` | Lock or unlock the frame for moving |
| `/divebar reset` | Reset the current profile to its defaults |
| `/divebar minimap` | Show or hide the minimap button |
| `/divebar profile <name>` | Switch to a profile, creating it if it doesn't exist |
| `/divebar xpreset` | Reset the experience session (XP per hour, time to level) |

Settings are saved per account in `WTF/Account/<account>/SavedVariables/DiveBar.lua`.

## Development

The repository root is the addon folder. `DiveBar.toc` lists the load order.

To test changes, put a copy of the repository in your client's `Interface/AddOns/DiveBar`, either by copying the files or by symlinking the folder. Then `/reload` in game. Type `/console scriptErrors 1` to see Lua errors.

The included `deploy.sh` copies only the addon files (`.lua`, `.toc`, `.tga`, `.blp`) and needs `bash` and `rsync`. That means macOS, Linux, or WSL on Windows. Tell it where your AddOns folder is in either of these ways:

- Set the `DIVEBAR_DEST` environment variable.
- Put the path on one line in a `.deploy-dest` file at the repository root. Git ignores this file.

```bash
./deploy.sh            # sync into the AddOns folder
./deploy.sh --dry-run  # show what would change
```

`deploy.sh` mirrors with `rsync --delete`, so removing a file from the repository also removes it from the AddOns folder.

WoW runs Lua 5.1. Check syntax with `luac5.1 -p *.lua`; any `luac` catches most syntax errors.

### Files

| File | Purpose |
| --- | --- |
| `Logic.lua` | Pure layout and settings helpers (rows, padding, border math) |
| `Themes.lua` | Forever, Flat, and Classic themes |
| `Core.lua` | Saved variables, profiles, slash command |
| `Bar.lua` | Frame building, placement, painting, border, XP badge |
| `Cast.lua` | Cast state, event wiring, update loop |
| `Swings.lua` | Swing timers from gear and swing events |
| `Experience.lua` | XP, rested, quest XP, session rate, time to level |
| `Timers.lua` | Mirror timers |
| `Blizzard.lua` | Hiding the default Blizzard bars |
| `Minimap.lua` | Minimap button |
| `Options.lua` | Options window |

### Releasing

Releases are built by the [BigWigs packager](https://github.com/BigWigsMods/packager) in GitHub Actions (`.github/workflows/release.yml`).

- **Every push and pull request:** the workflow checks syntax and builds a test zip. The zip is attached to the workflow run as an artifact and isn't published.
- **A pushed `v*` tag:** the workflow publishes the zip to GitHub Releases and to any site with a token configured (CurseForge, Wago).

To make a release:

1. Set `## Version:` in `DiveBar.toc`, and add a section to `CHANGELOG.md`.
2. Commit, then tag with the same version, for example `git tag -a v1.3.0 -m "Dive Bar 1.3.0"`.
3. Push the tag with `git push origin v1.3.0`.

The tag must match the `.toc` version, or have a suffix after it: `v1.3.0-beta1` is allowed with a `.toc` version of `1.3.0`. Tags containing `alpha` or `beta` publish as test builds rather than releases.

## License

Dive Bar is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. See [`LICENSE`](LICENSE).
