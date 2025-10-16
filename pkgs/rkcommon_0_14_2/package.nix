{
  cmake,
  fetchFromGitHub,
  lib,
  stdenv,
  tbb,
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

  prePatch = ''
    substituteInPlace cmake/FindTBB.cmake --replace-fail \
      'set(TBB_ROOT "''${TBB_ROOT}" CACHE PATH "The root path of TBB.")' \
      'set(TBB_ROOT "${tbb}" CACHE PATH "The root path of TBB.")''\nset(TBB_INCLUDE_DIR "${lib.getDev tbb}/include" CACHE PATH "The include directories of TBB.")'
  '';

  nativeBuildInputs = [
    cmake
  ];

  transitiveBuildInputs = [
    tbb
  ];

  cmakeFlags = [
    (lib.cmakeFeature "TBB_DIR" "${tbb}")
  ];

  meta = with lib; {
    description = "A common set of C++ infrastructure and CMake utilities used by various components of Intel Rendering Toolkit.";
    homepage = "https://github.com/RenderKit/rkcommon";
    license = licenses.apsl20;
    platforms = platforms.unix;
  };
}
