{
  lib,
  fetchFromGitHub,
  cmake,
  stdenv,
  python3,
  boost,
  openimageio,
  openexr,
  targetPackages,
  windows,
  netbsd,
  pkgs,
}:
let
  version = "2025";

  # Some LLVM 12 rip off from nixpkgs 25.05
  # These are used when buiding compiler-rt / libgcc, prior to building libc.
  preLibcCrossHeaders =
    let
      inherit (stdenv.targetPlatform) libc;
    in
    if stdenv.targetPlatform.isMinGW then
      targetPackages.windows.mingw_w64_headers or windows.mingw_w64_headers
    else if libc == "nblibc" then
      targetPackages.netbsd.headers or netbsd.headers
    else
      null;
  pkgsLlvmOverlay = pkgs.appendOverlays [ (self: super: { inherit llvmPackages_12; }) ];
  llvmPackagesSet = lib.recurseIntoAttrs (
    pkgsLlvmOverlay.callPackages ./llvm { inherit preLibcCrossHeaders; }
  );
  llvmPackages_12 = llvmPackagesSet."12";
in
stdenv.mkDerivation {
  inherit version;
  pname = "mdl-sdk";

  src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "MDL-SDK";
    rev = version;
    hash = "sha256-8w/iMtBVHnLdvlGmASQOHZYsNong+SjHvhuTmxjhsoM=";
  };

  patches = [
    ./skip-xlib-workaround-test.patch
  ];

  hardeningDisable = [ "zerocallusedregs" ];

  nativeBuildInputs = [
    cmake
    python3
  ];

  buildInputs = [
    boost
    llvmPackages_12.libllvm
    llvmPackages_12.libclang
    openimageio
    openexr
    python3
  ];

  cmakeFlags = with lib; [
    (cmakeBool "MDL_BUILD_CORE_EXAMPLES" false)
    (cmakeBool "MDL_BUILD_DOCUMENTATION" false)
    (cmakeBool "MDL_BUILD_SDK_EXAMPLES" false)
    (cmakeBool "MDL_ENABLE_CUDA_EXAMPLES" false)
    (cmakeBool "MDL_ENABLE_OPENGL_EXAMPLES" false)
    (cmakeBool "MDL_ENABLE_QT_EXAMPLES" false)
    (cmakeBool "MDL_ENABLE_SLANG" false)
    (cmakeBool "MDL_ENABLE_UNIT_TESTS" true)
    (cmakeBool "MDL_ENABLE_VULKAN_EXAMPLES" false)
    (cmakeFeature "python_PATH" "${python3}/bin/python")
  ];

  meta = with lib; {
    description = ".";
    homepage = "https://developer.nvidia.com/rendering-technologies/mdl-sdk";
    license = licenses.bsd3;
    platforms = platforms.unix;
  };
}
