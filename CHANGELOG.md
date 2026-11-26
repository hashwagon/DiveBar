# Changelog

## 1.6.0

- Fixed: hiding the game's default bars failed with "Can't read the Edit Mode layout" while a custom Edit Mode layout was active. With several custom layouts, the change could land on a layout you weren't using. Dive Bar now finds the layout that's actually active, and leaves the built-in presets alone.
- Options: each bar's Blizzard box is now "Hide default". Checked hides the game's own bar. Unchecked shows it again with your Edit Mode setting. Your saved choices are unchanged.
- Options: after you change a Hide default box, closing the window offers a reload, since the game's bars only follow Edit Mode after one.
- Options: the window is taller, so more settings show at once.
- Options: the note listing bars that can't be hidden is gone.
- XP badge: a new Fixed badge size option, with Badge width and Badge height sliders, keeps the badge one size so Time text size only changes the text.
- Vertical padding now moves in half steps.
- Neighbouring bars share their padding, so the gap between two bars is the larger of their two paddings rather than both added together. Bars with padding sit closer together.
- Borders, padding and bar heights line up with whole screen pixels, so matching gaps stay even and edges stay sharp.

## 1.5.1

- Preview: the Play demo checkbox is now a Play button that turns to Pause while the demo runs. It keeps one width, so the row beside it never shifts.
- Closing the options window pauses the demo.
- Preview: the heading row sits a little higher, clear of the gold line under it.

## 1.5.0

- Options window: rebuilt to sit alongside the game's own panels, narrower and shorter, with the Looking For Group window's art: its dark header behind the Preview, its textured background and gilded inner frame around the settings, and its slim scroll bar.
- Preview: follows the demo the way the bars do. Rows fold away when they're idle and come back as they play, and the anchored row holds still while the others come and go. The Preview area keeps one size, so the settings below don't move.
- Preview: a real cast plays in the preview too, in step with the bar.
- Demo: shorter, with one of each. A Frostbolt, a warrior fight with Slam woven in while the swing timer keeps running, a breath timer running out, and a Hearthstone home.
- Horizontal padding: a new slider in Look adds room between the bars and the side border. The frame grows to keep the bars at your width.
- Padding sliders on each bar are now called Vertical padding.
- Sliders: the gold fill now follows the value, so a full slider reaches the end of the groove.
- XP badge: the time chip is a little roomier.
- New profiles start with the Forever theme, a width of 459, a thinner border, smaller badge text, and a pixel of padding around the experience bar.

## 1.4.0

- Until the first lock, the bars play a demo that alternates a mage casting Frostbolt with a warrior swinging a two-hander and weaving in Slam, while experience fills every 20 seconds. Rows fold away between casts and fights as they do in real use. Real casts and swings show instead.
- Options: Play demo, on the Preview heading, runs the same demo on the bars and in the preview.
- Borders: the frame and the XP badge wear WoW Forever's window rim, with its chamfered corners. Forever keeps the bronze, Classic turns it silver like the classic cast bar and tooltip borders, and Flat draws a near-black band edged by a crisp one-pixel gray line. All three are the same thickness. On Classic Era, Forever and Classic keep the tooltip line, Forever's tinted bronze.
- Border: the slider now runs from a 1-pixel hairline to the weight of Forever's own window rims. Saved settings keep their thickness, which now sits higher on the slider. New profiles start thinner.
- Forever theme: the spell name no longer sits on a blue plate, so the bar's texture shows behind it.
- Rounded corners only applies to the tooltip line and is dimmed when the border has its own corners.

## 1.3.1

- Rounded corners: the background follows the curve of the border and stops under its silver line, so see-through backgrounds no longer show square corners or darker edges.
- XP badge: new profiles start with larger time text and no extra padding.

## 1.3.0

- First release on CurseForge.
- New Dive Bar art for the minimap button and the options window portrait.
- Options: tooltips explain each setting, replacing the notes under the controls, so the window is shorter. Tick boxes can be clicked on their labels.
- Options: "Blizzard bar" is now "Show Blizzard bar", and Background margin sits beside Width.
- Options: profile Reset and Delete sit next to the profile list, and Copy sits beside its list. The new profile box shows a hint until you type.
- Options: the version shown in the Profiles section matches the installed version.
- Options: the preview area is dark edge to edge with no divider under it, and the mouse wheel scrolls in smaller steps.
- Clearer messages when the Blizzard bars can't be hidden.

## 1.2.0

- XP badge: the badge scales with its Size setting, text and padding are sized separately, and each time format has a fixed width so the badge doesn't jump around.
- XP badge: short badges keep the frame's border line, the clear band inside rounded corners is filled, and an XP-blue edge marker glows toward completed XP.
- Bars run flush to the side border.
- Options: preview tick boxes for each bar during the session. Bars that are turned off never preview.
- Options: save your current settings as the defaults.

## 1.1.0

- First version tracked in this repository.
