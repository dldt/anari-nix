{
  cmake,
  embree-ispc,
  fetchFromGitHub,
  ispc,
  lib,
  libGL,
  openimagedenoise,
  openvkl,
  rkcommon,
  stdenv,
}:
stdenv.mkDerivation {
  pname = "ospray";
  version = "3.2.0";

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
    embree-ispc
    libGL
    openimagedenoise
    openvkl
    rkcommon
  ];

  cmakeFlags = with lib; [
    (cmakeBool "OSPRAY_ENABLE_APPS" false)
    (cmakeBool "OSPRAY_MODULE_DENOISER" true)
    (cmakeBool "OSPRAY_MODULE_BILINEAR_PATCH" true)
  ];

  meta = with lib; {
    description = "OSPRay is an open source, scalable, and portable ray tracing engine.";
    homepage = "https://ospray.org";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
