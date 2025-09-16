{
  lib,
  fetchFromGitHub,
  cmake,
  stdenv,
  llvmPackages,
  python3,
  boost,
  openimageio,
  openexr,
}:
let
  version = "2024.1.4";
in
stdenv.mkDerivation {
  inherit version;
  pname = "mdl-sdk";

  src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "MDL-SDK";
    rev = version;
    hash = "sha256-QA5z8CjFWzTPBkC2XD6D/wt8ShYYrY6EcTC1HVavzrw=";
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
    llvmPackages.libllvm
    llvmPackages.libclang
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
