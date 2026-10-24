{
  lib,
  stdenv,
  cmake,
  ninja,
  extra-cmake-modules,
  kwin,
  qtbase,
  qtdeclarative,
  kconfig,
  kcoreaddons,
  kcmutils,
  kglobalaccel,
  ki18n,
  krunner,
  kxmlgui,
  src ? ./..,
}:

# Out-of-tree build of the Overview 2 effect against nixpkgs' KWin.
#
# How the running system kwin finds the plugin on NixOS (no kwin patching or
# systemd unit overrides are needed):
#
#   * nixpkgs ships qtbase with a patch that makes
#     QCoreApplication::libraryPaths() append, for every PATH entry, the
#     sibling directory of the Qt plugin prefix ("lib/qt-6/plugins"), so the
#     kwin process (and systemsettings) search
#     /run/current-system/sw/lib/qt-6/plugins too.
#   * "/lib" is part of environment.pathsToLink's default, so a plugin
#     package added to environment.systemPackages lands exactly there.
#   * KWin's effect loader scans the relative subdirectory
#     "kwin/effects/plugins", the effects KCM additionally scans
#     "kwin/effects/configs".
#
# Therefore the only packaging requirement is that the .so files end up in
# $out/lib/qt-6/plugins/kwin/effects/{plugins,configs}/ and that the package
# is present in the system profile.
#
# The plugin links against KWin's private libraries, so a matching KWin/Qt
# revision is required: flake users should point inputs.nixpkgs.follows at
# the same nixpkgs their system was built from, or pass a matching kwin via
# `.override { kwin = ...; }`.
#
# NOTE: the plugin targets the kwin 6.8.x effect API; kwin must be >= 6.8.1.
assert lib.versionAtLeast kwin.version "6.8.1";

stdenv.mkDerivation {
  pname = "kwin-effect-overview2";
  version = "1.0.0";

  inherit src;

  nativeBuildInputs = [
    cmake
    ninja
    extra-cmake-modules
  ];

  buildInputs = [
    kwin
    qtbase
    qtdeclarative

    # Frameworks the effect and its config module link against. Mostly
    # propagated by kwin already, listed explicitly for robustness.
    kconfig
    kcoreaddons
    kcmutils
    kglobalaccel
    ki18n
    krunner
    kxmlgui
  ];

  # Both plugins (effect + config KCM) are installed by
  # kcoreaddons_add_plugin() into ${KDE_INSTALL_PLUGINDIR}/kwin/effects/...
  # Pin it to Qt's plugin prefix so that the layout matches the
  # PATH-derived search path of the patched qtbase ("lib/qt-6/plugins")
  # instead of whatever ECM auto-detects in the build sandbox.
  cmakeFlags = [
    "-DKDE_INSTALL_PLUGINDIR=${placeholder "out"}/${qtbase.qtPluginPrefix}"
  ];

  # No executables are shipped; wrapping would be a no-op.
  dontWrapQtApps = true;

  meta = with lib; {
    description = "KWin Overview effect fork with a visible panel and no virtual-desktop delete/rename";
    longDescription = ''
      Standalone fork of KDE Plasma's Overview KWin effect (kwin 6.8.1):
      the panel stays visible and the effect avoids it on every edge,
      virtual desktops cannot be created, deleted, or renamed from the
      overview, and the effect ships its own configuration module
      ("Overview 2" in Desktop Effects).
    '';
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
    teams = [ teams.qt-kde ];
  };
}
