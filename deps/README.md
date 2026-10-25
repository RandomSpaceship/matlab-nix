# Dependency lists

The files in this directory give the packages in the MATLAB environment for each
release. The `release` option (default R2026b) selects one file.

| File | What it is |
|---|---|
| `r<release>.nix` | The packages for one release. The script makes these files. Do not edit them. |
| `mapping.nix` | The nixpkgs attribute for each Debian package name. You edit this file. |
| `update-deps.py` | The script that makes the `r<release>.nix` files. |

[fhs-packages.nix](../fhs-packages.nix) adds a small set of packages to every release.
These packages are not in the MathWorks lists, because a Debian system always has them.

## Where the lists come from

MathWorks publishes the Debian packages that each release needs, in
[container-images](https://github.com/mathworks-ref-arch/container-images). The script
reads `matlab-deps/<release>/ubuntu24.04/base-dependencies-amd64.txt` for each release.
All releases from R2023a use the same Ubuntu version, thus the package names stay
the same across releases. Each generated file records the commit that it came from.

## Update the files

Run these commands from the root of the repository.

1. To make all files in this directory again from the latest lists, run this command:

   ```sh
   nix run .#update-deps
   ```

2. To add a release, give its name:

   ```sh
   nix run .#update-deps -- R2027a
   ```

3. To read the lists at a specified commit of container-images, use `--commit`:

   ```sh
   nix run .#update-deps -- --commit 0894c8dfd99679c1a11e3f33aec02b65cf31512c
   ```

4. Run `git diff deps/` and read the changes.
5. Run `nix flake check`. The `deps` check makes sure that each attribute is in
   nixpkgs.

Without the flake app, run `python3 -I deps/update-deps.py`. The script needs `nix`
and `nixfmt` on `PATH`. It reads `GITHUB_TOKEN` if you set it, but it does not need it.

## When the script stops at an unknown package

If a list has a Debian package that is not in `mapping.nix`, the script writes no
files. It shows each unknown name and the releases that have it.

1. Find the library that the Debian package supplies, on
   [packages.ubuntu.com](https://packages.ubuntu.com/).
2. Find the nixpkgs package with that library, for example with
   `nix-locate libfoo.so.1` (from nix-index).
3. Add the name to `mapping.nix`. The value is an attribute path in a string, a list
   of them, or `null`. Use `null` to leave a package out, and write the reason in a
   comment.
4. Run the script again.

## Packages that are left out

- `libboost-*`: MATLAB has its own copy of Boost.
- `sudo`: a setuid program does not work in the bubblewrap environment.
- `libdlt2` (R2026b): nixpkgs does not have COVESA DLT. The R2026b desktop starts
  without it.
- `libuhd4.6.0-dpdk` (R2025a to R2026a): the list needs `libuhd.so.4.6.0`, but nixpkgs
  has a later UHD version with a different soname.

## Testing

Only R2026b is tested with a real MATLAB installation. For the other releases, the
check makes sure only that the package list evaluates.
