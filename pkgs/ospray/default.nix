{
  cmake,
  embree,
  fetchFromGitHub,
  ispc,
  lib,
  libGL,
  openimagedenoise,
  openvkl,
  rkcommon_0_14_0,
  stdenv,
}:
stdenv.mkDerivation {
  pname = "ospray";
  version = "v3.2.0";

  # Main source.
  src = fetchFromGitHub {
    owner = "RenderKit";
    repo = "ospray";
    rev = "85af2929937d516997451cbd52d352cf93125ed2";
    hash = "sha256-XUiQi3OZGC8JOcBMkLagMQHDuzCQ+mQ2BQXsqnJWSm0=";
  };

  nativeBuildInputs = [
    cmake
    ispc
  ];

  buildInputs = [
    embree
    libGL
    openimagedenoise
    openvkl
    rkcommon_0_14_0
  ];

  cmakeFlags = [
    "-DOSPRAY_ENABLE_APPS=OFF"
    "-DOSPRAY_MODULE_DENOISER=ON"
    "-DOSPRAY_MODULE_BILINEAR_PATCH=ON"
  ];

  meta = with lib; {
    description = "OSPRay is an open source, scalable, and portable ray tracing engine.";
    homepage = "https://ospray.org";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
