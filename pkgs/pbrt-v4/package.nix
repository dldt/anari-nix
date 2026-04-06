{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  config,
  cudaSupport ? config.cudaSupport,
  optixSupport ? cudaSupport && stdenv.hostPlatform.isx86_64,
  cudaPackages,
  nvidia-optix,
  zlib,
  openexr,
  libGL,
  nix-update-script,
}:
stdenv.mkDerivation (_finalAttrs: {
  pname = "pbrt-v4";
  version = "0-unstable-2025-12-08";

  src = fetchFromGitHub {
    owner = "mmp";
    repo = "pbrt-v4";
    rev = "8c19f304558fd7681e2fef2c395a689d0106fb05";
    hash = "sha256-My/AOimAlDxxO89s8MwfckbnQwHXO7krY+pAyY0ctwI=";
    fetchSubmodules = true;
  };

  postPatch = ''
    # Disable git submodule hash validation (no .git in Nix builds)
    sed -i 's/function(CHECK_EXT NAME DIR HASH)/function(CHECK_EXT NAME DIR HASH)\n  return()/' CMakeLists.txt
  '';

  nativeBuildInputs = [
    cmake
  ]
  ++ lib.optionals cudaSupport [
    cudaPackages.cuda_nvcc
  ];

  buildInputs = [
    zlib
    openexr
  ]
  ++ lib.optionals cudaSupport [
    cudaPackages.cuda_cudart
    cudaPackages.cuda_cccl
  ]
  ++ lib.optionals optixSupport [
    nvidia-optix
  ]
  ++ lib.optional stdenv.hostPlatform.isLinux [
    libGL
  ];

  cmakeFlags =
    with lib;
    [
      (cmakeBool "PBRT_BUILD_NATIVE_EXECUTABLE" false)
    ]
    ++ optionals cudaSupport [
      (cmakeFeature "CMAKE_CUDA_ARCHITECTURES" "all-major")
    ]
    ++ optionals optixSupport [
      (cmakeFeature "PBRT_OPTIX_PATH" (builtins.toString nvidia-optix))
    ];

  postInstall = ''
    # Clean bundled dep headers, cmake configs, and pkgconfig (keep .a files — pbrt links them)
    rm -rf $out/include/{Ptex*,zlib.h,zconf.h,libdeflate.h,GLFW,double-conversion,utf8proc.h}
    rm -rf $out/lib/cmake/{Ptex,libdeflate,double-conversion,utf8proc,glfw3,deflate,zlib,ZLIB}
    rm -rf $out/lib/pkgconfig
    rm -rf $out/share
    rm -f $out/bin/{ptxinfo,libdeflate-gzip}

    # Install pbrt headers
    (cd $src/src && find pbrt -name '*.h' -exec install -Dm644 {} $out/include/{} \;)

    # Install generated headers from the build tree
    find . -name 'pbrt_soa.h' -exec install -Dm644 {} $out/include/pbrt/pbrt_soa.h \;
    find . -name 'wavefront_workitems_soa.h' -exec install -Dm644 {} $out/include/pbrt/wavefront_workitems_soa.h \;

    # Install ext headers referenced by pbrt's public API
    cp -r $src/src/ext/openvdb/nanovdb $out/include/
    cp -r $src/src/ext/stb $out/include/
    cp -r $src/src/ext/filesystem $out/include/

    # Create cmake config for consumers
    mkdir -p $out/lib/cmake/pbrt
    cat > $out/lib/cmake/pbrt/pbrt-config.cmake << 'CMEOF'
    include(CMakeFindDependencyMacro)
    find_dependency(Threads)
    find_dependency(ZLIB)
    find_dependency(OpenEXR)

    set(_pbrt_prefix "''${CMAKE_CURRENT_LIST_DIR}/../../..")

    if(NOT TARGET pbrt::pbrt_lib)
      add_library(pbrt::pbrt_lib STATIC IMPORTED)
      set_target_properties(pbrt::pbrt_lib PROPERTIES
        IMPORTED_LOCATION "''${_pbrt_prefix}/lib/libpbrt_lib.a"
        INTERFACE_INCLUDE_DIRECTORIES "''${_pbrt_prefix}/include"
        INTERFACE_LINK_LIBRARIES
          "Threads::Threads;ZLIB::ZLIB;OpenEXR::OpenEXR;''${_pbrt_prefix}/lib/libPtex.a;''${_pbrt_prefix}/lib/libdeflate.a;''${_pbrt_prefix}/lib/libdouble-conversion.a;''${_pbrt_prefix}/lib/libutf8proc.a;''${_pbrt_prefix}/lib/libglfw3.a"
      )
    endif()

    unset(_pbrt_prefix)
    CMEOF
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--flake"
      "--version=branch"
    ];
  };

  meta = with lib; {
    description = "Physically Based Rendering Toolkit v4";
    homepage = "https://github.com/mmp/pbrt-v4";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
})
