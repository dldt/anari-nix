{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  anari-sdk,
  pkg-config,
  cudaPackages,
  mdl-sdk,
  nvidia-optix,
  python3,
}:
stdenv.mkDerivation {
  pname = "visrtx";
  version = "v0.12.0-304-g68766e2";

  # Main source.
  src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "VisRTX";
    rev = "68766e23b235fb612b15fe6794891e4f24ae6d8c";
    hash = "sha256-er9jx1jahL0auDx45rmV+JKXfYJk7ZZl2W4X4s8qd3s=";
  };

  cmakeFlags = with lib; [
    (cmakeBool "FETCHCONTENT_FULLY_DISCONNECTED" true)
    (cmakeFeature "OptiX_ROOT_DIR" (builtins.toString nvidia-optix))
    (cmakeBool "VISRTX_BUILD_GL_DEVICE" false)
    (cmakeBool "VISRTX_ENABLE_MDL_SUPPORT" true)
    (cmakeBool "VISRTX_PRECOMPILE_SHADERS" false)

    (cmakeFeature "OPTIX_FETCH_VERSION" "${versions.majorMinor nvidia-optix.version}")
    (cmakeBool "VISRTX_ENABLE_NEURAL" false)
  ];

  patches = [
    ./disable-optix-headers-fetch.patch
  ];

  postFixup = ''
    patchelf --add-rpath ${mdl-sdk}/lib/ $out/lib/libanari_library_visrtx.so
  '';

  nativeBuildInputs = [
    cudaPackages.cuda_nvcc

    cmake
    pkg-config
    python3
  ];

  buildInputs = [
    anari-sdk

    # CUDA and OptiX
    cudaPackages.cuda_cudart
    cudaPackages.cuda_cccl
    (lib.getDev cudaPackages.cuda_nvml_dev)

    cudaPackages.libcurand
    nvidia-optix

    # MDL
    mdl-sdk
  ];

  meta = with lib; {
    description = "VisRTX is an experimental, scientific visualization-focused implementation of the Khronos ANARI standard.";
    homepage = "https://github.com/NVIDIA/VisRTX";
    license = licenses.bsd3;
    platforms = platforms.linux;
  };
}
