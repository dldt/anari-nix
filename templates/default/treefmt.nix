{ pkgs, ... }:
{
  # Used to find the project root
  projectRootFile = "flake.nix";
  programs = {
    black.enable = true;
    cmake-format.enable = true;
    jsonfmt = {
      enable = true;
      package = pkgs.hujsonfmt;
    };
    just.enable = true;
    mdformat.enable = true;
    nixfmt.enable = true;
    shfmt.enable = true;
    statix.enable = true;
    yamlfmt.enable = true;
  };
}
