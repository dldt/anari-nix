{
  description = ''
    Some tools I am missing from the main nixpkgs store.
  '';

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://dldt.cachix.org/"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "dldt.cachix.org-1:lF3I8Yijsqk+5+ZjH3QCLYrPvKadXpL41fsdIpM5Rss="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixpkgs-unstable";
    nixpkgs-2505.url = "github:NixOS/nixpkgs?ref=release-25.05";
    systems.url = "github:nix-systems/default";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-2505,
      systems,
      treefmt-nix,
    }:
    let
      inherit (nixpkgs) lib;
      forEachSystem = systems: lib.genAttrs systems;
      forAllDefaultSystems = forEachSystem (import systems);

      filterDerivations =
        packages:
        lib.attrsets.filterAttrs (packageName: packageDesc: lib.attrsets.isDerivation packageDesc) packages;

      filterSystem =
        system: packages:
        lib.attrsets.filterAttrs (
          packageName: packageDesc:
          let
            packagePlatforms = packageDesc.meta.platforms or [ system ];
          in
          builtins.elem system packagePlatforms
        ) packages;

      filterOutNixGLEnv =
        packages: lib.attrsets.filterAttrs (packageName: packageDesc: packageName != "nixglenv") packages;

      pkgs =
        system:
        let
          pkgs-2505 = import nixpkgs-2505 {
            inherit system;
            config = {
              allowUnfree = true;
              cudaSupport = false;
            };
          };
        in
        import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            cudaSupport = false;
          };
          # Make sure we first apply our local overrides
          overlays = [
            (_: _: { inherit (pkgs-2505) llvmPackages_12; })
            (import ./overrides.nix)
          ];
        };

      packages =
        system:
        filterOutNixGLEnv (
          filterSystem system (
            filterDerivations (
              lib.packagesFromDirectoryRecursive {
                inherit (pkgs system) callPackage newScope;
                directory = ./pkgs;
              }
            )
          )
        );

      # Same, enabling CUDA support
      pkgsCuda =
        system:
        let
          pkgs-2505 = import nixpkgs-2505 {
            inherit system;
            config = {
              allowUnfree = true;
              cudaSupport = false;
            };
          };
        in
        import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            cudaSupport = true;
          };
          # Make sure we first apply our local overrides
          overlays = [
            (_: _: { inherit (pkgs-2505) llvmPackages_12; })
            (import ./overrides.nix)
          ];
        };

      packagesCuda =
        system:
        filterOutNixGLEnv (
          filterDerivations (
            lib.packagesFromDirectoryRecursive {
              inherit (pkgsCuda system) callPackage newScope;
              directory = ./pkgs;
            }
          )
        );

      treefmtEval = system: treefmt-nix.lib.evalModule (pkgs system) ./treefmt.nix;

      # CUDA dumb introspection
      canDoCuda = system: system == "x86_64-linux" || system == "aarch64-linux";

    in
    {
      packages = forAllDefaultSystems packages;

      overlays.default = import ./overlay.nix;

      checks = forAllDefaultSystems (
        system:
        filterDerivations {
          format = (treefmtEval system).config.build.check self;
          packages = (pkgs system).linkFarm "packages" (packages system);
          packagesCuda =
            if (canDoCuda system) then
              (pkgsCuda system).linkFarm "packagesCuda" (packagesCuda system)
            else
              null;
        }
      );

      formatter = forAllDefaultSystems (system: (treefmtEval system).config.build.wrapper);

      templates.default = {
        path = ./templates/default;
        description = "A very basic ANARI flake";
      };

      devShells = forAllDefaultSystems (
        system: with (pkgs system); {
          default = mkShell {
            buildInputs = [
              cachix
              nix
              nix-update
              nix-prefetch-git
              python3Packages.pygit2
              python3Packages.pygithub
            ];
          };
        }
      );
    };
}
