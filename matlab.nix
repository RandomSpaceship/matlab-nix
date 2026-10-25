{
  lib,
  buildFHSEnv,
  writeShellScript,
  writeShellApplication,
  symlinkJoin,
  makeDesktopItem,
  unzip,
  # The installation directory, instead of ~/.local/share/matlab/<release>.
  installDir ? null,
}:

# MATLAB is installed imperatively by MathWorks' installer (it needs your
# MathWorks login, downloads the products you pick and activates them for this
# machine), into a user-writable directory outside the store. This package is
# the FHS environment it runs in, and the commands that find that directory.
let
  release = "R2026b";

  defaultRoot =
    if installDir == null then
      "\"\${XDG_DATA_HOME:-$HOME/.local/share}/matlab/${release}\""
    else
      lib.escapeShellArg installDir;

  # MATLAB_ROOT overrides the install location.
  findRoot = ''
    root="''${MATLAB_ROOT:-}"
    if [ -z "$root" ]; then
      root=${defaultRoot}
    fi
  '';

  env = buildFHSEnv {
    name = "matlab-env";
    targetPkgs = import ./fhs-packages.nix;
    profile = ''
      export LANG="''${LANG:-en_US.UTF-8}"
    '';
    # Runs its arguments, or an interactive bash without any.
    runScript = writeShellScript "matlab-env-run" ''
      if [ $# -eq 0 ]; then
        exec bash
      fi
      exec "$@"
    '';
  };

  matlab = writeShellApplication {
    name = "matlab";
    text = findRoot + ''
      if [ ! -x "$root/bin/matlab" ]; then
        echo "matlab: no MATLAB ${release} installation in $root" >&2
        echo "Install it with matlab-install (or set MATLAB_ROOT to an existing installation)." >&2
        exit 1
      fi

      # The desktop entry's icon, from the installation (not redistributed here).
      icon="''${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/256x256/apps/matlab.png"
      if [ ! -e "$icon" ] && [ -e "$root/bin/glnxa64/cef_resources/matlab_icon.png" ]; then
        mkdir -p "$(dirname "$icon")"
        ln -sf "$root/bin/glnxa64/cef_resources/matlab_icon.png" "$icon"
      fi

      exec ${env}/bin/matlab-env "$root/bin/matlab" "$@"
    '';
  };

  # Without a terminal, MATLAB starts without its desktop unless asked to.
  desktopItem = makeDesktopItem {
    name = "matlab";
    desktopName = "MATLAB ${release}";
    exec = "${matlab}/bin/matlab -desktop";
    icon = "matlab";
    startupWMClass = "MATLAB ${release}";
    categories = [
      "Development"
      "Education"
      "Science"
      "Math"
    ];
    mimeTypes = [ "text/x-matlab" ];
    keywords = [
      "matrix"
      "numerical computation"
      "plotting"
    ];
  };

  # Runs the installer from the downloaded .zip (or a directory it was
  # extracted to). Choose the directory it prints as the destination.
  matlab-install = writeShellApplication {
    name = "matlab-install";
    runtimeInputs = [ unzip ];
    text = findRoot + ''
      if [ $# -ne 1 ]; then
        echo "usage: matlab-install matlab_${release}_Linux.zip | <extracted installer directory>" >&2
        exit 1
      fi

      if [ -d "$1" ]; then
        installer=$(realpath "$1")
      else
        installer=$(mktemp -d -t matlab-installer.XXXXXX)
        trap 'rm -rf "$installer"' EXIT
        echo "Extracting $1 ..."
        # -X -K keep the permissions the installer needs.
        unzip -q -X -K "$1" -d "$installer"
      fi

      mkdir -p "$root"
      echo "Choose this folder as the installation destination:"
      echo "  $root"
      ${env}/bin/matlab-env "$installer/install"
    '';
  };

  # An interactive shell in the environment, with MATLAB's bin on PATH, for
  # mex, mlint, the MATLAB Engine for Python and debugging.
  matlab-shell = writeShellApplication {
    name = "matlab-shell";
    text = findRoot + ''
      export MATLAB_ROOT="$root"
      export PATH="$root/bin:$PATH"
      exec ${env}/bin/matlab-env "$@"
    '';
  };
in
symlinkJoin {
  pname = "matlab";
  version = release;
  paths = [
    matlab
    matlab-install
    matlab-shell
    desktopItem
  ];

  passthru = { inherit env release installDir; };

  meta = {
    description = "FHS environment and launchers for an imperatively installed MATLAB";
    homepage = "https://www.mathworks.com/products/matlab.html";
    # The Nix code; MATLAB itself is not part of the package.
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "matlab";
  };
}
