{
  description = ''
    Overview 2 — a standalone fork of KDE Plasma's Overview KWin effect
    (kwin 6.8.1) that keeps the panel visible and cannot create, delete or
    rename virtual desktops. Ships its own configuration module for the
    Desktop Effects systemsettings page.
  '';

  inputs = {
    # Must match the nixpkgs the system kwin was built from (override with
    # inputs.nixpkgs.follows = "nixpkgs" in the consumer's flake, or pass a
    # custom kwin via .override { kwin = ...; }).
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems =
        f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (
        pkgs: {
          kwin-effect-overview2 = pkgs.kdePackages.callPackage ./nix/package.nix {
            src = self;
          };
          default = self.packages.${pkgs.system}.kwin-effect-overview2;
        }
      );

      devShells = forAllSystems (
        pkgs: {
          default = pkgs.mkShell {
            inputsFrom = [ self.packages.${pkgs.system}.default ];
          };
        }
      );

      # Rebuilds the plugin against the consumer's nixpkgs (i.e. the same
      # KWin that the compositor runs), instead of importing this flake's
      # frozen package. This keeps the private-KWin-library ABI in sync.
      overlays.default = final: _prev: {
        kwin-effect-overview2 = final.kdePackages.callPackage ./nix/package.nix {
          src = self;
        };
      };

      nixosModules.default = import ./nix/module.nix self;
    };
}
