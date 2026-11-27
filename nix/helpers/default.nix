rec {
  importFromFiles =
    {
      list,
      attrs,
      targetAttr,
    }:
    map (path: (import path { inherit attrs; }).${targetAttr}) list;
  # bulkImportFromFileDirectory :: (path: String, attrs: AttrSet) -> [Path] -> [[Package]] -> [Package]
  bulkImportFromFileDirectory =
    {
      path,
      attrs,
      inputs,
      lib,
      ...
    }:
    rec {
      allFilePaths = (inputs.import-tree.withLib lib).leafs path;
      doImport = importFromFiles {
        list = allFilePaths;
        targetAttr = "packages";
        inherit attrs;
      };
      allPackages = builtins.concatLists doImport;
    };

  # genOptionalsFromConfig
  # :: {
  #     conditional :: AttrSet -> Bool,
  #     path:: Path
  #     target :: [String]
  #
  #   } -> (map ((f :: AttrSet -> Bool) -> a)  -> [a])
  #
  genOptionalsFromConfig =
    {
      conditional,
      path,
      target,
      lib,
      ...
    }:
    map (x: lib.optionals (conditional x) path) target;

  selectFromOlderPkgs =
    {
      lib,
      pkgs,
      pkgsOlder,
      packageName,
      versionCriterion,
      versionConfig,
    }:
    if lib.versionAtLeast versionConfig versionCriterion then
      pkgs."${packageName}${toString versionConfig}"
    else
      pkgsOlder."${packageName}${versionConfig}";
  selectFromOlderPkgsInt =
    {
      pkgs,
      pkgsOlder,
      packageName,
      versionCriterion,
      versionConfig,
    }:
    if versionConfig < versionCriterion then
      pkgsOlder."${packageName}${toString versionConfig}"
    else
      pkgs."${packageName}${toString versionConfig}";

  listSubdirectories = {dir, exclude ? []}: let entries = builtins.readDir dir; in builtins.filter (
    name: entries.${name} == "directory" && builtins.substring 0 1 name != "_" && !(builtins.elem name exclude)
  ) (builtins.attrNames entries);
}
