{
  lib,
  python3Packages,
  meson,
  fetchFromGitHub,
  stdenv,
  pkg-config,
  hdf5,
  ninja,
}:
let
  # Main source.
  src = fetchFromGitHub {
    owner = "pyCGNS";
    repo = "pyCGNS";
    rev = "1b7230cc3604a8b53ca8800ff9930a683452f4f7";
    hash = "sha256-idyOr9toW26r1M0Jnqlg0+jKt9W7ZqjRK1/FY03Z8uU=";
  };

in
stdenv.mkDerivation {
  pname = "pycgns";
  version = "v6.3.4-2-g1b7230c";

  inherit src;

  nativeBuildInputs = [
    meson
    pkg-config
    python3Packages.cython
    ninja
  ];

  buildInputs = [
    python3Packages.numpy
    hdf5
  ];

  meta = with lib; {
    description = "pyCGNS is a set of Python modules implementing the CFD General Notation System standard.";
    homepage = "http://pycgns.github.io/";
    license = licenses.lgpl21Only;
    platforms = platforms.unix;
  };
}
