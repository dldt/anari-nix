{
  cmake,
  fetchFromGitHub,
  lib,
  stdenv,
}:
let
  # Main source.
  version = "v0.9.4";
  conduit-src = fetchFromGitHub {
    owner = "llnl";
    repo = "conduit";
    rev = version;
    fetchSubmodules = true;
    hash = "sha256-xs/9hsE1DLCegXp3CHSl6qpC4ap+niNAWX5lNlUxz9E=";
  };
in
stdenv.mkDerivation {
  inherit version;

  pname = "conduit";

  src = conduit-src // {
    outPath = conduit-src + "/src";
  };

  nativeBuildInputs = [
    cmake
  ];

  meta = with lib; {
    description = "Simplified Data Exchange for HPC Simulations.";
    homepage = "https://software.llnl.gov/conduit/";
    license = licenses.bsd0;
    platforms = platforms.unix;
  };
}
