final: prev:
let
  overlays = prev.lib.composeManyExtensions [
    (import ./overrides.nix)
    (import ./packages.nix)
    (import ./aliases.nix)
  ];
in
overlays final prev
