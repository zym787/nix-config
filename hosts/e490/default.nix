{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../nixos/configuration.nix
  ];

  # 原 flake.nix 中通过 users.users.drinkto.home 设置，先搬到这里
  users.users.drinkto.home = "/home/drinkto";

  # 原 flake.nix 中的 HM 挂载，Phase 1 先继续使用旧 home.nix
  home-manager.users.drinkto = {
    imports = [ ../../home-manager/home.nix ];
  };
}
