{
  description = ''
    An simple anari-nix template
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
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    anari-nix.url = "github:dldt/anari-nix";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      anari-nix,
      systems,
      treefmt-nix,
    }:
    let
      inherit (nixpkgs) lib;
      forEachSystem = systems: lib.genAttrs systems;
      forAllDefaultSystems = forEachSystem (import systems);

      # nixpkgs
      pkgs =
        system:
        import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            cudaSupport = system == "x86_64-linux" || system == "aarch64-linux";
          };
          overlays = [ anari-nix.overlays.default ];
        };

      # ANARI specific
      anariDevicePackages =
        pkgs:
        with pkgs;
        (
          [
            anari-cycles
            anari-visionaray
            anari-ospray
          ]
          ++ (lib.optionals pkgs.config.cudaSupport [
            anari-barney
            visrtx
          ])
          ++ (lib.optionals (system == "x86_64-linux") [ visgl ])
        );

      anariDevices =
        pkgs:
        pkgs.symlinkJoin {
          name = "anari-devices";
          paths = anariDevicePackages pkgs;
        };

      treefmtEval = system: treefmt-nix.lib.evalModule (pkgs system) ./treefmt.nix;
    in
    {
      packages = forAllDefaultSystems (
        system:
        let
          packages = pkgs system;
        in
        {
          default = packages.stdenv.mkDerivation {
            pname = "some-package";
            version = "1.0.0";
            dontUnpack = true;
            installPhase = ''
              mkdir -p $out/bin
              echo -e "#!/bin/sh\necho Hello, world!" > $out/bin/hello
              chmod +x $out/bin/hello
            '';
            meta = with lib; {
              description = "A simple package";
              license = licenses.mit;
              mainProgram = "hello";
            };
          };
        }
      );

      # The devShell for each system type.
      devShells = forAllDefaultSystems (
        system:
        let
          packages = pkgs system;
          devices = anariDevices packages;
        in
        {
          default = packages.mkShellNoCC {
            packages = [
              packages.tsd
              devices
            ];
          };
        }
      );

      # Treefmt
      formatter = forAllDefaultSystems (system: (treefmtEval system).config.build.wrapper);
    };
}
