# Dive Bar

A World of Warcraft addon: one player frame with a cast bar, breath/fatigue/Feign Death timers, swing timers, and an experience line with a time-to-level badge.

The repo root is the addon folder. `DiveBar.toc` lists the load order.

## Live deploys and testing: WoW Forever

The live copy is the **Forever** client:

```
~/Games/battlenet/drive_c/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns/DiveBar
```

Edit here, then deploy:

```bash
./deploy.sh            # copy .lua/.toc (and any .tga/.blp) to the Forever AddOns folder
./deploy.sh --dry-run  # show what would change
```

`deploy.sh` mirrors with `rsync --delete`, so files removed here are removed from the live folder too. Set `DIVEBAR_DEST` to deploy somewhere else.

In game, `/reload` picks up the changes. `/divebar` or the minimap button opens the options. Turn on `/console scriptErrors 1` to see Lua errors.

Settings live in the `DiveBarDB` saved variable under `_forever_/WTF/Account/<account>/SavedVariables/DiveBar.lua`. Deploying does not touch them.

## Classic Era copy

There is an older copy at `_classic_era_/Interface/AddOns/DiveBar`. It is not deployed from here and lacks recent work (the time-to-level badge, XP per hour, the rounded-corner and swing texture fixes). The code still supports Era (`## Interface: 16001, 11509`; Era uses the combat log where Forever has `PLAYER_SWING`), but test on Forever first.

## Files

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
