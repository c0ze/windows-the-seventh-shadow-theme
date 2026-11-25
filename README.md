# The Seventh Shadow: a Windows theme

Industrial gothic doom on a frozen lake, for Windows 10 and 11. Ophelia, from The 7th Shadow's video
*The Beast in the Baud*, in seven 4K stills, with the band's colours: void, pewter, the cyan of her veins, gold.
Ported from the Omarchy theme **[c0ze/omarchy-the-seventh-shadow-theme](https://github.com/c0ze/omarchy-the-seventh-shadow-theme)**.

**[the7th-shadow.arda.tr](https://the7th-shadow.arda.tr)** ·
[watch the video](https://youtu.be/nakRhr2EAyE)

## Install

Both files are on the **[latest release](https://github.com/c0ze/windows-the-seventh-shadow-theme/releases/latest)**.

**Just the theme:** double-click `TheSeventhShadow.deskthemepack`. You get dark mode, the vein cyan (`#6FD3F0`) as
the accent, and the seven stills as a slideshow that moves on every ten minutes, as the Omarchy rotation timer
does. Keep the file name as it is: Windows unpacks the pack into a folder named after the file, and the
theme looks for its pictures there.

**Everything:** unzip `TheSeventhShadow-Windows.zip` and run

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

On top of the theme, that

- shows the accent on title bars and window borders: the Windows cousin of the Hyprland vein-to-gold border
  (`-NoTitleBarAccent` leaves it off);
- puts `1-storm` on the lock screen (`-NoLockScreen` to skip, `-LockScreenImage 7-through-ice.jpg` for another);
- adds a **The Seventh Shadow** colour scheme and profile to Windows Terminal, with the portrait faint behind the
  text. It goes in as a fragment, so your `settings.json` is not touched (`-NoTerminal` to skip);
- with `-Fastfetch`, puts the band's crest and panel in `~/.config/fastfetch`. An existing config is kept as
  `config.jsonc.bak`. The icons need a Nerd Font.

No admin rights needed. `uninstall.ps1` takes the extras out again.

Run it from an ordinary terminal or Explorer. Packaged apps (Store apps, and some desktop apps installed as MSIX)
get their own private copy of new folders in AppData. If the script runs from inside one of those and
`%LOCALAPPDATA%\Microsoft\Windows Terminal` doesn't exist yet, the Terminal fragment lands in that private copy
and Windows Terminal never sees it.

## What is not here

Windows has no animated wallpapers of its own, so the intros and loops from the Omarchy theme stay there. The
twelve-second loops would work in a wallpaper engine such as Lively Wallpaper, which can play an `.mp4`.
The Plymouth crest and the Hyprland border animation have no Windows counterpart.

## Building

```powershell
.\build.ps1 -From ..\omarchy-the-seventh-shadow-theme
```

copies the stills fresh from a checkout of the Omarchy theme and writes `dist\TheSeventhShadow.deskthemepack`
and `dist\TheSeventhShadow-Windows.zip`. The palette in `terminal/` comes from that theme's `colors.toml`.
