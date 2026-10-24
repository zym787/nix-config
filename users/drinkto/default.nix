{
  settings,
  pkgs,
  ...
}: let
  packages = settings.packages {inherit pkgs;};
in {
  imports = [../../common/home];

  home = {
    username = "drinkto";
    homeDirectory = "/home/drinkto";
    stateVersion = settings.stateVersion;
  };

  home.packages =
    packages.core
    ++ packages.networking
    ++ packages.dev
    ++ packages.office
    ++ packages.ai
    ++ packages.desktop
    ++ packages.utils
    ++ packages.media
    ++ packages.messaging
    ++ packages.systemTools
    ++ packages.nixTools
    ++ packages.cloud;

  programs.git.settings.user = {
    name = "drinkto";
    email = "z_one787@163.com";
  };
}
