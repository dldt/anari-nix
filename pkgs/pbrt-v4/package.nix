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

    # Strip interactive GUI and its OpenGL/GLFW/GLAD dependencies (not needed for the render driver)
    sed -i '/find_package(OpenGL REQUIRED)/d' CMakeLists.txt
    sed -i '/^  glfw$/d; /^  glad$/d; s/  OpenGL::GL)/  )/' CMakeLists.txt

    # Provide stub GL headers so gui.h can be parsed without GLFW/GLAD
    mkdir -p src/ext/stub/{glad,GLFW}
    echo 'typedef void* GLADloadproc;' > src/ext/stub/glad/glad.h
    echo 'typedef struct GLFWwindow GLFWwindow;' > src/ext/stub/GLFW/glfw3.h

    # Provide stub GUI implementation (no-op without display)
    cat > src/pbrt/util/gui.cpp << 'GUISTUB'
    #include <pbrt/util/gui.h>
    namespace pbrt {
    void GUI::Initialize() {}
    Point2i GUI::GetResolution() { return {0, 0}; }
    GUI::GUI(std::string, Vector2i, Bounds3f) {}
    GUI::~GUI() {}
    DisplayState GUI::RefreshDisplay() { return DisplayState::NONE; }
    }
    GUISTUB

    # Stub CUDA-GL interop header (gui.h includes it under PBRT_BUILD_GPU_RENDERER)
    cat > src/pbrt/gpu/cudagl.h << 'CUDAGLSTUB'
    #pragma once
    #include <pbrt/util/color.h>
    namespace pbrt {
    template <typename T> class CUDAOutputBuffer {
    public:
      CUDAOutputBuffer(int32_t, int32_t) {}
      ~CUDAOutputBuffer() {}
      T *Map() { return nullptr; }
      void Unmap() {}
      void Draw(int, int) {}
      void StartAsynchronousReadback() {}
      const T *GetReadbackPixels() { return nullptr; }
    };
    }
    CUDAGLSTUB

    # Replace GLFW/GLAD subdirectory builds with stub include paths
    sed -i '/glfw\|glad/d' src/ext/CMakeLists.txt
    echo 'set(GLFW_INCLUDE ''${CMAKE_CURRENT_SOURCE_DIR}/stub PARENT_SCOPE)' >> src/ext/CMakeLists.txt
    echo 'set(GLAD_INCLUDE ''${CMAKE_CURRENT_SOURCE_DIR}/stub PARENT_SCOPE)' >> src/ext/CMakeLists.txt

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
  ];

  cmakeFlags =
    with lib;
    [
      (cmakeBool "PBRT_BUILD_NATIVE_EXECUTABLE" false)
    ]
    ++ optionals cudaSupport [
      # pbrt manages CUDA arch via --gpu-architecture in CMAKE_CUDA_FLAGS;
      # set this to skip checkcuda auto-detection (needs a real GPU, impossible in sandbox)
      (cmakeFeature "PBRT_GPU_SHADER_MODEL" "sm_89")
      (cmakeFeature "CMAKE_PREFIX_PATH" (cudaPackages.cuda_cudart + "/lib/stubs"))
    ]
    ++ optionals optixSupport [
      (cmakeFeature "PBRT_OPTIX_PATH" (builtins.toString nvidia-optix))
    ];

  # nvcc 12.8 generates .cudafe1.stub.c referencing cuda::std device variables
  # without including CCCL headers; force-include them via the host compiler
  preConfigure = lib.optionalString cudaSupport ''
    export CUDAFLAGS="$CUDAFLAGS -Xcompiler -include,cuda/std/__utility/piecewise_construct.h -Xcompiler -include,cuda/std/__concepts/swappable.h -Xcompiler -include,cuda/std/__iterator/iter_move.h"
  '';

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
          "Threads::Threads;ZLIB::ZLIB;OpenEXR::OpenEXR;''${_pbrt_prefix}/lib/libPtex.a;''${_pbrt_prefix}/lib/libdeflate.a;''${_pbrt_prefix}/lib/libdouble-conversion.a;''${_pbrt_prefix}/lib/libutf8proc.a"
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
