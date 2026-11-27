{ pkgs, ... }: {
  languages = {
   fortran = {
     enable = true;
     fprettify.enable = true;
   };
  };
}
