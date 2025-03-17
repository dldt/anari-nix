self: pkgs:
let
  inherit (pkgs) callPackage;
in
{
  anari-ospray = callPackage ./anari-ospray {
    inherit (self)
      anari-sdk
      openvkl
      ospray
      rkcommon_0_14_0
      ;
  };
  anari-sdk = callPackage ./anari-sdk { inherit (self) webpconfig_cmake tinygltf; };
  anari-visionaray = callPackage ./anari-visionaray { inherit (self) anari-sdk visionaray; };
  cgns = callPackage ./cgns { };
  conduit = callPackage ./conduit { };
  pycgns = callPackage ./pycgns { };
  hdanari = callPackage ./hdanari { inherit (self) anari-sdk; };
  nanovdb-tools = callPackage ./nanovdb-tools { };
  nixglenv = callPackage ./nixglenv { };
  nvidia-mdl = callPackage ./nvidia-mdl { };
  nvidia-nrd = callPackage ./nvidia-nrd { };
  openvdb-tools = callPackage ./openvdb-tools { };
  openvkl = callPackage ./openvkl { inherit (self) rkcommon_0_14_0; };
  ospray = callPackage ./ospray { inherit (self) openvkl rkcommon_0_14_0; };
  rkcommon_0_14_0 = callPackage ./rkcommon_0_14_0 { };
  tinygltf = callPackage ./tinygltf { };
  tsd = callPackage ./tsd { inherit (self) anari-sdk conduit; };
  visgl = callPackage ./visgl { inherit (self) anari-sdk; };
  visionaray = callPackage ./visionaray { };
  webpconfig_cmake = callPackage ./webpconfig_cmake { };
}
