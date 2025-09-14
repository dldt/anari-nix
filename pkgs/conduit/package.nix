{
  cmake,
  fetchFromGitHub,
  lib,
  stdenv,
}:
let
  # Main source.
  version = "v0.9.5";
  conduit-src = fetchFromGitHub {
    owner = "llnl";
    repo = "conduit";
    rev = version;
    fetchSubmodules = true;
    hash = "sha256-mX7/5C4wd70Kx1rQyo2BcZMwDRqvxo4fBdz3pq7PuvM=";
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
