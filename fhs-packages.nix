# Libraries and tools in MATLAB's FHS environment, for `buildFHSEnv`'s
# `targetPkgs`: the dependency list of the release (deps/<release>.nix, made
# by deps/update-deps.py from MathWorks' own lists), and the packages below,
# which every release gets.
{ lib, release }:

pkgs:

let
  file = ./deps + "/${lib.toLower release}.nix";
  supported = map (name: "R" + lib.removePrefix "r" (lib.removeSuffix ".nix" name)) (
    lib.filter (lib.hasPrefix "r20") (lib.attrNames (builtins.readDir ./deps))
  );
in
if !builtins.pathExists file then
  throw ''
    matlab: no dependency list for MATLAB ${release} (deps/ has ${lib.concatStringsSep ", " supported}).
    Make one with `nix run .#update-deps -- ${release}`.''
else
  import file pkgs
  ++ (with pkgs; [
    # Not packages in MathWorks' lists, because a Debian system always has
    # them.
    bashInteractive
    coreutils
    which
    libx11
    libxext
    libxi
    libxrender
    libsm
    libxkbcommon
    libglvnd
    dbus
    freetype

    # mex compiles with the system gcc.
    gcc

    # In the lists of earlier releases, but not in the R2026b list. The
    # R2026b environment was tested with them, so they stay.
    gtk3
    pango
    libdrm
    libxcursor
    libxxf86vm
  ])
