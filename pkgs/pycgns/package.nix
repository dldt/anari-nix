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
    rev = "c2b98650e96708ec141aaeb10581834047860dd0";
    hash = "sha256-WXoqYqpDZdrKa6yQavAarkecnTU9BKFA5t1Iv53Jp04=";
  };

in
stdenv.mkDerivation {
  pname = "pycgns";
  version = "v6.3.4";

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
