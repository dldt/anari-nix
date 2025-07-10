final: prev:
{
  embree = prev.embree.overrideAttrs (old: {
    cmakeFlags = old.cmakeFlags ++ [
      "-DEMBREE_ISPC_SUPPORT=ON"
    ];
  });
}
# Handle CUDA CMake implicit directory fix.
// (
  let
    overrideWithSetupHook =
      cudaPackages:
      cudaPackages.overrideScope (
        final': prev':
        let
          inherit (prev'.backendStdenv) cc;
          update-what = if prev' ? "cuda_nvcc" then "cuda_nvcc" else "cudatoolkit";
          setupHook = prev.makeSetupHook {
            name = "cmake-filter-implicit-paths-hook";
            substitutions = {
              # Will be used to compute exclusion path.
              ccFullPath = "${cc}/bin/${cc.targetPrefix}c++";
            };
          } ./hooks/cuda-filter-cmake-implicit-paths-hook.sh;
        in
        {
          ${update-what} = prev'.${update-what}.overrideAttrs (old: {
            propagatedBuildInputs =
              (if old ? "propagatedBuildInputs" then old.propagatedBuildInputs else [ ])
              ++ [ setupHook ];
          });
        }
      );

    allCudaPackagesNames = builtins.filter (x: prev.lib.strings.hasPrefix "cudaPackages" x) (
      builtins.attrNames prev
    );
  in
  builtins.foldl' (
    acc: elem:
    {
      ${elem} = overrideWithSetupHook prev.${elem};
    }
    // acc
  ) { } allCudaPackagesNames
)
