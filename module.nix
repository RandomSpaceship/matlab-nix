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

  config = lib.mkIf cfg.enable (
    lib.setAttrByPath packagesOption [
      (if cfg.installDir == null then cfg.package else cfg.package.override { inherit (cfg) installDir; })
    ]
  );
}
