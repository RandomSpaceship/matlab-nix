# The NixOS and Home Manager modules, which differ only in the option the
# package is added to.
{ self, packagesOption }:

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.matlab;
in
{
  options.programs.matlab = {
    enable = lib.mkEnableOption "the MATLAB launchers and FHS environment";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.matlab;
      defaultText = lib.literalExpression "matlab.packages.\${pkgs.stdenv.hostPlatform.system}.matlab";
      description = "The MATLAB package (the launchers; MATLAB itself is installed with `matlab-install`).";
    };

    release = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "R2025b";
      description = ''
        The MATLAB release, for the default installation directory, the
        messages and the desktop entry. The default (null) is the release of
        the package. Only the default release of the package is tested.
      '';
    };

    installDir = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/opt/MATLAB/R2026b";
      description = ''
        Absolute path of the MATLAB installation. The default (null) is
        `~/.local/share/matlab/<release>` of the user running it. `MATLAB_ROOT`
        in the environment still takes precedence.
      '';
    };
  };

  config =
    let
      # Only the options that are set, so that a package without these
      # arguments still works with the defaults.
      overrides = lib.filterAttrs (_: value: value != null) { inherit (cfg) release installDir; };
    in
    lib.mkIf cfg.enable (
      lib.setAttrByPath packagesOption [
        (if overrides == { } then cfg.package else cfg.package.override overrides)
      ]
    );
}
