{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  anari-sdk,
  python3,
  embree,
  ospray,
  openvkl,
  rkcommon_0_14_0,
}:
stdenv.mkDerivation {
  pname = "anari-ospray";
  version = "v0.0.0-47-g469438";

  # Main source.
  src = fetchFromGitHub {
    owner = "ospray";
    repo = "anari-ospray";
    rev = "469438d10c0cc92cb6dc05733b40bde6ecca0070";
    hash = "sha256-CvjdEjVEfdH1ETI+HDx2jxiCq3a8A79odLQqClKXu3E=";
  };

  patches = [
    ./fix-anari-0.13-sdk.patch # extrcted from https://github.com/ospray/anari-ospray/pull/24
  ];

  nativeBuildInputs = [
    cmake
    python3
  ];

  buildInputs = [
    anari-sdk
    embree
    ospray
    openvkl
    rkcommon_0_14_0
  ];

  meta = with lib; {
    description = "Translation layer from Khronos ANARI to Intel OSPRay: ANARILibrary and ANARIDevice 'ospray'.";
    homepage = "https://github.com/ospray/anari-ospray";
    license = licenses.apsl20;
    platforms = platforms.unix;
  };
}
