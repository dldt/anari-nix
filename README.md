# anari-nix

Nix flake packaging the [ANARI](https://www.khronos.org/anari/) ecosystem and
its related renderers, debuggers, and file formats — tools not (yet) in
nixpkgs.

## Usage

Add the flake to your inputs and either use the overlay or pull individual
packages:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    anari-nix.url = "github:dldt/anari-nix";
  };
}
```

- **Overlay** — `overlays.default` adds every package here to nixpkgs'
  package and Python package sets.
- **Packages** — `packages.<system>.<name>` exposes the packages directly.
  All packages are built twice: once with CUDA disabled (`packages`), and
  once with CUDA enabled where the platform supports it.

See `pkgs/` for the current package list; each directory contains a
`package.nix`. Python packages live under `python-pkgs/` and are only
available through the overlay.

You can also bootstrap a new project with the bundled template:

```console
nix flake init -t anari-nix
```

## Updating packages

Packages are updated weekly by CI (`update-packages.yml`, backed by
`scripts/update.py`):

```console
nix develop -c ./scripts/update.py
```

Most packages expose `passthru.updateScript` and update themselves; the rest
fall back to `nix-update --flake`. Packages that are intentionally pinned or
inherit sources from nixpkgs are listed in `SKIPPED_PACKAGES` in
`scripts/update.py`.

The flake input lockfile is updated weekly (`update-flake-lock.yml`).

## Development

`nix develop` provides `cachix`, `nix-update`, and the Python helpers the
update script needs. Formatting (`nix fmt`) is enforced by treefmt; run
`nix fmt` before committing and `nix fmt -- --ci` in CI mode.
