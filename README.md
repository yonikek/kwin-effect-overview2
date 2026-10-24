# kwin-effect-overview2

A fork of KDE Plasma's **Overview** desktop effect (KWin `overview` plugin, version `6.8.1`)
with two behavioral changes:

1. **Virtual desktops can no longer be created, deleted or renamed** — by default;
   toggleable.
   - Everything the stock effect offers here (the "Delete Virtual Desktop" hover
     button, the "Add Virtual Desktop" buttons and their drop areas, the
     click-to-rename editor, and the `Delete` / `F2` / `-` / `+` hotkeys) is still
     present in this fork, but gated behind the *workspace management* toggle
     (`src/DesktopBar.qml`, `src/Main.qml`): with the toggle off (the default) the
     desktop names are shown as read-only labels and there are no add/delete
     affordances.
   - Arranging desktops in System Settings / KCM is still possible ("Configure Virtual
     Desktops…" remains).

2. **The panel (Plasma dock) stays visible while the effect is active** — by default;
   toggleable ("Show the panel while the overview is active").
   - With the toggle on (the default): in the stock effect the dock is drawn only
     during the exit transition and fades away as soon as the effect reaches full
     opacity (`opacity: 1 - (gridVal + overviewVal)` in `src/Main.qml`); in this fork
     the dock thumbnail is kept at full opacity, so the panel remains visible (as a
     static, non-interactive image) behind/below the overview UI.
   - With the toggle off, the stock behavior is restored: the panel fades away and
     the overview contents use the whole screen.
   - The overview contents (desktop grid / window heap) are laid out ("free-rect
     centered") inside the screen area remaining free of panel (dock) windows:
     panel insets on each axis are summed into the maximum content size, and the
     content is centered inside the panel-free area (net offset `(left - right)/2`
     on the x axis, `(top - bottom)/2` on the y axis), so the effect does not
     cover panels on any edge, and a panel on any edge is treated identically.
   - Panel windows are recognized by their bar shape (long along a screen edge,
     thin across it), so that e.g. a full-width bottom panel is not mistaken
     for left/right insets.

3. **A configuration UI is available from the Desktop Effects systemsettings module.**
   - Like the stock Overview effect, the fork declares `"X-KDE-ConfigModule"` in
     its `src/metadata.json` and builds a KCModule target
     (`kwin4_effect_overview2_config`, from `src/kcm/`) installed into
     `lib/qt6/plugins/kwin/effects/configs`. It exposes the three stock
     options (ignore minimized windows, windows organized in the grid view,
     search results include filtered windows), the fork's two toggles —
     "Show the panel while the overview is active" (default on) and "Allow
     managing virtual desktops (create, delete, rename)" (default off) —
     plus a shortcuts editor for the fork's
     global actions ("Overview 2", "Grid View 2" and the two cycle actions).
     Unlike stock, no default keybindings are set.

Everything else (search, KRunner integration, gestures, animations, grid view, …) is unchanged.

## Why a separate plugin?

The code links against the installed `KWin::kwin` CMake package instead of building inside
the kwin source tree, and installs as its own dynamic effect plugin
(`kwin4_effect_overview2`) with its own QML module URI (`org.kde.kwin.overview2`) and global
shortcut action names. Because of that it can safely coexist with the stock effect, although
**you should disable the stock Overview and assign your shortcuts to the fork** — otherwise
a 4-finger touchpad swipe would drive both effects at once (the gesture wiring is identical
to upstream).

Dependencies must match your installed KWin version (the effect API is not
binary-compatible; rebuild whenever KWin updates).

## Requirements (Arch Linux)

- `kwin` (KWin 6.8.1 headers + `libkwin.so` — the standard package ships them)
- `cmake`, `ninja`/`make`, `gcc`
- `extra-cmake-modules` (ECM ≥ 6.30)
- Qt 6 (`Quick`), KF6: `CoreAddons`, `Config`, `GlobalAccel`, `I18n`, `Runner`

```sh
sudo pacman -S --needed base-devel cmake ninja extra-cmake-modules kwin qt6-base qt6-declarative \
    kcoreaddons kconfig kglobalaccel ki18n krunner
```

## Build

```sh
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=$HOME/.local \
    -DKDE_INSTALL_PLUGINDIR=share/qt6/plugins
cmake --build build
cmake --install build
```

This installs to `~/.local/share/qt6/plugins/kwin/effects/plugins/kwin4_effect_overview2.so`.

> Note: on Arch, `~/.local/lib` is sometimes root-owned; the `KDE_INSTALL_PLUGINDIR`
> setting above sidesteps that by installing under `~/.local/share` instead.

KWin's effect loader discovers plugins in every directory of
`QCoreApplication::libraryPaths()` plus `kwin/effects/plugins`, so a plugin dropped into
`/usr/lib/qt6/plugins/kwin/effects/plugins` works with no extra configuration:

```sh
sudo cmake --install build \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DKDE_INSTALL_PLUGINDIR=lib/qt6/plugins
```

## Installing per-user (needs `QT_PLUGIN_PATH`)

KWin's session process must be able to find `~/.local/...`. Add a user environment
override and log out/in (or restart the session):

```
# ~/.config/environment.d/qt-plugin-path.conf
QT_PLUGIN_PATH=%h/.local/share/qt6/plugins
```

Discovery can be verified independently of KWin: any small Qt program that calls
`KPluginMetaData::findPlugins("kwin/effects/plugins")` with `QT_PLUGIN_PATH` set to the
per-user plugin dir must list `kwin4_effect_overview2` and report a matching
`org.kde.kwin.EffectPluginFactory<version>` IID (this was done during development).

## NixOS installation

The repository ships a Nix flake (`flake.nix`, packaging under `nix/package.nix`
and a NixOS module under `nix/module.nix`). The plugin is linked against the
KWin of the nixpkgs set it is evaluated with, so the nixpkgs input **must match
the nixpkgs your system was built from** — ABI of KWin's private libraries is
not stable. In the consumer flake, add `inputs.nixpkgs.follows = "nixpkgs";`
to the `kwin-effect-overview2` input to guarantee that.

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; # match your system
    kwin-effect-overview2 = {
      url = "github:USER/kwin-effect-overview2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

### Declarative (NixOS module)

```nix
# in configuration.nix
{
  imports = [ inputs.kwin-effect-overview2.nixosModules.default ];
  programs.kwin-effect-overview2.enable = true;
}
```

### Plain package

```nix
environment.systemPackages = [
  inputs.kwin-effect-overview2.packages.${pkgs.system}.default
];
```

### Overlay (reuses your own nixpkgs)

The overlay rebuilds the plugin against *your* nixpkgs (the KWin that the
compositor actually runs), which keeps the ABI in sync:

```nix
nixpkgs.overlays = [ inputs.kwin-effect-overview2.overlays.default ];
environment.systemPackages = [ pkgs.kwin-effect-overview2 ];
```

No `QT_PLUGIN_PATH` or systemd-unit overrides are needed on NixOS: nixpkgs'
qtbase adds `PATH`-derived plugin directories (`bin/../lib/qt-6/plugins`) to
`QCoreApplication::libraryPaths()`, `/lib` is linked into the system profile by
default, and KWin scans the `kwin/effects/plugins` subdirectory of those paths
(the effect's config module is picked up from `kwin/effects/configs`, also in
the profile, by systemsettings).

As everywhere else, the effect is disabled by default: enable *Overview 2* in
Desktop Effects, disable the stock *Overview*, and assign a shortcut manually.



1. Restart KWin (`killall -3 kwin_wayland`… relogin) or simply run
   `qdbus org.kde.KWin /Effects org.kde.KWin.Effects.loadEffect kwin4_effect_overview2`
   to load it into the running session.
2. Open **System Settings → Desktop Effects**, search for *"Overview 2"*:
   - uncheck the stock **Overview** effect,
   - enable **Overview 2 (fork of Overview)** and click *Reconfigure* / *Apply*.
3. Assign shortcuts in **System Settings → Shortcuts → KWin**:
   - *Toggle Overview 2* (suggest `Meta+W`, matching the stock default),
   - *Toggle Grid View 2* (suggest `Meta+G`).
   The fork deliberately ships with **no default shortcuts** so it cannot steal `Meta+W`
   from the stock effect before the stock effect is disabled.

## Notes / limitations

- The fork's own effect-configuration records (screen edges, borders, filtering) still use
  the `kwinrc` group `[Effect-overview]`, exactly like the stock effect, so both share
  those settings.
- The stock effect's config KCM (`kwin_overview_config`) is not included; there is nothing
  else to configure in a dialog — screen-edge activation can still be set in
  `kwinrc`, e.g. via `kcm_kwin_effects`-stored borders (`BorderActivate`, etc.).

## License

GPL-2.0-or-later (same as upstream; SPDX notices preserved in the files).
