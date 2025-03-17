self: pkgs:
let
  overrides = import ./overrides.nix self pkgs;
  packages = import ./packages.nix self (pkgs // overrides);
in
packages // overrides
