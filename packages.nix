final: prev:
prev.lib.packagesFromDirectoryRecursive {
  inherit (prev) callPackage newScope;
  directory = ./pkgs;
}
