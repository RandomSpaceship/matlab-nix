# MATLAB for NixOS

This Nix flake runs [MATLAB](https://www.mathworks.com/products/matlab.html) R2026b on
NixOS (`x86_64-linux`).

You cannot package MATLAB in the usual way. Its installer needs your MathWorks login.
It downloads the products that your licence covers, and it activates them for this
machine. Thus you install MATLAB yourself, into a user-writable directory outside the
Nix store. This flake gives the [`buildFHSEnv`](https://nixos.org/manual/nixpkgs/unstable/#sec-fhs-environments)
environment that MATLAB and its installer run in. It also gives launchers that find the
installation. This repository does not include or redistribute files from MathWorks.

The packages in the environment follow the MathWorks dependency list for R2026b
([container-images](https://github.com/mathworks-ref-arch/container-images),
`matlab-deps/r2026b/ubuntu24.04`). [fhs-packages.nix](fhs-packages.nix) maps that list
to nixpkgs.

## Install MATLAB

1. Download the Linux installer (`matlab_R2026b_Linux.zip`) from your
   [MathWorks account](https://www.mathworks.com/downloads/).
2. Run the installer in the environment:

   ```sh
   nix run github:RandomSpaceship/matlab-nix#install -- matlab_R2026b_Linux.zip
   ```

   The command extracts the zip file to a temporary directory and starts the
   installer. You can also give it a directory that you extracted before.
3. Sign in, and select your products.
4. When the installer asks for the destination, select the directory that the command
   showed:

   ```
   ~/.local/share/matlab/R2026b
   ```

   Do not use the directory that the installer suggests (`/usr/local/MATLAB/R2026b`).
   You cannot write to it on NixOS.
5. Do not select "create symbolic links". The `matlab` command of this flake does that
   job.

To use a different installation directory, set `MATLAB_ROOT`, or set `installDir` in
the modules.

## Run MATLAB

```sh
nix run github:RandomSpaceship/matlab-nix               # the desktop
nix run github:RandomSpaceship/matlab-nix -- -batch "disp(version)"
nix run github:RandomSpaceship/matlab-nix#shell         # bash in the environment
```

At the first start, MATLAB asks you to sign in again (online licensing). The launcher
passes all MATLAB command-line options through.

`matlab-shell` (the `shell` app) is a bash shell in the same environment. It sets
`MATLAB_ROOT` and puts the MATLAB `bin` directory on `PATH`. Use it for `mex`, `mlint`,
the MATLAB Engine for Python, or debugging. With arguments, it runs them instead of a
shell, for example `matlab-shell mex hello.c`.

## NixOS and Home Manager modules

`nixosModules.default` installs MATLAB for all users. `homeModules.default` installs it
for one user. The two modules add `programs.matlab`. This option installs `matlab`,
`matlab-install`, `matlab-shell`, and a "MATLAB R2026b" desktop entry. A module does
nothing until you set `programs.matlab.enable`.

- `programs.matlab.installDir`: the absolute path of the installation directory. The
  default is `~/.local/share/matlab/R2026b` of the user that runs MATLAB. `MATLAB_ROOT`
  overrides this option.
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

For Home Manager, import `matlab.homeModules.default` in your home configuration. Then
set the same option there.

You can also use the package without a module, as `packages.x86_64-linux.matlab` or as
`matlab` from `overlays.default`. For example, you can add it to the dev shell of a
project. The package holds only the Nix code and the environment. Thus it does not need
`allowUnfree`.

## Known issues

- **Crash on exit with the glibc allocator.** NixOS has glibc 2.44. With glibc 2.43 and
  later, the MATLAB desktop aborts on exit with `free(): chunks in smallbin corrupted`.
  Then it hangs, and it leaves a `~/matlab_crash_dump.*` file. The same crash occurs on
  [Ubuntu 26.04](https://www.mathworks.com/matlabcentral/discussions/general/887876-matlab-crash-on-ubuntu-26-04-free-chunks-in-smallbin-corrupted)
  and [Fedora 44](https://www.mathworks.com/matlabcentral/answers/2183725-matlab-hangs-throws-c-errors-when-exitting-fedora-44).
  MathWorks does not support these distributions at this time.

  Thus `matlab` and `matlab-shell` preload tcmalloc (from gperftools) as the MATLAB
  allocator. With tcmalloc, MATLAB exits cleanly. This preload hides heap corruption in
  MATLAB, but it does not fix it. Remove the preload when MathWorks fixes the crash.

  MATLAB has its own `ld_shim` workaround for newer distributions. MATLAB selects a shim
  from `/etc/os-release`, so it never selects one on NixOS. A test of the shim with the
  NixOS loader did not stop the crash.
- **No desktop without a terminal.** MATLAB opens its desktop automatically only when
  you start it from a terminal. Without a terminal, it runs at the command line and
  exits immediately. The desktop entry adds `-desktop`. Add `-desktop` when you start
  MATLAB from a script or a keybinding.
- **The first start after the installation asks you to sign in.** This occurs also
  after you signed in to the installer, because MATLAB uses online licensing. MATLAB
  keeps the login in `~/.matlab`.
- **`MathWorksServiceHost` continues to run after MATLAB exits.** It is the MathWorks
  licensing and update daemon, in `~/.MathWorks/ServiceHost`. A piped command can start
  it, for example `matlab -batch … | tail`. Then the daemon keeps the pipe open, and the
  command seems to hang after MATLAB stops. Use `-logfile`, or send the output to a file.
- **`MathWorksServiceHost` changes the desktop configuration.** When the daemon
  installs or updates itself, it adds an autostart entry to `~/.config/autostart`. It
  also adds handlers for `mw-matlab:` and two other URL schemes to
  `~/.local/share/applications/mimeapps.list`. If Home Manager manages default
  applications (`xdg.mimeApps.enable`), that file is a symlink. The daemon replaces it
  with a regular file, and the next Home Manager activation fails.

  Thus the environment puts a temporary overlay on these two directories. MATLAB can
  read the files in them, but its changes do not get to your home directory. As a
  result, `mw-matlab:` links (for example from MATLAB Online) do not open MATLAB.

  If you ran MATLAB without this overlay, remove the files that the daemon wrote:

  ```sh
  rm ~/.local/share/applications/mw-{matlab,simulink,matlabconnector}.desktop \
    ~/.config/autostart/mathworks-service-host.desktop
  ```

  Then remove the `x-scheme-handler/mw-*` lines from `mimeapps.list`. If Home Manager
  manages the file, delete it and run the switch again. Also delete
  `mimeapps.list.bak` if Home Manager cannot make a backup.
- The main menu showed "Error while processing HTTP request. Retry limit reached:
  Connection refused" one time, with two MATLAB desktops open. After a restart of
  MATLAB, the error did not occur again.

MATLAB runs on Wayland through XWayland. The tests used niri with xwayland-satellite.

## Update to a new release

Each MATLAB release installs in its own directory, next to the other releases. For a
new release, do these steps:

1. Change `release` in [matlab.nix](matlab.nix).
2. Compare [fhs-packages.nix](fhs-packages.nix) with the new `matlab-deps/<release>`
   list.
3. Run the new installer.

CI ([check.yml](.github/workflows/check.yml)) builds the package and runs
`nix flake check`. The checks cover the build, the configuration of the two modules,
and the formatting (`nix fmt`). CI cannot install MATLAB. Thus only a manual test
shows that MATLAB runs.

## Development

Developed using Claude Code and Opus 5.5.

## Prior work

- [doronbehar/nix-matlab](https://gitlab.com/doronbehar/nix-matlab) (archived): the
  most complete earlier flake, and the base of the
  [NixOS wiki page](https://wiki.nixos.org/wiki/Matlab). It uses the same approach.
  It has a package list that its author maintained by hand, and it reads the
  installation directory from `~/.config/matlab/nix.sh`.
- [jorsn/matlab-nix-imperative](https://github.com/jorsn/matlab-nix-imperative): an FHS
  environment for `nix-shell`, for a MATLAB that you install yourself. `MATLAB_DIR`
  sets the installation directory.
- [MATLAB on NixOS](http://tilde.club/~if/blog/matlab.html): an FHS shell for the
  installer, and workarounds for the GUI segmentation faults of that time.

## Licence

The Nix code in this repository is under the [MIT licence](LICENSE.md). MATLAB is
proprietary software by The MathWorks, Inc., under its own licence terms. You install
it from MathWorks. This repository does not include or redistribute it.
