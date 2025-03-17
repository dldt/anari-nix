{
  cmake,
  fetchFromGitHub,
  lib,
  stdenv,
}:
let
  # Main source.
  version = "v0.9.3";
  conduit-src = fetchFromGitHub {
    owner = "llnl";
    repo = "conduit";
    rev = version;
    fetchSubmodules = true;
    hash = "sha256-R7DiMwaMG9VfqDJiO3kFPb76j6P2GZl/6qLxDfVex8A=";
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
