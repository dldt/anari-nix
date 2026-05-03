{
  cmake,
  fetchFromGitHub,
  fetchurl,
  lib,
  nix-update-script,
  python3,
  stdenv,
}:
let
  anari_cts_pybind11 = fetchurl {
    url = "https://github.com/pybind/pybind11/archive/refs/tags/v2.13.6.zip";
    hash = "sha256-0KEW6R9kpKLY+3WQw0JC35IlimHsZEt5EnlR6CG0e+Y=";
  };
  pythonEnv = python3.withPackages (ps: [
    ps.pillow
    ps.reportlab
    ps.scikit-image
    ps.tabulate
  ]);
in
stdenv.mkDerivation {
  pname = "anari-cts";
  version = "0.15.0-unstable-2026-04-30";

  src = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "ANARI-SDK";
    rev = "79ebccb995382d34b0b01612344880f75958366b";
    hash = "sha256-D6GPf5ftRVpTqI7Mnt7oEnoynBCsJMVhRG8HHayCNjw=";
  };

  postUnpack = ''
    mkdir -p "''${sourceRoot}/.anari_deps/anari_cts_pybind11/"
    cp "${anari_cts_pybind11}" "''${sourceRoot}/.anari_deps/anari_cts_pybind11/v2.13.6.zip"
  '';

  nativeBuildInputs = [
    cmake
    pythonEnv
  ];

  buildInputs = [
    pythonEnv
  ];

  cmakeFlags = with lib; [
    (cmakeBool "BUILD_CTS" true)
    (cmakeBool "BUILD_EXAMPLES" false)
    (cmakeBool "BUILD_HELIDE_DEVICE" false)
    (cmakeBool "BUILD_TESTING" false)
    (cmakeBool "BUILD_VIEWER" false)
    (cmakeBool "CTS_ENABLE_GLTF" false)
    (cmakeBool "FETCHCONTENT_FULLY_DISCONNECTED" true)
    (cmakeBool "INSTALL_CTS" true)
  ];

  # The in-tree build installs the full SDK alongside the CTS. Strip
  # everything except the CTS artifacts and the SDK libraries that the
  # pybind11 module links against at runtime.
  postInstall = ''
    rm -rf "$out/include" "$out/share/anari/code_gen" \
           "$out/share/anari/anari_viewer" \
           "$out/lib/cmake" "$out/bin"
  '';

  # Patch the CTS Python scripts to find the pybind11 module and use the
  # correct Python interpreter.
  postFixup = ''
    for f in "$out/share/anari/cts"/*.py; do
      if head -1 "$f" | grep -q '^#!/'; then
        substituteInPlace "$f" \
          --replace-quiet '#!/usr/bin/env python' "#!${pythonEnv}/bin/python"
      fi
    done
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--flake"
      "--version=branch"
    ];
  };

  meta = with lib; {
    description = "Conformance Test Suite for ANARI renderers.";
    homepage = "https://www.khronos.org/anari/";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}
