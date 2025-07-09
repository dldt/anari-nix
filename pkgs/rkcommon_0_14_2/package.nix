{
  cmake,
  fetchFromGitHub,
  lib,
  stdenv,
  tbb_2021,
}:
let
  version = "v1.14.2";

  # Main source.
  src = fetchFromGitHub {
    owner = "RenderKit";
    repo = "rkcommon";
    tag = version;
    hash = "sha256-ezUvl/zr/mLEN4lJnvZRvFbf619JpaqfvqXbEa62Ovc=";
  };
in
stdenv.mkDerivation {
  inherit src version;
  pname = "rkcommon0_14_2";

  nativeBuildInputs = [
    cmake
  ];

  propagatedBuildInputs = [
    tbb_2021
  ];

  meta = with lib; {
    description = "A common set of C++ infrastructure and CMake utilities used by various components of Intel Rendering Toolkit.";
    homepage = "https://github.com/RenderKit/rkcommon";
    license = licenses.apsl20;
    platforms = platforms.unix;
  };
}
