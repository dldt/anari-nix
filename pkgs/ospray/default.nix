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
  version = "v3.2.0-25-g675c216b9";

  # Main source.
  src = fetchFromGitHub {
    owner = "RenderKit";
    repo = "ospray";
    rev = "675c216b91a765bbd1cf8c7ae8e2c3c0684f21a0";
    hash = "sha256-/ufvfj4vNARw+LqPVRu5SJqbgFAKRG7Skbty8oz4EgM=";
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
