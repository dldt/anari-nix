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
  implib-so-rev = "a3e167cf978a5b8a38ec0f710d8c4331e8dcdd9a";
  implib-so-src = fetchurl {
    url = "https://github.com/yugr/Implib.so/archive/${implib-so-rev}.zip";
    hash = "sha256-e1HoFg2dy8KwewP18NoQnhyd2XuaIXkVd7Asxmm6bcE=";
  };
in
stdenv.mkDerivation {
  pname = "anari-helide-gpu";
  version = "0.17.0-1-unstable-2026-11-25";

  # Main source
  src = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "ANARI-SDK";
    rev = "bbd28df094a209a7765d476c19a7d2dfabc95209";
    hash = "sha256-T5XQu+cUDBkNEATdqdd+5/hB3pYIOukrkASLKuJCF7I=";
  };
  sourceRoot = "source/src/devices/helide_gpu";

  postUnpack = ''
    mkdir -p "''${sourceRoot}/.anari_deps/anari_helide_gpu_glm/"
    cp "${glm_for_helide_gpu-src}" "''${sourceRoot}/.anari_deps/anari_helide_gpu_glm/1.0.1.zip"
  ''
  + lib.optionalString stdenv.hostPlatform.isLinux ''
    mkdir -p "''${sourceRoot}/.anari_deps/anari_helide_gpu_implib_so/"
    cp "${implib-so-src}" "''${sourceRoot}/.anari_deps/anari_helide_gpu_implib_so/${implib-so-rev}.zip"
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
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    # The device dlopens SDL3; use its store path instead of an unqualified SONAME.
    (lib.cmakeFeature "SDL3_SONAME" "${lib.getLib sdl3}/lib/libSDL3.so.0")
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
