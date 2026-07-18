{
  anari-sdk,
  cmake,
  fetchFromGitHub,
  fetchurl,
  lib,
  stdenv,
  glslang,
  python3,
  sdl3,
  spirv-cross,
  nix-update-script,
}:
let
  glm_for_helide_gpu-src = fetchurl {
    url = "https://github.com/g-truc/glm/archive/refs/tags/1.0.1.zip";
    hash = "sha256-CcVxYpZ4fh9/y4exy9vyaBTsEojtYlnM0w1dl5WAn6U=";
  };
in
stdenv.mkDerivation {
  pname = "anari-helide-gpu";
  version = "0.15.0-unstable-2026-07-18";

  # Main source
  src = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "ANARI-SDK";
    rev = "a44213eed2aebc6765f3967eae9729596315133b";
    hash = "sha256-SzzN1UXN7peCKZNP7w/0SzZhXBknpkW4NCr2MnUMXvM=";
  };
  sourceRoot = "source/src/devices/helide_gpu";

  postUnpack = ''
    mkdir -p "''${sourceRoot}/.anari_deps/anari_helide_gpu_glm/"
    cp "${glm_for_helide_gpu-src}" "''${sourceRoot}/.anari_deps/anari_helide_gpu_glm/1.0.1.zip"
  '';

  nativeBuildInputs = [
    cmake
    glslang
    python3
  ]
  # spirv-cross is required on Darwin to cross-compile shaders to MSL; on Linux
  # the SPIR-V shaders are used directly, so it is left out to skip the MSL step.
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    spirv-cross
  ];

  buildInputs = [
    anari-sdk
    sdl3
  ];

  # GLM is used header-only; building its (near-empty) compiled lib is pointless
  # and, since GLM_BUILD_INSTALL is off, a shared one would dangle at runtime.
  cmakeFlags = [
    (lib.cmakeBool "GLM_BUILD_LIBRARY" false)
  ];

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--flake"
      "--version=branch"
    ];
  };

  meta = with lib; {
    description = "Helide GPU device, SDL3_gpu based, for ANARI.";
    homepage = "https://www.khronos.org/anari/";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}
