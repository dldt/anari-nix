{
  cmake,
  fetchFromGitHub,
  lib,
  nix-update-script,
  python3,
  stdenv,
}:
let
  pythonEnv = python3.withPackages (ps: [
    ps.pillow
    ps.reportlab
    ps.scikit-image
    ps.tabulate
  ]);
in
stdenv.mkDerivation {
  pname = "anari-cts";
  version = "0.15.0-unstable-2026-07-01";

  src = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "ANARI-SDK";
    rev = "9de01a490d99dec836c0bbebaf2872430631a25f";
    hash = "sha256-ej8GJwBYHtufggQx6UxQcAz2hkn4Lllp8Pnf63QNQi0=";
  };

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
  # everything except the CTS artifacts (the anariCts binary, the
  # reporting scripts) and the SDK libraries the binary links against
  # at runtime.
  postInstall = ''
    rm -rf "$out/include" "$out/share/anari/code_gen" \
           "$out/share/anari/anari_viewer" \
           "$out/lib/cmake"
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
