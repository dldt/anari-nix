{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  config,
  cudaSupport ? config.cudaSupport,
  optixSupport ? cudaSupport && stdenv.hostPlatform.isx86_64,
  # pbrt-v4 trips a chain of nvcc/CCCL 12.8 bugs (cudafe1.stub.c host-stub
  # gen, __host__ macroization order, cuda_bf16 device intrinsics in
  # non-arch-guarded paths) that are absent in 12.9+. Pin to cudaPackages_12_9
  # rather than keeping the flake-default cudaPackages so we can drop the
  # workarounds. Other packages in the flake (barney, visionaray) keep the
  # default cudaPackages — there's a second CUDA closure on disk in exchange.
  cudaPackages_12_9,
  autoAddDriverRunpath,
  nvidia-optix,
  zlib,
  openexr,
  nix-update-script,
}:
let
  cudaPackages = cudaPackages_12_9;
in
stdenv.mkDerivation (_finalAttrs: {
  pname = "pbrt-v4";
  version = "0-unstable-2026-05-14";

  src = fetchFromGitHub {
    owner = "mmp";
    repo = "pbrt-v4";
    rev = "64ba33e48851576c945b7837f759df49d6d22f27";
    hash = "sha256-6BqUPgIXc1OYfupx4As9bsS9jdS+4eOZu39Bpngq30U=";
    fetchSubmodules = true;
  };

  # All embedded multi-line strings (substituteInPlace patterns, heredoc bodies,
  # heredoc terminators) keep at least 4 leading spaces in the Nix source so that
  # Nix's indented-string min-indent stripping uniformly removes 4 spaces and the
  # bash heredoc terminators land at column 0.
  postPatch = ''
    # Disable git submodule hash validation (no .git in Nix builds).
    # Upstream uses `function (CHECK_EXT ...)` with a space — --replace-fail catches a rename.
    substituteInPlace CMakeLists.txt --replace-fail \
        'function (CHECK_EXT NAME DIR HASH)' \
        'function (CHECK_EXT NAME DIR HASH)
      return()'

    # Strip GUI: no display server, no GLFW/GLAD, no OpenGL.
    substituteInPlace CMakeLists.txt --replace-fail \
        'find_package(OpenGL REQUIRED)' ""
    # gui.h gets installed for consumers; replace its GL/GLFW includes with forward
    # declarations so it can be transitively included without a GL toolchain.
    # gui.h only references GLFWwindow* as an opaque pointer and GLADloadproc as a
    # callback type — opaque-struct + typedef is sufficient.
    substituteInPlace src/pbrt/util/gui.h --replace-fail \
        '#include <glad/glad.h>' 'typedef void *GLADloadproc;'
    substituteInPlace src/pbrt/util/gui.h --replace-fail \
        '#include <GLFW/glfw3.h>' 'typedef struct GLFWwindow GLFWwindow;'
    substituteInPlace CMakeLists.txt --replace-fail \
        '  glfw
      glad
      OpenGL::GL)' \
        '  )'

    # Strip the glfw/glad ext subdirectory section, replace with stub include paths.
    sed -i '/^# glfw \/ glad$/,/^set_property (TARGET glad PROPERTY FOLDER "ext")$/d' src/ext/CMakeLists.txt
    {
      echo 'set (GLFW_INCLUDE ''${CMAKE_CURRENT_SOURCE_DIR}/stub PARENT_SCOPE)'
      echo 'set (GLAD_INCLUDE ''${CMAKE_CURRENT_SOURCE_DIR}/stub PARENT_SCOPE)'
    } >> src/ext/CMakeLists.txt
    grep -q "GLFW_INCLUDE.*stub" src/ext/CMakeLists.txt  # fail loudly if range deletion missed

    # Stub GL headers so gui.h parses without GLFW/GLAD.
    mkdir -p src/ext/stub/{glad,GLFW}
    echo 'typedef void* GLADloadproc;' > src/ext/stub/glad/glad.h
    echo 'typedef struct GLFWwindow GLFWwindow;' > src/ext/stub/GLFW/glfw3.h

    # Stub GUI implementation. Signatures must match src/pbrt/util/gui.h at the pinned
    # src.rev; if upstream changes any GUI:: signature this stub will fail to link, and
    # you'll need to bump src.rev and update these declarations together.
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

    # cudagl.h pulls in <glad/glad.h> + <cuda_gl_interop.h>; the stripped GL toolchain
    # cannot satisfy that even in CUDA builds, so the stub stays unconditional.
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
  ''
  + lib.optionalString cudaSupport ''
    # pbrt's CMakeLists hardcodes a single CUDA arch via `--gpu-architecture=$ARCH`
    # (sm_75 here), which is correct for OptiX PTX compilation (single-arch required
    # by `-ptx`). For SASS-target compiles, emit PTX-only for compute_75 instead of
    # the multi-arch SASS list — a single virtual arch keeps the embedded sample
    # tables (pmj02tables, bluenoise) from being duplicated per gencode and shrinks
    # the static archive by ~hundreds of MB. The driver JITs to the user's GPU on
    # first run and caches under ~/.nv/ComputeCache. The `$<NOT:CUDA_PTX_COMPILATION>`
    # guard keeps this off pbrt's OptiX shader targets, where `-ptx + extra gencode`
    # is a fatal nvcc error. Scoped to cuda_build_configuration so it doesn't leak
    # into check_language(CUDA)'s try-compile.
    substituteInPlace CMakeLists.txt --replace-fail \
        'string (APPEND CMAKE_CUDA_FLAGS " -Xnvlink -suppress-stack-size-warning")' \
        'string (APPEND CMAKE_CUDA_FLAGS " -Xnvlink -suppress-stack-size-warning -Xfatbin=-compress-all")
        target_compile_options (cuda_build_configuration INTERFACE
            "$<$<AND:$<COMPILE_LANGUAGE:CUDA>,$<NOT:$<BOOL:$<TARGET_PROPERTY:CUDA_PTX_COMPILATION>>>>:-gencode=arch=compute_75,code=compute_75>")'
  '';

  nativeBuildInputs = [
    cmake
  ]
  ++ lib.optionals cudaSupport [
    cudaPackages.cuda_nvcc
    autoAddDriverRunpath
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

  cmakeFlags = [
    (lib.cmakeBool "PBRT_BUILD_NATIVE_EXECUTABLE" false)
  ]
  ++ lib.optionals cudaSupport [
    # Skip pbrt's checkcuda probe (needs a real GPU). The arch value here is unused
    # because postPatch swaps `--gpu-architecture=$ARCH` for the full gencode list,
    # but the variable must be non-empty to bypass the probe.
    (lib.cmakeFeature "PBRT_GPU_SHADER_MODEL" "sm_75")
    # pbrt uses the legacy `find_package(CUDA REQUIRED)` module, which expects a
    # monolithic toolkit layout. Point it at cudaPackages.cudatoolkit (merged tree)
    # so CUDA_VERSION_MAJOR/MINOR/PATCH and CUDA_NVCC_EXECUTABLE resolve correctly.
    (lib.cmakeFeature "CUDA_TOOLKIT_ROOT_DIR" "${cudaPackages.cudatoolkit}")
  ]
  ++ lib.optionals optixSupport [
    (lib.cmakeFeature "PBRT_OPTIX_PATH" "${nvidia-optix}")
  ];

  preConfigure = lib.optionalString cudaSupport ''
    # Allow the linker to resolve `-lcuda` against the driver stub at link time;
    # autoAddDriverRunpath then patches RPATH so the loader picks the real driver at runtime.
    export NIX_LDFLAGS="$NIX_LDFLAGS -L${cudaPackages.cuda_cudart}/lib/stubs"
  '';

  postInstall = ''
    # Clean bundled dep headers, cmake configs, and pkgconfig (keep .a files — pbrt links them statically)
    rm -rf $out/include/{Ptex*,zlib.h,zconf.h,libdeflate.h,GLFW,double-conversion,utf8proc.h}
    rm -rf $out/lib/cmake/{Ptex,libdeflate,double-conversion,utf8proc,glfw3,deflate,zlib,ZLIB}
    rm -rf $out/lib/pkgconfig
    rm -rf $out/share
    rm -f $out/bin/{ptxinfo,libdeflate-gzip}

    # Drop standalone utility tools — each statically links libpbrt_lib.a
    # and CUDA fatbins, weighing ~320 MB. This package is consumed as a
    # library (see lib/cmake/pbrt-config); users who want imgtool/plytool/
    # pspec can install upstream pbrt-v4 directly.
    rm -f $out/bin/{imgtool,plytool,pspec}

    # cmake build dir is one level below the (patched) source root.
    pbrtSrc=$(realpath ..)

    # Install pbrt headers from the *patched* source so consumers don't re-import
    # `#include <glad/glad.h>` from gui.h that we've already neutralised.
    (cd "$pbrtSrc/src" && find pbrt -name '*.h' -exec install -Dm644 {} $out/include/{} \;)

    # Generated headers from the build tree
    find . -name 'pbrt_soa.h' -exec install -Dm644 {} $out/include/pbrt/pbrt_soa.h \;
    find . -name 'wavefront_workitems_soa.h' -exec install -Dm644 {} $out/include/pbrt/wavefront_workitems_soa.h \;

    # Ext headers referenced by pbrt's public API
    cp -r "$pbrtSrc/src/ext/openvdb/nanovdb" $out/include/
    cp -r "$pbrtSrc/src/ext/stb" $out/include/
    cp -r "$pbrtSrc/src/ext/filesystem" $out/include/

    # CUDA-built pbrt also produces libpbrt_embedded_ptx_lib.a; install it for downstream linkage.
    find . -name 'libpbrt_embedded_ptx_lib.a' -exec install -Dm644 {} $out/lib/libpbrt_embedded_ptx_lib.a \;

    mkdir -p $out/lib/cmake/pbrt
    cat > $out/lib/cmake/pbrt/pbrt-config.cmake << 'CMEOF'
    include(CMakeFindDependencyMacro)
    find_dependency(Threads)
    find_dependency(ZLIB)
    find_dependency(OpenEXR)

    set(_pbrt_prefix "''${CMAKE_CURRENT_LIST_DIR}/../../..")

    # Presence of the embedded-PTX archive marks a CUDA-enabled build.
    set(_pbrt_with_cuda FALSE)
    if(EXISTS "''${_pbrt_prefix}/lib/libpbrt_embedded_ptx_lib.a")
      set(_pbrt_with_cuda TRUE)
      find_dependency(CUDAToolkit)
    endif()

    if(NOT TARGET pbrt::pbrt_lib)
      add_library(pbrt::pbrt_lib STATIC IMPORTED)
      set_target_properties(pbrt::pbrt_lib PROPERTIES
        IMPORTED_LOCATION "''${_pbrt_prefix}/lib/libpbrt_lib.a"
        INTERFACE_INCLUDE_DIRECTORIES "''${_pbrt_prefix}/include"
      )

      set(_pbrt_link
        "Threads::Threads"
        "ZLIB::ZLIB"
        "OpenEXR::OpenEXR"
        "''${_pbrt_prefix}/lib/libPtex.a"
        "''${_pbrt_prefix}/lib/libdeflate.a"
        "''${_pbrt_prefix}/lib/libdouble-conversion.a"
        "''${_pbrt_prefix}/lib/libutf8proc.a"
      )
      if(_pbrt_with_cuda)
        list(APPEND _pbrt_link
          "''${_pbrt_prefix}/lib/libpbrt_embedded_ptx_lib.a"
          "CUDA::cudart"
          "CUDA::cuda_driver"
        )
        set_property(TARGET pbrt::pbrt_lib APPEND PROPERTY
          INTERFACE_COMPILE_DEFINITIONS "PBRT_BUILD_GPU_RENDERER")
      endif()
      set_property(TARGET pbrt::pbrt_lib PROPERTY INTERFACE_LINK_LIBRARIES "''${_pbrt_link}")
      unset(_pbrt_link)
    endif()

    unset(_pbrt_prefix)
    unset(_pbrt_with_cuda)
    CMEOF
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--flake"
      "--version=branch"
    ];
  };

  meta = {
    description = "Physically Based Rendering Toolkit v4";
    homepage = "https://github.com/mmp/pbrt-v4";
    license = lib.licenses.asl20;
    mainProgram = "pbrt";
    platforms = lib.platforms.unix;
    # pbrt's GPU path requires OptiX (upstream CMakeLists.txt: "Found CUDA but
    # PBRT_OPTIX_PATH is not set. Disabling GPU compilation."). On platforms where
    # OptiX is unavailable, cudaSupport=true silently produces a CPU-only binary
    # while still pulling the full CUDA toolchain into the closure — flag broken.
    broken = cudaSupport && !optixSupport;
  };
})
