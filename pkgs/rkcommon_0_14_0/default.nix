{
  cmake,
  fetchFromGitHub,
  lib,
  stdenv,
  tbb_2021_11,
}:
let
  version = "v1.14.0";

  # Main source.
  src = fetchFromGitHub {
    owner = "RenderKit";
    repo = "rkcommon";
    tag = version;
    hash = "sha256-nUtoPImNM84XJmVvulEXaSsbiH2sfDEJwm2FkSR1Q94=";
  };
in
stdenv.mkDerivation {
  inherit src version;
  pname = "rkcommon0_14_0";

  nativeBuildInputs = [
    cmake
  ];

  propagatedBuildInputs = [
    tbb_2021_11
  ];

  meta = with lib; {
    description = "A common set of C++ infrastructure and CMake utilities used by various components of Intel Rendering Toolkit.";
    homepage = "https://github.com/RenderKit/rkcommon";
    license = licenses.apsl20;
    platforms = platforms.unix;
  };
}
