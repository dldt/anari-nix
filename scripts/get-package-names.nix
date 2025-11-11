{
  flake-path,
}:
with builtins;
let
  flake = builtins.getFlake (builtins.toString flake-path);
  allPackages =
    let
      uniquePackages =
        list: foldl' (acc: e: if elem e.name (catAttrs "name" acc) then acc else acc ++ [ e ]) [ ] list;
    in
    uniquePackages (concatMap attrValues (attrValues flake.outputs.packages));
in
{
  allPackages = map (p: p.pname) allPackages;
}
