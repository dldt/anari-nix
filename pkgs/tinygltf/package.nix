{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  nix-update-script,
}:
stdenv.mkDerivation rec {
  pname = "tinygltf";
  version = "3.1.0";

  src = fetchFromGitHub {
    owner = "syoyo";
    repo = "tinygltf";
    rev = "v${version}";
    hash = "sha256-zuFQob+N5Zk0/ZHZJA6nUAh45zaBR8g9dlrxwoOL26Q=";
  };

  nativeBuildInputs = [ cmake ];
  # Since v3, upstream installs a C11 API rather than the legacy C++ headers.
  doCheck = true;

  passthru.updateScript = nix-update-script { extraArgs = [ "--flake" ]; };

  meta = with lib; {
    description = "C11 glTF loader and serializer";
    homepage = "https://github.com/syoyo/tinygltf";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
