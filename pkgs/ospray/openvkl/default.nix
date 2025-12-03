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

  src = fetchFromGitHub {
    owner = "RenderKit";
    repo = "openvkl";
    rev = "8c6ba526813b871a624cb9d73d4cbb689ac7f4ce";
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
