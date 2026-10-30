{
  anari-sdk,
  cmake,
  fetchFromGitHub,
  fetchurl,
  imath,
  ispc,
  lib,
  nix-update-script,
  python3,
  stdenv,
}:
let
  # Mirror the archives expected by anari_sdk_fetch_project so configuration
  # works in the build sandbox. Embree and MaterialX are built statically with
  # private symbols by upstream; their installed shared libraries cannot replace them.
  archives = {
    anari_embree = fetchurl {
      url = "https://github.com/RenderKit/embree/archive/refs/tags/v4.3.3.zip";
      hash = "sha256-Y9ZOWHlb3fbpxWT2aJVky4WHaU4CXn7HeQdyzIIYs7k=";
    };
    halcyon_openqmc = fetchurl {
      url = "https://github.com/AcademySoftwareFoundation/openqmc/archive/refs/tags/v0.7.1.zip";
      hash = "sha256-rSEH5HPojXyub/O813Hiw6I8ZPCusl07FCukci7rlrg=";
    };
    halcyon_materialx = fetchurl {
      url = "https://github.com/AcademySoftwareFoundation/MaterialX/archive/38368ee04da84ce1f8837ecba7322dd6d81291f8.zip";
      hash = "sha256-kf/Z0A96UWmQ4/XWTs/tx/7WgOXiEs49/XpES1cjjjY=";
    };
    halcyon_stb = fetchurl {
      url = "https://github.com/nothings/stb/archive/2c980bb59875b0d32144a71867fbdebb2f77cd20.zip";
      hash = "sha256-jln3KweAaQzaZHJoBCafY4o753udFQbqlfRD95ZLzPA=";
    };
    halcyon_tinyexr = fetchurl {
      url = "https://github.com/syoyo/tinyexr/archive/refs/tags/v1.0.13.zip";
      hash = "sha256-oR75+aBs2f8bhfpLI6W4kHuxA7Y8m/xv++1xT0FNxk8=";
    };
  };
in
stdenv.mkDerivation {
  pname = "anari-halcyon";
  version = "0.16.0-unstable-2026-10-30";

  src = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "ANARI-SDK";
    rev = "c5fbea18c99be7d5fce666522f35997c62c9cb29";
    hash = "sha256-DmhZWLucnQsOhLCwFOarjehFHqi9yeaj+CU3hAZDMPo=";
  };
  sourceRoot = "source/src/devices/halcyon";

  postUnpack = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: archive: ''
      mkdir -p "''${sourceRoot}/.anari_deps/${name}"
      cp "${archive}" "''${sourceRoot}/.anari_deps/${name}/${archive.name}"
    '') archives
  );

  nativeBuildInputs = [
    cmake
    ispc
    python3
  ];

  buildInputs = [
    anari-sdk
    imath
  ];

  cmakeFlags = [
    (lib.cmakeBool "HALCYON_BUILD_TESTS" true)
    # Do not let ISPC select an ISA based on the build machine's CPU.
    (lib.cmakeFeature "CMAKE_ISPC_INSTRUCTION_SETS" (
      if stdenv.hostPlatform.isAarch64 then "neon-i32x4" else "sse2-i32x4;avx2-i32x8"
    ))
  ];

  # tinyexr's archive contains non-ASCII filenames.
  env.LC_ALL = if stdenv.hostPlatform.isDarwin then "en_US.UTF-8" else "C.UTF-8";

  doCheck = true;

  # Upstream's tests point the ANARI loader at the build-tree device with
  # LD_LIBRARY_PATH, which dyld ignores: without this the loader falls back to
  # an anchored load next to the installed libanari and finds no halcyon.
  preCheck = lib.optionalString stdenv.hostPlatform.isDarwin ''
    export DYLD_LIBRARY_PATH="$PWD''${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}"
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--flake"
      "--version=branch=next_release"
    ];
  };

  meta = with lib; {
    description = "Halcyon CPU rendering device, based on Embree and ISPC, for ANARI";
    homepage = "https://github.com/KhronosGroup/ANARI-SDK/tree/next_release/src/devices/halcyon";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}
