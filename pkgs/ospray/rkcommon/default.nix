{
  cmake,
  fetchFromGitHub,
  lib,
  stdenv,
  tbb,
}:
stdenv.mkDerivation rec {
  pname = "rkcommon";
  # OSPRay v3.2.0 requires this exact version.
  version = "1.14.0";

  src = fetchFromGitHub {
    owner = "RenderKit";
    repo = "rkcommon";
    rev = "v${version}";
    hash = "sha256-nUtoPImNM84XJmVvulEXaSsbiH2sfDEJwm2FkSR1Q94=";
  };

  prePatch = ''
    substituteInPlace cmake/FindTBB.cmake --replace-fail \
      'set(TBB_ROOT "''${TBB_ROOT}" CACHE PATH "The root path of TBB.")' \
      'set(TBB_ROOT "${tbb}" CACHE PATH "The root path of TBB.")''\nset(TBB_INCLUDE_DIR "${lib.getDev tbb}/include" CACHE PATH "The include directories of TBB.")'
  '';

  nativeBuildInputs = [
    cmake
  ];

  # rkcommon's public headers and CMake config (find_dependency(TBB)) expose
  # TBB, so it must propagate to consumers (ospray, anari-ospray). propagated
  # inputs also land in rkcommon's own rpath. transitiveBuildInputs is not a
  # real mkDerivation attribute and was silently ignored.
  propagatedBuildInputs = [
    tbb
  ];

  cmakeFlags = [
    (lib.cmakeFeature "TBB_DIR" "${tbb}")
  ];

  meta = with lib; {
    description = "A common set of C++ infrastructure and CMake utilities used by various components of Intel Rendering Toolkit.";
    homepage = "https://github.com/RenderKit/rkcommon";
    license = licenses.apsl20;
    platforms = platforms.unix;
  };
}
