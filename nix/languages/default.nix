{ lib, ... }:
let
  t = lib.types;
  helpers = import ../helpers;
  languages = helpers.listSubdirectories {dir = ./.; exclude = ["default"];};
in
{
  perSystem =
    { config, ... }:
    {
      options.languages = lib.genAttrs languages (name: {
        extraPackages = lib.mkOption {
          type = t.listOf t.package;
          default = [ ];
          example = lib.literalExpression "[ pkgs.valgrind ]";
          description = "Extra packages to add to the ${name} devshell.";
        };
      });

      config.devshells = lib.mkMerge (
        map (
          name:
          lib.mkIf (config.languages.${name}.enable or false) {
            ${name}.packages = config.languages.${name}.extraPackages;
          }
        ) languages
      );
    };
}
