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
    rev = "ea8baea3b9d854bf9cf5c834a805c50948dd2603";
    hash = "sha256-JlT4VFs8aVlW+l151HZIZumfFsccZXcO/k5WpbYF09Y=";
  };

  nixgl = import src {
    inherit pkgs;
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
