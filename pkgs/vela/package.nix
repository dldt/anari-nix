{
  lib,
  stdenv,
  fetchurl,
  fetchFromGitHub,
  config,
  cudaSupport ? config.cudaSupport,
  mpiSupport ? false,
  mpi,
  openimageio,
  cmake,
  anari-sdk,
  libGL,
  lua54Packages,
  pkg-config,
  assimp,
  boost,
  cudaPackages,
  glm,
  hdf5,
  libjpeg_turbo,
  opensubdiv,
  tbb,
  silo,
  sdl3,
  sol2,
  openusd,
  libx11,
  libxt,
  vtk,
  zlib,
  python3,
  nix-update-script,
  materialx,
}:
let
  imgui-src = fetchurl {
    url = "https://github.com/ocornut/imgui/archive/refs/tags/v1.92.9b-docking.zip";
    hash = "sha256-BDREUVeldfRS/w8tFoH92Q6ok54MaYPm+OR8UfuhvM0=";
  };
  imguizmo-src = fetchurl {
    url = "https://github.com/CedricGuillemet/ImGuizmo/archive/105e4fde45e4e74aae8973d98750820ef7aca7e2.zip";
    hash = "sha256-dU/KToxmxaJV+VMjm1GBOFIokj9kbRo5vcpboYrMfP0=";
  };
  miniscene-src = fetchurl {
    url = "https://github.com/ingowald/miniScene/archive/4eee09bd95d91b8b9e29eeecb1df6053cce84590.zip";
    hash = "sha256-3yExfhETmMNgNcmnPVwsYcfmoNrMav0JxcCVc8BKn/4=";
  };
  # Vela only needs OpenUSD library support. Nixpkgs' top-level openusd
  # enables USDView/tools, which pulls PyQt6 -> QtWebEngine and breaks on
  # aarch64-darwin.
  openusdCore = openusd.override {
    withUsdView = false;
    withTools = false;
  };
