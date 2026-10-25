# Dev notes

## MathWorksServiceHost rewrites `mimeapps.list`

Status: the overlay workaround is in `matlab.nix` (`hiddenDirs`). The README tells
users about it under "Known issues". The workaround is not tested against a real
ServiceHost update (see below).

### What writes the files

`MathWorksServiceHost` writes them, not MATLAB. The code is
`registerOpenInDesktopProtocolHandler` in
`~/.MathWorks/ServiceHost/-mw_shared_installs/<version>/bin/glnxa64/libmwagentmlcshortcututils.so`.
It writes the files directly and does not use `xdg-mime`. It writes:

- `mw-matlab.desktop`, `mw-simulink.desktop` and `mw-matlabconnector.desktop` in
  `~/.local/share/applications/`
- the three `x-scheme-handler/mw-*` lines in `~/.local/share/applications/mimeapps.list`
- `mathworks-service-host.desktop` in `~/.config/autostart/`

It finds the directory with `foundation::paths::getAppdataPath`, which seems to use
`$HOME` and not `XDG_DATA_HOME`. A `foundation::feature` flag controls the code, but
the flag name is not in the strings of the library. No setting or environment
variable to turn it off was found.

### What triggers it

The write occurs at the first start of a new ServiceHost version, after it installs
or updates itself. On 2026-10-26, the files got the timestamp 01:28:37. The
ServiceHost logs show that v2026.11.0.3 started for the first time at that moment.
That version was an auto-update from v2026.7.1.1 during a MATLAB session.

These did not trigger the write (with the handler files removed first):

- `matlab -batch`
- `matlab -desktop` for 30 seconds
- a reinstall of v2026.7.1.1 from the MATLAB installation, after
  `~/.MathWorks/ServiceHost` was moved aside

Thus the real test is the next ServiceHost update. To force one, move
`~/.MathWorks/ServiceHost` aside and keep a MATLAB desktop open until a new
`-mw_shared_installs/v*` directory appears. Then compare the files on the host with
the files in `/proc/<ServiceHost pid>/root$HOME/...`.

### Why the workaround is an overlay

- ServiceHost continues to run after MATLAB exits, but it stays in the `matlab-env`
  mount namespace. Thus a bwrap mount also applies to it.
- bwrap cannot mount on a symlink ("Can't mount on symlink destination"). Thus a bind
  on `mimeapps.list` itself is not possible.
- `--overlay-src DIR --tmp-overlay DIR` (bubblewrap 0.10 and later) shows the real
  files and keeps all changes in a tmpfs. A scratch test confirmed that a replacement
  of a symlink in the overlay does not get to the real directory.
- A `--tmpfs` on the directory also blocks the write. But it hides the
  `.desktop` files of the user from `xdg-open` in the environment.

Known limit: Home Manager can change the real directory while MATLAB runs. Overlayfs
does not support changes to its lower directory, so MATLAB can then see old files.

### Fallback if the overlay fails

Make Home Manager overwrite the file:

```nix
xdg.dataFile."applications/mimeapps.list".force = lib.mkIf config.xdg.mimeApps.enable true;
```

- Guard it with `xdg.mimeApps.enable`. Without the guard, `force` alone defines a file
  with no `source`, and the evaluation fails.
- `module.nix` is shared with the NixOS module, which has no `xdg.dataFile`. It needs a
  flag such as `isHomeManager` from `flake.nix`, next to `packagesOption`.
- The handlers are not useful to ship in the package. Their `Exec` lines point into a
  versioned ServiceHost directory.

### Possible opt-out

If a user wants the `mw-matlab:` links (non-NixOS, no Home Manager `xdg.mimeApps`),
add a package argument `hideDesktopRegistration ? true` to `matlab.nix`. Do not add a
module option. Users can set the argument with `.override`, as with `installDir`.
