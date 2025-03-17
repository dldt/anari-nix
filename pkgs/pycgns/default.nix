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
    rev = "68331a1cbfd9463e906b169af5b74dbbace19ed9";
    hash = "sha256-ZqNkQo8Ml72yr37frfPrSOVsW83TDQpW5sYPw3grgbU=";
  };

in
stdenv.mkDerivation {
  pname = "pycgns";
  version = "v6.3.1";

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