in
stdenv.mkDerivation {
  pname = "vela";
  version = "0-unstable-2026-10-20";

  src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "Vela";
    rev = "5f7e6d39017e26f35d9fde0ba6f8b92038cfe661";
    hash = "sha256-vVJ+7KLbkstRvoFUeg+PH3+2BwN9lEiWLCFowbaf8FQ=";
  };

  # anari_sdk_fetch_project() downloads into `.anari_deps/<name>` under the
  # source root; seeding it there keeps the build offline.
  postUnpack = ''
    mkdir -p "''${sourceRoot}/.anari_deps/vela_ext_imgui_sdl/"
    cp "${imgui-src}" "''${sourceRoot}/.anari_deps/vela_ext_imgui_sdl/v1.92.9b-docking.zip"
    mkdir -p "''${sourceRoot}/.anari_deps/vela_ext_imguizmo/"
    cp "${imguizmo-src}" "''${sourceRoot}/.anari_deps/vela_ext_imguizmo/105e4fde45e4e74aae8973d98750820ef7aca7e2.zip"
    mkdir -p "''${sourceRoot}/.anari_deps/vela_ext_miniscene/"
    cp "${miniscene-src}" "''${sourceRoot}/.anari_deps/vela_ext_miniscene/4eee09bd95d91b8b9e29eeecb1df6053cce84590.zip"
  '';

  patches = [
    ./0001-fix-io-build-against-OpenUSD-25.05.patch
    # Shared with anari-vsr, which references it from here.
    ./0002-fetch-imnodes-only-for-viskores-demo.patch
    ./0003-make-the-anari-device-library-optional.patch
    # -usd_mdl / USD_MDL, the MDL counterpart of upstream's -usd_mtlx.
    ./0004-add-usd_mdl-importer-type.patch
  ];

  cmakeFlags = [
    (lib.cmakeBool "BUILD_TESTING" false)
    # The device is anari-vsr's to ship; building it here would have both
    # packages carry the same library.
    (lib.cmakeBool "VSR_BUILD_ANARI_DEVICE" false)
    (lib.cmakeBool "VSR_USE_CUDA" cudaSupport)
    (lib.cmakeBool "VSR_USE_ASSIMP" true)
    (lib.cmakeBool "VSR_USE_HDF5" true)
    (lib.cmakeBool "VSR_USE_LUA" true)
    # .mini import/export, the format haystack consumes.
    (lib.cmakeBool "VSR_USE_MINISCENE" true)
    (lib.cmakeBool "VSR_USE_MPI" mpiSupport)
    # Texture formats stb cannot decode (e.g. TIFF), needed by USD/MaterialX assets.
    (lib.cmakeBool "VSR_USE_OIIO" true)
    (lib.cmakeBool "VSR_USE_NETWORKING" true)
    (lib.cmakeBool "VSR_USE_SDL3" true)
    (lib.cmakeBool "VSR_USE_TURBOJPEG" true)
    (lib.cmakeBool "VSR_USE_SILO" true)
    (lib.cmakeBool "VSR_USE_TBB" true)
    (lib.cmakeBool "VSR_USE_USD" true)
    (lib.cmakeBool "VSR_USE_VTK" true)
  ];

  # Only the USD file format plugin has an install rule; every application is
  # left in CMAKE_RUNTIME_OUTPUT_DIRECTORY, which the top-level CMakeLists sets
  # to the build root. Install whatever landed there rather than naming apps
  # one by one -- a hardcoded list silently drops anything upstream adds, which
  # is how vsrConvert went missing.
  postInstall = ''
    mkdir -p "''${out}/bin"
    installed=()
    for app in ./*; do
      [ -f "''${app}" ] || continue
      [ -x "''${app}" ] || continue
      case "''${app}" in
        *.so | *.so.* | *.a | *.dylib | *.cmake) continue ;;
      esac
      cp "''${app}" "''${out}/bin/"
      installed+=("$(basename "''${app}")")
    done

    echo "vela: installed ''${#installed[@]} applications: ''${installed[*]}"

    # Guard against the glob silently matching nothing useful if upstream
    # changes the output layout. The CUDA demos only exist when VSR_USE_CUDA
    # is on, so they are only required then.
    expected=(
      scivisStudio
      scivisStudioClient
      scivisStudioServer
      vsrConvert
      vsrPrint
      vsrRemoteViewer
      vsrServer
      vsrViewer
    )
    ${lib.optionalString cudaSupport ''
      expected+=(vsrDemoAnimatedParticles vsrDemoAnimatedVolume)
    ''}
    ${lib.optionalString mpiSupport ''
      expected+=(vsrMPIViewer vsrMPIServer)
    ''}
    for app in "''${expected[@]}"; do
      if [ ! -x "''${out}/bin/''${app}" ]; then
        echo "vela: expected application ''${app} was not installed" >&2
        exit 1
      fi
    done
  '';

  nativeBuildInputs = [
    cmake
    pkg-config
    python3
  ]
  ++ lib.optionals cudaSupport [
    cudaPackages.cuda_nvcc
  ];

  buildInputs = [
    anari-sdk
    assimp
    # vsr_network is boost.asio, which VSR_USE_NETWORKING turns on; turbojpeg
    # encodes SciVis Studio's remote frames.
    boost
    libjpeg_turbo
    sdl3
    glm
    libGL
    lua54Packages.lua
    hdf5
    materialx
    openimageio
    opensubdiv
    openusdCore
    silo
    sol2
    tbb
    vtk
    zlib
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    libx11
    libxt
  ]
  ++ lib.optionals mpiSupport [ mpi ]
  ++ lib.optionals cudaSupport [
    cudaPackages.cuda_cudart
    cudaPackages.cuda_cccl
  ];

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version=branch"
      "--flake"
    ];
  };

  meta = with lib; {
    description = "Scene graph library and applications pairing a live, editable scene description with ANARI devices";
    homepage = "https://github.com/NVIDIA/Vela";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}
