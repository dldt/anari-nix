{
  lib,
  fetchFromGitHub,
  cmake,
  stdenv,
  python3,
  swig,
  boost,
  openimageio,
  openexr,
  targetPackages,
  windows,
  netbsd,
  pkgs,
  # Python bindings support
  enablePythonBindings ? true,
}:
let
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
  pkgsLlvmOverlay = pkgs.appendOverlays [ (_self: _super: { inherit llvmPackages_12; }) ];
  llvmPackagesSet = lib.recurseIntoAttrs (
    pkgsLlvmOverlay.callPackages ./llvm { inherit preLibcCrossHeaders; }
  );
  llvmPackages_12 = llvmPackagesSet."12";
in
stdenv.mkDerivation rec {
  version = "2025";
  pname = "mdl-sdk";

  outputs = [ "out" ] ++ lib.optionals enablePythonBindings [ "python" ];

  src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "MDL-SDK";
    rev = "2025";
    hash = "sha256-8w/iMtBVHnLdvlGmASQOHZYsNong+SjHvhuTmxjhsoM=";
  };

  patches = [
    ./skip-xlib-workaround-test.patch
  ];

  hardeningDisable = [ "zerocallusedregs" ];

  nativeBuildInputs = [
    cmake
    python3
  ]
  ++ lib.optionals enablePythonBindings [
    swig
    python3.pkgs.setuptools
    python3.pkgs.wheel
  ];

  buildInputs = [
    boost
    llvmPackages_12.libllvm
    llvmPackages_12.libclang
    openimageio
    openexr
    python3
  ]
  ++ lib.optionals enablePythonBindings [
    python3.pkgs.numpy
  ];

  cmakeFlags =
    with lib;
    [
      (cmakeBool "MDL_BUILD_CORE_EXAMPLES" false)
      (cmakeBool "MDL_BUILD_DOCUMENTATION" false)
      (cmakeBool "MDL_BUILD_SDK_EXAMPLES" false)
      (cmakeBool "MDL_ENABLE_CUDA_EXAMPLES" false)
      (cmakeBool "MDL_ENABLE_OPENGL_EXAMPLES" false)
      (cmakeBool "MDL_ENABLE_PYTHON_BINDINGS" enablePythonBindings)
      (cmakeBool "MDL_ENABLE_QT_EXAMPLES" false)
      (cmakeBool "MDL_ENABLE_SLANG" false)
      (cmakeBool "MDL_ENABLE_UNIT_TESTS" true)
      (cmakeBool "MDL_ENABLE_VULKAN_EXAMPLES" false)
      (cmakeFeature "python_PATH" "${python3}/bin/python")
    ]
    ++ lib.optionals enablePythonBindings [
      (cmakeFeature "PYTHON_DIR" "${python3}")
      (cmakeFeature "swig_PATH" "${swig}/bin/swig")
    ];

  # Handle Python bindings installation
  postInstall = lib.optionalString enablePythonBindings ''
        # Move Python bindings to the python output
        mkdir -p $python/${python3.sitePackages}/mdl_sdk
        if [ -d $out/lib/python ]; then
          # Move the Python files to the mdl_sdk package
          mv $out/lib/python/*.py $python/${python3.sitePackages}/mdl_sdk/
          mv $out/lib/python/*.so $python/${python3.sitePackages}/mdl_sdk/
          
          # Keep the source files in a separate location for reference
          if [ -d $out/lib/python/src ]; then
            mkdir -p $python/share/mdl-sdk/python-src
            mv $out/lib/python/src/* $python/share/mdl-sdk/python-src/
          fi
          
          # Clean up the empty directory
          rm -rf $out/lib/python
        fi
        
        # Create the __init__.py file
        cat > $python/${python3.sitePackages}/mdl_sdk/__init__.py << 'EOF'
    """
    NVIDIA MDL SDK Python Bindings

    This package provides Python bindings for the NVIDIA Material Definition Language (MDL) SDK.
    """

    # Import the low-level bindings
    from . import pymdlsdk

    # Import the high-level wrapper if available
    try:
        from . import pymdl
    except ImportError:
        # pymdl is optional, continue without it
        pass

    __version__ = "${version}"
    EOF
  '';

  meta = with lib; {
    description =
      "NVIDIA Material Definition Language (MDL) SDK"
      + lib.optionalString enablePythonBindings " with Python bindings";
    homepage = "https://developer.nvidia.com/rendering-technologies/mdl-sdk";
    license = licenses.bsd3;
    platforms = platforms.unix;
    maintainers = [
      # add your maintainer name here
    ];
    broken = stdenv.hostPlatform.system == "aarch64-darwin";
  };
}
