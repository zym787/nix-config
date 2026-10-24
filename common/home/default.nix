# 所有用户共享的 Home Manager 基础配置。
{...}: {
  imports = [
    ./git.nix
    ./shell.nix
  ];

  # 让 Home Manager 管理自身，便于 `home-manager` 命令和代际回滚。
  programs.home-manager.enable = true;
}
