{
  lib,
  fetchFromGitHub,
  cmake,
  stdenv,
  llvmPackages_12,
  python3,
  boost,
  openimageio,
  openexr,
}:
let
  version = "2024.0.4";
in
stdenv.mkDerivation {
  inherit version;
  pname = "nvidia-mdl";

  src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "MDL-SDK";
    rev = version;
    hash = "sha256-3RBgfC0ypGXc0+24UfqYbJ/dIxTxnDXMWa8qFApFAI8=";
  };

  patches = [
    ./fix-missing-cstdint.patch
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

  cmakeFlags = [
    "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON"
    "-DMDL_BUILD_CORE_EXAMPLES=OFF"
    "-DMDL_BUILD_DOCUMENTATION=OFF"
    "-DMDL_BUILD_SDK_EXAMPLES=OFF"
    "-DMDL_ENABLE_CUDA_EXAMPLES=OFF"
    "-DMDL_ENABLE_OPENGL_EXAMPLES=OFF"
    "-DMDL_ENABLE_QT_EXAMPLES=OFF"
    "-DMDL_ENABLE_SLANG=OFF" # Have to be on at some point
    "-DMDL_ENABLE_UNIT_TESTS=ON"
    "-DMDL_ENABLE_VULKAN_EXAMPLES=OFF"
    "-Dpython_PATH=${python3}/bin/python"
  ];

  meta = with lib; {
    description = ".";
    homepage = "https://developer.nvidia.com/rendering-technologies/mdl-sdk";
    license = licenses.bsd3;
    platforms = platforms.unix;
  };
}
