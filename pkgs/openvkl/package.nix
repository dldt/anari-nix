{
  cmake,
  embree,
  fetchFromGitHub,
  ispc,
  lib,
  openvdb,
  rkcommon_0_14_2,
  stdenv,
  tbb,
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

  cmakeFlags = with lib; [
    (cmakeBool "BUILD_EXAMPLES" false)
    (cmakeFeature "CMAKE_POLICY_VERSION_MINIMUM" "3.5")
  ];

  buildInputs = [
    embree
    openvdb
    rkcommon_0_14_2
    tbb
  ];

  meta = with lib; {
    description = "A collection of high-performance volume computation kernels.";
    homepage = "https://github.com/RenderKit/openvkl";
    license = licenses.apsl20;
    platforms = platforms.unix;
  };
}
