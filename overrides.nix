self: pkgs:
{
  embree = pkgs.embree.overrideAttrs (old: {
    cmakeFlags = old.cmakeFlags ++ [
      "-DEMBREE_ISPC_SUPPORT=ON"
    ];
  });

  openvdb =
    let
      patch = pkgs.fetchpatch {
        url = "https://github.com/AcademySoftwareFoundation/openvdb/commit/930c3acb8e0c7c2f1373f3a70dc197f5d04dfe74.diff";
        hash = "sha256-EjwSw1GZ6WgTlA4GNzOfaB/9jOGJkGBQ/5V6lOEoji8=";
      };
    in
    pkgs.openvdb.overrideAttrs (old: {
      patches = [ patch ] ++ pkgs.lib.optionals (old ? "patches") old.patches;
    });
}
# Handle CUDA CMake implicit directory fix.
// (
  let
    overrideWithSetupHook =
      cudaPackages:
      cudaPackages.overrideScope (
        self: super:
        let
          cc = super.backendStdenv.cc;
          update-what = if super ? "cuda_nvcc" then "cuda_nvcc" else "cudatoolkit";
          setupHook = pkgs.makeSetupHook {
            name = "cmake-filter-implicit-paths-hook";
            substitutions = {
              # Will be used to compute exclusion path.
              ccFullPath = "${cc}/bin/${cc.targetPrefix}c++";
            };
          } ./hooks/cuda-filter-cmake-implicit-paths-hook.sh;
        in
        {
          ${update-what} = super.${update-what}.overrideAttrs (old: {
            propagatedBuildInputs =
              (if old ? "propagatedBuildInputs" then old.propagatedBuildInputs else [ ])
              ++ [ setupHook ];
          });
        }
      );

    allCudaPackagesNames = builtins.filter (x: pkgs.lib.strings.hasPrefix "cudaPackages" x) (
      builtins.attrNames pkgs
    );
  in
  builtins.foldl' (
    acc: elem:
    {
      ${elem} = overrideWithSetupHook pkgs.${elem};
    }
    // acc
  ) { } allCudaPackagesNames
)
// {
}
