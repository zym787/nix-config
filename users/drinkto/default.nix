# drinkto 的个人 Home Manager 配置。
{
  settings,
  pkgs,
  ...
}: let
  # 包分组来自 settings/packages.nix；system 组由 core.nix 安装到系统。
  packages = settings.packages {inherit pkgs;};
in {
  # 所有用户共享的 git/starship/home-manager 基础。
  imports = [../../common/home];

  home = {
    username = "drinkto";
    homeDirectory = "/home/drinkto";
    # 与系统 stateVersion 保持同一个来源，避免两边不一致。
    stateVersion = settings.stateVersion;
  };

  # 个人用户级软件：GUI、CLI、开发工具、媒体等。
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

  # git 身份属于个人配置，放在用户目录而不是 common/home。
  programs.git.settings.user = {
    name = "drinkto";
    email = "z_one787@163.com";
  };
}
