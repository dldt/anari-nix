{
  description = ''
    Some tools I am missing from the main nixpkgs store.
  '';

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixpkgs-unstable";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      treefmt-nix,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;

          overlays = [
            (import ./overrides.nix)
          ];
        };

        allPackages = import ./packages.nix self.packages.${system} pkgs;

        platformPackages = builtins.removeAttrs allPackages (
          builtins.filter (
            x: allPackages.${x} ? "meta" && !builtins.elem system allPackages.${x}.meta.platforms
          ) (builtins.attrNames allPackages)
        );
        packages = builtins.removeAttrs platformPackages [ "nixglenv" ];
        treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
      in
      {
        packages = packages;
        formatter = treefmtEval.config.build.wrapper;

        # A devShell exposing those packages.
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            git
            github-cli
            jq
            nix-prefetch-git
          ];
        };

        checks = packages;
      }
    )
    // (
      let
        overlay = import ./default.nix;
      in
      {
        overlays.default = final: prev: overlay final prev;
      }
    );
}
