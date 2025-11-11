{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  nlohmann_json,
  stb,
  nix-update-script,
}:
stdenv.mkDerivation {
  pname = "tinygltf";
  version = "2.9.7";

  src = fetchFromGitHub {
    owner = "syoyo";
    repo = "tinygltf";
    rev = "81bd50c1062fdb956e878efa2a9234b2b9ec91ec";
    hash = "sha256-tG9hrR2rsfgS8zCBNdcplig2vyiIcNspSVKop03Zx9A=";
  };

  nativeBuildInputs = [ cmake ];
  propagatedBuildInputs = [
    nlohmann_json
    stb
  ];

  postInstall = ''
    rm $out/include/json.hpp
    rm $out/include/stb_image.h
    rm $out/include/stb_image_write.h
  '';

  passthru.updateScript = nix-update-script { extraArgs = [ "--flake" ]; };

  meta = with lib; {
    description = "TinyGLTF is a header only C++11 glTF 2.0 https://github.com/KhronosGroup/glTF library.";
    homepage = "https://github.com/syoyo/tinygltf";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
