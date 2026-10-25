{
  description = "MATLAB on NixOS (an FHS environment for an imperative install)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          f (
            import nixpkgs {
              inherit system;
              overlays = [ self.overlays.default ];
            }
          )
        );
    in
    {
      overlays.default = final: prev: {
        matlab = final.callPackage ./matlab.nix { };
      };

      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);

      packages = forAllSystems (pkgs: {
        inherit (pkgs) matlab;
        default = pkgs.matlab;
      });

      apps = forAllSystems (
        pkgs:
        let
          inherit (self.packages.${pkgs.stdenv.hostPlatform.system}) matlab;
        in
        {
          default = {
            type = "app";
            program = "${matlab}/bin/matlab";
          };
          #   nix run .#install -- matlab_R2026b_Linux.zip
          install = {
            type = "app";
            program = "${matlab}/bin/matlab-install";
          };
          shell = {
            type = "app";
            program = "${matlab}/bin/matlab-shell";
          };
          # Makes deps/<release>.nix again from MathWorks' lists (see
          # deps/README.md). Run it from the root of the repository.
          update-deps = {
            type = "app";
            program = pkgs.lib.getExe (
              pkgs.writeShellApplication {
                name = "update-deps";
                runtimeInputs = [
                  pkgs.python3
                  pkgs.nixfmt
                ];
                text = ''exec python3 -I ${./deps/update-deps.py} "$@"'';
              }
            );
          };
        }
      );

      # MATLAB itself can't be installed in the sandbox (it needs a MathWorks
      # login), so these only cover the environment and the launchers.
      checks = forAllSystems (
        pkgs:
        let
          inherit (pkgs.stdenv.hostPlatform) system;
          inherit (self.packages.${system}) matlab;
          inherit (nixpkgs) lib;

          # Not the default release, so that the check sees the override.
          settings = {
            programs.matlab = {
              enable = true;
              release = "R2025b";
              installDir = "/opt/matlab-test";
            };
          };

          # A minimal system with the module enabled, evaluated (not built).
          nixos =
            (lib.nixosSystem {
              modules = [
                self.nixosModules.default
                settings
                {
                  nixpkgs.hostPlatform = system;
                  boot.loader.grub.enable = false;
                  fileSystems."/" = {
                    device = "none";
                    fsType = "tmpfs";
                  };
                  system.stateVersion = "26.05";
                }
              ];
            }).config;

          # The Home Manager module, with a stand-in for the one option it sets
          # (so that this flake doesn't need Home Manager as an input).
          home =
            (lib.evalModules {
              specialArgs = { inherit pkgs; };
              modules = [
                self.homeModules.default
                settings
                {
                  options.home.packages = lib.mkOption {
                    type = lib.types.listOf lib.types.package;
                    default = [ ];
                  };
                }
              ];
            }).config;

          installedMatlab =
            packages: lib.findFirst (p: p.pname or null == "matlab") (throw "matlab not installed") packages;
        in
        {
          inherit matlab;

          module =
            let
              fromNixos = installedMatlab nixos.environment.systemPackages;
              fromHome = installedMatlab home.home.packages;
            in
            assert fromNixos.installDir == "/opt/matlab-test" && fromNixos.release == "R2025b";
            assert fromHome.installDir == "/opt/matlab-test" && fromHome.release == "R2025b";
            pkgs.runCommand "check-module" { } ''
              grep -qx 'Name=MATLAB R2025b' ${fromNixos}/share/applications/matlab.desktop
              grep -qx 'StartupWMClass=MATLAB R2025b' ${fromNixos}/share/applications/matlab.desktop
              grep -q "/opt/matlab-test" ${fromNixos}/bin/matlab
              grep -q "no MATLAB R2025b installation" ${fromNixos}/bin/matlab
              touch $out
            '';

          # The package list of every release in deps/ evaluates (each
          # attribute is in nixpkgs). Only the default release is built.
          deps =
            let
              releases = map (name: "R" + lib.removePrefix "r" (lib.removeSuffix ".nix" name)) (
                lib.filter (lib.hasPrefix "r20") (lib.attrNames (builtins.readDir ./deps))
              );
              envs = map (release: (matlab.override { inherit release; }).env.drvPath) releases;
            in
            builtins.deepSeq envs (pkgs.writeText "check-deps" (lib.concatLines releases));

          format = pkgs.runCommand "check-format" { nativeBuildInputs = [ pkgs.nixfmt ]; } ''
            nixfmt --check ${./.}/*.nix ${./.}/deps/*.nix
            touch $out
          '';
        }
      );

      # programs.matlab.enable installs the launchers (`matlab`,
      # `matlab-install`, `matlab-shell` and a desktop entry), for every user
      # (NixOS) or for one (Home Manager). MATLAB itself is still installed
      # with `matlab-install`.
      nixosModules.default = import ./module.nix {
        inherit self;
        packagesOption = [
          "environment"
          "systemPackages"
        ];
      };
      homeModules.default = import ./module.nix {
        inherit self;
        packagesOption = [
          "home"
          "packages"
        ];
      };
    };
}
