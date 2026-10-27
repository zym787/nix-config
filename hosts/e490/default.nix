# 主机 e490 的入口：组合硬件、共享系统模块、用户和 Home Manager。
{pkgs, ...}: let
  # 主机特有变量（当前只有 hostName）。
  hostVars = import ./variables.nix;
in {
  # 共享系统配置；主机特有硬件单独放 hardware-configuration.nix。
  imports = [
    ./hardware-configuration.nix
    ../../common/nixos/core.nix
    ../../common/nixos/network.nix
    ../../common/nixos/proxy.nix
    ../../common/nixos/bluetooth.nix
    ../../common/nixos/desktop.nix
    ../../common/nixos/desktop-sessions.nix
    ../../common/nixos/graphics.nix
    ../../common/nixos/gaming.nix
    ../../common/nixos/appimage.nix
    ../../common/nixos/flatpak.nix
    ../../common/nixos/audio.nix
    ../../common/nixos/fonts.nix
    ../../common/nixos/ime.nix
    ../../common/nixos/printing.nix
    ../../common/nixos/systemd.nix
    ../../common/nixos/performance.nix
  ];

  # 主机名来自 variables.nix，保证磁盘/SSH/mDNS 名称一致。
  networking.hostName = hostVars.hostName;

  # 系统级 zsh；用户的 .zshrc/插件由 Home Manager 管理。
  programs.zsh.enable = true;

  # 系统级用户：Home Manager 挂载前必须先存在。
  users.users.drinkto = {
    isNormalUser = true;
    description = "drinkto";
    home = "/home/drinkto";
    # ghostty/kitty 都默认启动这个 shell；Home Manager 负责 .zshrc。
    shell = pkgs.zsh;
    # 远程登录用公钥；私钥只在客户端。
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIIN0efXDzfUMXzuI26CiV2xTAkxp/b4HIphsUVQXxU4 drinkto4nixos"
    ];
    # networkmanager 管理网络；wheel 允许 sudo；
    # video/render 用于 Intel/AMD GPU 和 Steam/Proton 的 DRM/Vulkan 访问。
    extraGroups = ["networkmanager" "wheel" "video" "render"];
  };

  # 该主机启用 drinkto 的 Home Manager 配置。
  # 首次登录 zsh 时用户可能已生成 ~/.zshrc；保留原文件并让 HM 接管。
  home-manager.backupFileExtension = "hm-backup";
  home-manager.users.drinkto = {
    imports = [../../users/drinkto];
  };
}
