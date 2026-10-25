# MATLAB for NixOS

Nix flake that runs [MATLAB](https://www.mathworks.com/products/matlab.html) R2026b on
NixOS (`x86_64-linux`).

MATLAB can't be packaged in the usual way: its installer needs your MathWorks login,
downloads the products your licence covers, and activates them for this machine. So
MATLAB is installed imperatively, into a user-writable directory outside the store,
and this flake provides the [`buildFHSEnv`](https://nixos.org/manual/nixpkgs/unstable/#sec-fhs-environments)
environment it (and its installer) runs in, plus launchers that find the installation.
Nothing from MathWorks is included or redistributed here.

The environment's packages follow MathWorks' own dependency list for R2026b
([container-images](https://github.com/mathworks-ref-arch/container-images),
`matlab-deps/r2026b/ubuntu24.04`), mapped to nixpkgs in [fhs-packages.nix](fhs-packages.nix).

## Installing MATLAB

Download the Linux installer (`matlab_R2026b_Linux.zip`) from your
[MathWorks account](https://www.mathworks.com/downloads/), then run it in the environment:

```sh
nix run github:RandomSpaceship/matlab-nix#install -- matlab_R2026b_Linux.zip
```

It extracts the zip to a temporary directory (an already extracted directory works
too) and starts the installer. Sign in, pick your products, and when asked for the
destination folder, choose the one it printed:

```
~/.local/share/matlab/R2026b
```

The installer suggests `/usr/local/MATLAB/R2026b`, which isn't writable on NixOS.
Leave "create symbolic links" unticked; the flake's `matlab` command does that job.

`MATLAB_ROOT` (or the modules' `installDir`) changes the folder.

## Running MATLAB

```sh
nix run github:RandomSpaceship/matlab-nix               # the desktop
nix run github:RandomSpaceship/matlab-nix -- -batch "disp(version)"
nix run github:RandomSpaceship/matlab-nix#shell         # bash in the environment
```

The first start asks you to sign in again (online licensing). All of MATLAB's own
command-line options pass through.

`matlab-shell` (the `shell` app) is a bash in the same environment with
`MATLAB_ROOT` set and MATLAB's `bin` on `PATH`, for `mex`, `mlint`, the MATLAB Engine
for Python, or debugging. With arguments it runs them instead, e.g.
`matlab-shell mex hello.c`.

## NixOS and Home Manager modules

`nixosModules.default` (for every user) and `homeModules.default` (for one) both add
`programs.matlab`, which installs `matlab`, `matlab-install`, `matlab-shell` and a
"MATLAB R2026b" desktop entry. Importing a module does nothing until
`programs.matlab.enable` is set.

- `programs.matlab.installDir`: absolute path of the installation, instead of
  `~/.local/share/matlab/R2026b` of whoever runs it. `MATLAB_ROOT` still takes precedence.
- `programs.matlab.package`: replaces the package.

```nix
{
  inputs.matlab.url = "github:RandomSpaceship/matlab-nix";

  outputs = { nixpkgs, matlab, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        matlab.nixosModules.default
        { programs.matlab.enable = true; }
      ];
    };
  };
}
```

With Home Manager, import `matlab.homeModules.default` in your home configuration and
set the same option there.

The package is also available on its own, as `packages.x86_64-linux.matlab` or as
`matlab` from `overlays.default`, e.g. for a project's dev shell. It's only the Nix
code and the environment, so it doesn't need `allowUnfree`.

## Known issues

- **Crash on exit with glibc's allocator.** With glibc 2.43 and later (NixOS has 2.44),
  closing the MATLAB desktop aborts with `free(): chunks in smallbin corrupted` and
  hangs, leaving a `~/matlab_crash_dump.*`. The same happens on
  [Ubuntu 26.04](https://www.mathworks.com/matlabcentral/discussions/general/887876-matlab-crash-on-ubuntu-26-04-free-chunks-in-smallbin-corrupted)
  and [Fedora 44](https://www.mathworks.com/matlabcentral/answers/2183725-matlab-hangs-throws-c-errors-when-exitting-fedora-44),
  which MathWorks doesn't support yet. `matlab` and `matlab-shell` therefore preload
  tcmalloc (from gperftools) as MATLAB's allocator, which exits cleanly. Remove it once
  MathWorks fixes the crash; it hides heap corruption in MATLAB rather than fixing it.
  MATLAB's own `ld_shim` workaround for newer distros (selected from `/etc/os-release`,
  so never on NixOS) was tried with NixOS's loader and didn't stop the crash.
- **No desktop without a terminal.** MATLAB only opens its desktop by itself when it's
  started from a terminal; otherwise it runs at the command line and exits at once.
  The desktop entry passes `-desktop`; do the same when launching it from a script or
  keybinding.
- **The first start after installing asks you to sign in**, even after signing in to
  the installer. That's online licensing; the login is kept in `~/.matlab`.
- **`MathWorksServiceHost` stays running** after MATLAB exits (it's MathWorks' licensing
  and update daemon, installed to `~/.MathWorks/ServiceHost`). When it's started by a
  piped command, e.g. `matlab -batch … | tail`, it keeps the pipe open and the
  command seems to hang after MATLAB is done. Use `-logfile` or redirect to a file.
- The main menu once showed "Error while processing HTTP request. Retry limit reached:
  Connection refused", with two MATLAB desktops running; it was gone after restarting
  MATLAB.

MATLAB runs on Wayland through XWayland; it was tested on niri (with
xwayland-satellite).

## Updating to a new release

MATLAB releases install side by side, each in its own folder. For a new release, bump
`release` in [matlab.nix](matlab.nix), compare [fhs-packages.nix](fhs-packages.nix)
against the new `matlab-deps/<release>` list, and run the new installer.

CI ([check.yml](.github/workflows/check.yml)) builds the package and runs
`nix flake check`: the build, both modules' configuration, and formatting
(`nix fmt`). MATLAB itself can't be
installed there, so running it is only tested by hand.

## Prior work

- [doronbehar/nix-matlab](https://gitlab.com/doronbehar/nix-matlab) (archived): the
  most complete earlier flake, and the base of the
  [NixOS wiki page](https://wiki.nixos.org/wiki/Matlab). It uses the same
  approach, with a hand-maintained package list and the install folder set in
  `~/.config/matlab/nix.sh`.
- [jorsn/matlab-nix-imperative](https://github.com/jorsn/matlab-nix-imperative): a
  `nix-shell` based FHS environment for an imperative install, configured with
  `MATLAB_DIR`.
- [MATLAB on NixOS](http://tilde.club/~if/blog/matlab.html): an FHS shell for the
  installer, and the GUI segfault workarounds of that time.

## License

The Nix code in this repository is under the [MIT license](LICENSE.md). MATLAB is
proprietary software by The MathWorks, Inc. under its own license terms; it is
installed by you from MathWorks, not included or redistributed here.
