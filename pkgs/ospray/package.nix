{
  callPackage,
  cmake,
  embree-ispc,
  fetchFromGitHub,
  ispc,
  lib,
  libGL,
  openimagedenoise,
  stdenv,
}:
let
  openvkl = callPackage ./openvkl { inherit rkcommon; };
  rkcommon = callPackage ./rkcommon { };
in
stdenv.mkDerivation rec {
  pname = "ospray";
  version = "3.2.0";

  # Main source.
  src = fetchFromGitHub {
    owner = "RenderKit";
    repo = "ospray";
    rev = "v${version}";
    hash = "sha256-XUiQi3OZGC8JOcBMkLagMQHDuzCQ+mQ2BQXsqnJWSm0=";
  };

  nativeBuildInputs = [
    cmake
    ispc
  ];

  buildInputs = [
    embree-ispc
    libGL
    openimagedenoise
  ];

  propagatedBuildInputs = [
    openvkl
    rkcommon
  ];

  cmakeFlags =
    with lib;
    [
      (cmakeBool "OSPRAY_ENABLE_APPS" false)
      (cmakeBool "OSPRAY_MODULE_DENOISER" true)
      (cmakeBool "OSPRAY_MODULE_BILINEAR_PATCH" true)
    ]
    ++ optional stdenv.hostPlatform.isAarch64 (cmakeFeature "OSPRAY_BUILD_ISA" "NEON2X");

  meta = with lib; {
    description = "OSPRay is an open source, scalable, and portable ray tracing engine.";
    homepage = "https://ospray.org";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
