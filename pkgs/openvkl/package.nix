{
  cmake,
  embree,
  fetchFromGitHub,
  ispc,
  lib,
  openvdb,
  rkcommon,
  stdenv,
  tbb,
}:
stdenv.mkDerivation {
  pname = "openvkl";
  version = "2.0.1";

  # Main source.
  src = fetchFromGitHub {
    owner = "RenderKit";
    repo = "openvkl";
    tag = "2.0.1";
    hash = "sha256-kwthPHGy833KY+UUxkPbnXDKb+Li32NRNt2yCA+vL1A=";
  };

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
    rkcommon
    tbb
  ];

  meta = with lib; {
    description = "A collection of high-performance volume computation kernels.";
    homepage = "https://github.com/RenderKit/openvkl";
    license = licenses.apsl20;
    platforms = platforms.unix;
  };
}
