{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  anari-sdk,
  pkg-config,
  cudaPackages,
  materialx,
  mdl-sdk,
  nvidia-optix,
  python3,
  nix-update-script,
}:
stdenv.mkDerivation {
  pname = "visrtx";
  version = "26.09-unstable-2026-11-25";

  # Main source.
  src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "VisRTX";
    rev = "bb2b92560b6006a78555e100f2849ccc101d563d";
    hash = "sha256-0aE8pEf2E2R355D2dUtjsLlVz3UdfZ05P1KtN9HGcEU=";
  };

  cmakeFlags = with lib; [
    (cmakeBool "FETCHCONTENT_FULLY_DISCONNECTED" true)
    (cmakeFeature "OptiX_ROOT_DIR" (toString nvidia-optix))
    (cmakeBool "VISRTX_BUILD_GL_DEVICE" false)
    (cmakeBool "VISRTX_ENABLE_MDL_SUPPORT" true)
    (cmakeBool "VISRTX_ENABLE_MATERIALX_SUPPORT" true)
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
    cudaPackages.libcurand.static
    nvidia-optix

    # MDL, MaterialX
    materialx
    mdl-sdk
  ];

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version=branch"
      # Ignore administrative tags such as tsd_removed, retaining branch snapshots.
      "--version-regex=^v?([0-9]+\\.[0-9]+(?:\\.[0-9]+)?-unstable-[0-9-]+)$"
      "--flake"
    ];
  };

  meta = with lib; {
    description = "VisRTX is an experimental, scientific visualization-focused implementation of the Khronos ANARI standard.";
    homepage = "https://github.com/NVIDIA/VisRTX";
    license = licenses.bsd3;
    platforms = [ "x86_64-linux" ];
  };
}
