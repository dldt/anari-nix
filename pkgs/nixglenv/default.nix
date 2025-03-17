{
  pkgs,
  lib,
  shfmt,
  stdenv,
  fetchFromGitHub,
}:
let
  src = fetchFromGitHub {
    owner = "nix-community";
    repo = "nixGL";
    rev = "310f8e49a149e4c9ea52f1adf70cdc768ec53f8a";
    hash = "sha256-lnzZQYG0+EXl/6NkGpyIz+FEOc/DSEG57AP1VsdeNrM=";
  };

  nixgl = import src {
    pkgs = pkgs;
  };
in
stdenv.mkDerivation {
  inherit src;

  pname = "nixglenv";
  version = "main";

  buildInputs = [ shfmt ];

  # NixGL. Source both Nvidia specific environment and general Intel one, so the content can be run on true hardware
  # or through xrdp/glamor
  installPhase = ''
    echo -e "# NVIDIA\n" > ''${out}
    sed -e '/^\s*exec "/d' -e '/^#!\//d' "${nixgl.auto.nixGLNvidia.outPath}/bin/${nixgl.auto.nixGLNvidia.name}" >> ''${out}
    echo -e "\n# Fallback\n" >> ''${out}
    sed -e '/^\s*exec "/d' -e '/^#!\//d' "${nixgl.nixGLIntel.outPath}/bin/${nixgl.nixGLIntel.name}" >> ''${out}

    shfmt -w ''${out}
  '';

  meta = with lib; {
    description = "Expose nixGL environment as a single sourceable file.";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
