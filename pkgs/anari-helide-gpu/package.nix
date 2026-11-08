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
  implib-so-src = fetchFromGitHub {
    owner = "yugr";
    repo = "Implib.so";
    rev = "a3e167cf978a5b8a38ec0f710d8c4331e8dcdd9a";
    hash = "sha256-T+q2LXQogD7KCHevU5HW8XPkzC3DzfjD41gtlJZ6i/M=";
  };
in
stdenv.mkDerivation {
  pname = "anari-helide-gpu";
  version = "0.16.0-unstable-2026-11-06";

  # Main source
  src = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "ANARI-SDK";
    rev = "62f5007711f8ed5c0c8f1307c3717b581b4611ec";
    hash = "sha256-b3cBU/S+2S/+pkEbzC8tQgpF6XguuuBh8LtRTO5ejYM=";
  };
  sourceRoot = "source/src/devices/helide_gpu";

  postUnpack = ''
    mkdir -p "''${sourceRoot}/.anari_deps/anari_helide_gpu_glm/"
    cp "${glm_for_helide_gpu-src}" "''${sourceRoot}/.anari_deps/anari_helide_gpu_glm/1.0.1.zip"
  '';

  # This upstream FetchContent_Populate call uses the explicit form, which
  # ignores FETCHCONTENT_SOURCE_DIR_IMPLIB_SO. Supply the pinned source directly.
  postPatch = lib.optionalString stdenv.hostPlatform.isLinux ''
    substituteInPlace CMakeLists.txt \
      --replace-fail 'FetchContent_Populate(implib_so
        GIT_REPOSITORY https://github.com/yugr/Implib.so.git
        GIT_TAG a3e167cf978a5b8a38ec0f710d8c4331e8dcdd9a
        SOURCE_DIR ''${CMAKE_BINARY_DIR}/_deps/implib_so-src
        BINARY_DIR ''${CMAKE_BINARY_DIR}/_deps/implib_so-build
      )' 'set(implib_so_SOURCE_DIR "${implib-so-src}")'
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
