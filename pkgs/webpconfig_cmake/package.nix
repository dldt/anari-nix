{
  lib,
  pkgs,
  stdenvNoCC,
  libwebp,
}:
let
  webpconfig = ./WebPConfig.cmake;
  webptargets = ./WebPTargets.cmake;
  webptargets-release = ./WebPTargets-release.cmake;
  suffix = if pkgs.stdenv.isDarwin then "dylib" else "so";
in
stdenvNoCC.mkDerivation {

  pname = "webpconfig_cmake";
  version = "0.0.1";

  srcs = [
    webpconfig
    webptargets
    webptargets-release
  ];

  dontUnpack = true;

  buildInputs = [ libwebp ];

  buildCommand = ''
    mkdir -p "$out/lib/cmake/webp/"
    substitute ${webpconfig} "$out/lib/cmake/webp/WebPConfig.cmake" --replace-fail "@LIBWEBP_IMPORT_PREFIX@" "${libwebp}"
    substitute ${webptargets} "$out/lib/cmake/webp/WebPTargets.cmake" --replace-fail "@LIBWEBP_IMPORT_PREFIX@" "${libwebp}"

    cp "${webptargets-release}" "$out/lib/cmake/webp/WebPTargets-release.cmake"
    for lib in "sharpyuv" "webpdecoder" "webp" "webpdemux" "webpmux"
    do
      libs=(${libwebp}/lib/lib$lib.*${suffix}*)
      libs=($(printf '%s\n' "''${libs[@]}"|awk '{print length, $0}'|sort -r -n|cut -d " " -f2-))
      if test ''${#libs[@]} -lt 2; then
        echo Cannot file libraries for $lib 1>&2
        exit 1
      fi
      LIB="$(echo "$lib" | tr a-z A-Z)"

      substituteInPlace "$out/lib/cmake/webp/WebPTargets-release.cmake" \
          --replace-fail "@''${LIB}_IMPORTED_LOCATION_RELEASE@" "$(basename "''${libs[0]}")" \
          --replace-fail "@''${LIB}_IMPORTED_SONAME_RELEASE@" "$(basename "''${libs[1]}")"
    done
  '';

  meta = with lib; {
    description = "Expose a WebPConfig.cmake module.";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
