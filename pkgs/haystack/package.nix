{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  anari-sdk,
  # The imgui viewer pulls in the owl submodule, whose project() declares CUDA
  # as a language, so nvcc is required regardless of config.cudaSupport.
  cudaPackages,
  autoAddDriverRunpath,
  glfw,
  libGL,
  tbb,
  libx11,
  nix-update-script,
}:
stdenv.mkDerivation {
  pname = "haystack";
  version = "0.9.0-unstable-2026-10-06";

  src = fetchFromGitHub {
    owner = "ingowald";
    repo = "HayStack";
    rev = "7d9fb0361d63f8a236c4ef524b7489dc1800b047";
    fetchSubmodules = true;
    hash = "sha256-ytHgvOSacXi2pdJqLp6gSRiU7kb/RzyPpQ57BnyZj0w=";
  };

  cmakeFlags = [
    (lib.cmakeBool "HS_CUTEE" false)
    (lib.cmakeFeature "CMAKE_CUDA_ARCHITECTURES" "all-major")
    # owl is only ever built, never installed by its parent project, so its
    # shared library would otherwise be linked against from the build tree.
    (lib.cmakeFeature "CMAKE_INSTALL_RPATH" "${placeholder "out"}/lib")
    (lib.cmakeBool "CMAKE_BUILD_WITH_INSTALL_RPATH" true)
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 -t "''${out}/bin" ./hsOffline ./hsViewer

    runHook postInstall
  '';

  nativeBuildInputs = [
    cmake
    cudaPackages.cuda_nvcc
    autoAddDriverRunpath
  ];

  buildInputs = [
    anari-sdk
    cudaPackages.cuda_cudart
    cudaPackages.cuda_cccl
    glfw
    libGL
    libx11
    tbb
  ];

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--flake"
      "--version=branch"
    ];
  };

  meta = with lib; {
    description = "ANARI-based viewer for scientific visualization data (meshes, volumes, AMR)";
    homepage = "https://github.com/ingowald/HayStack";
    license = licenses.asl20;
    # owl requires the CUDA toolkit, which is Linux-only.
    platforms = platforms.linux;
  };
}
