{
  cmake,
  embree,
  fetchFromGitHub,
  ispc,
  lib,
  openvdb,
  rkcommon_0_14_0,
  stdenv,
  tbb_2021_11,
}:
let
  version = "v2.0.1";

  # Main source.
  src = fetchFromGitHub {
    owner = "RenderKit";
    repo = "openvkl";
    tag = version;
    hash = "sha256-kwthPHGy833KY+UUxkPbnXDKb+Li32NRNt2yCA+vL1A=";
  };
in
stdenv.mkDerivation {
  inherit src version;
  pname = "openvkl";

  nativeBuildInputs = [
    cmake
    ispc
  ];

  cmakeFlags = [
    "-DBUILD_EXAMPLES=OFF"
  ];

  buildInputs = [
    embree
    openvdb
    rkcommon_0_14_0
    tbb_2021_11
  ];

  meta = with lib; {
    description = "A collection of high-performance volume computation kernels.";
    homepage = "https://github.com/RenderKit/openvkl";
    license = licenses.apsl20;
    platforms = platforms.unix;
  };
}
