{
  lib,
  stdenv,
  fetchFromGitHub,
  config,
  cudaSupport ? config.cudaSupport,
  cmake,
  anari-sdk,
  cudaPackages,
  glm,
  zlib,
  python3,
  nix-update-script,
}:
stdenv.mkDerivation {
  pname = "anari-vsr";
  version = "0-unstable-2026-09-10";

  # Main source. Shared with the vela package, which builds the applications
  # from the same tree.
  src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "Vela";
    rev = "0b3664774b5b1d2bab32a76e78798e5bc312caed";
    hash = "sha256-VSyi8MNYGmMF8Aeoec7q6qVFFbnggrdI3Ckk6lzhLVo=";
  };

  # Lives in the vela package, which needs the same fix. Without it the
  # unconditional imnodes subdirectory downloads an archive nothing here builds.
  patches = [ ../vela/0002-fetch-imnodes-only-for-viskores-demo.patch ];

  # The device captures ANARI state rather than loading scenes, so none of the
  # importer backends are of use to it -- and leaving them off keeps the runtime
  # closure to the device itself.
  cmakeFlags = [
    (lib.cmakeBool "BUILD_TESTING" false)
    (lib.cmakeBool "VSR_BUILD_APPS" false)
    (lib.cmakeBool "VSR_BUILD_UI_LIBRARY" false)
    (lib.cmakeBool "VSR_USE_ASSIMP" false)
    (lib.cmakeBool "VSR_USE_CUDA" cudaSupport)
    (lib.cmakeBool "VSR_USE_HDF5" false)
    (lib.cmakeBool "VSR_USE_LUA" false)
    (lib.cmakeBool "VSR_USE_SDL3" false)
    (lib.cmakeBool "VSR_USE_SILO" false)
    (lib.cmakeBool "VSR_USE_TBB" false)
    (lib.cmakeBool "VSR_USE_USD" false)
    (lib.cmakeBool "VSR_USE_VTK" false)
  ];

  nativeBuildInputs = [
    cmake
    python3
  ]
  ++ lib.optionals cudaSupport [
    cudaPackages.cuda_nvcc
  ];

  buildInputs = [
    anari-sdk
    glm
    zlib
  ]
  ++ lib.optionals cudaSupport [
    cudaPackages.cuda_cudart
    cudaPackages.cuda_cccl
  ];

  doInstallCheck = true;

  nativeInstallCheckInputs = [ anari-sdk ];

  # ANARI dlopens libanari_library_<subtype>.so through the loader search path,
  # so this proves the library both links and registers its subtype.
  installCheckPhase = ''
    runHook preInstallCheck

    LD_LIBRARY_PATH="''${out}/lib''${LD_LIBRARY_PATH:+:''${LD_LIBRARY_PATH}}" \
      anariInfo -l vsr

    runHook postInstallCheck
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version=branch"
      "--flake"
    ];
  };

  meta = with lib; {
    description = "Vela's VSR device for ANARI, capturing ANARI state into a VSR scene";
    homepage = "https://github.com/NVIDIA/Vela";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}
