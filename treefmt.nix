{ pkgs, ... }:
{
  # Used to find the project root
  projectRootFile = "flake.nix";
  settings.global.excludes = [
    "pkgs/mdl-sdk/llvm/**"
  ];
  programs = {
    black.enable = true;
    cmake-format.enable = true;
    jsonfmt = {
      enable = true;
      package = pkgs.hujsonfmt;
    };
    just.enable = true;
    mdformat.enable = true;
    deadnix.enable = true;
    statix.enable = true;
    keep-sorted.enable = true;
    nixfmt.enable = true;
    shfmt.enable = true;
    yamlfmt.enable = true;
  };
}
