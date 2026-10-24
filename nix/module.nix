self:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.kwin-effect-overview2;
in
{
  options.programs.kwin-effect-overview2 = {
    enable = lib.mkEnableOption ''
      the Overview 2 KWin effect.

      The effect is disabled in Desktop Effects by default; after switching
      to it, disable the stock Overview effect and assign a shortcut to
      "Overview 2" (e.g. Super+W) in the Desktop Effects configuration,
      because the fork ships no default keybindings.
    '';

    package = lib.mkOption {
      type = lib.types.package;
      # Rebuild against this configuration's nixpkgs so that the plugin is
      # linked against the same KWin that the compositor runs. Override with
      # e.g. `.override { kwin = ...; }` if you use a custom KWin.
      default = pkgs.kdePackages.callPackage (import ./package.nix) { src = self; };
      defaultText = lib.literalExpression ''
        pkgs.kdePackages.callPackage ./package.nix { src = kwin-effect-overview2 source; }
      '';
      description = "The kwin-effect-overview2 package to install.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
  };
}
