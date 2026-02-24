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
  nix-update-script,
}:
stdenv.mkDerivation {
  pname = "visrtx";
  version = "0.13.0-unstable-2026-02-23";

  # Main source.
  src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "VisRTX";
    rev = "1ce4ce0703b7c8bdf0fbea12738317b77d328ddc";
    hash = "sha256-pq8aHwSkzd/v9ny48ex8G/dNP8fZArJOljklppFDnsc=";
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
    cudaPackages.libcurand.static
    nvidia-optix

    # MDL
    mdl-sdk
  ];

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version=branch"
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
