{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  nlohmann_json,
  stb,
}:
let
  version = "v2.9.6";
in
stdenv.mkDerivation {
  pname = "tinygltf";
  inherit version;

  src = fetchFromGitHub {
    owner = "syoyo";
    repo = "tinygltf";
    rev = version;
    hash = "sha256-3dBxfdXeTbzeQAXaBXFaflLgXYeuOfESdq6V3+0iCXY=";
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

  meta = with lib; {
    description = "TinyGLTF is a header only C++11 glTF 2.0 https://github.com/KhronosGroup/glTF library.";
    homepage = "https://github.com/syoyo/tinygltf";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
