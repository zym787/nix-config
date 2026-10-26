# 多桌面会话：niri + DMS 为默认，同时保留 KDE、GNOME、Hyprland、Denial。
# 所有会话都注册到 SDDM，登录时在会话菜单中选择；不需要重装系统。
{
  inputs,
  pkgs,
  lib,
  ...
}: {
  # DenialWM 官方 flake 提供 NixOS module；必须在启用前导入。
  imports = [
    inputs.denial.nixosModules.denial
  ];

  # Niri 是主会话；DMS 由用户的 niri 配置启动。
  programs.niri.enable = true;
  programs.niri.useNautilus = false; # 使用 GTK portal 的文件选择器

  # 保留 KDE Plasma 作为日常/兼容会话。
  services.desktopManager.plasma6.enable = true;

  # GNOME 作为尝鲜会话；继续使用 SDDM，不启用 GDM。
  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = false;

  # Hyprland 作为尝鲜会话；UWSM 改善 systemd 集成。
  programs.hyprland.enable = true;
  programs.hyprland.withUWSM = true;

  # DenialWM：Flutter 原生 Wayland 合成器，实验性会话。
  # 官方包首次可能需要编译整套 Flutter engine，默认关闭；需要时改成 true
  # 并重新 switch，SDDM 就会出现 Denial 会话。
  programs.denial.enable = false;
  programs.denial.package = inputs.denial.packages.${pkgs.stdenv.hostPlatform.system}.denial;

  # 默认进入 Niri；SDDM 会话菜单仍可选其他桌面。
  services.displayManager.defaultSession = "niri";

  # KDE 与 GNOME 同时安装时会争抢 SSH askpass；统一使用 KSSHAskPass。
  programs.ssh.askPassword = lib.mkForce "${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass";

  # 一个很轻量的“退出到会话选择器”辅助命令。
  # 真正的会话切换发生在 SDDM：注销后点选目标会话即可。
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "desktop-sessions" ''
      echo "可用桌面会话："
      for f in /run/current-system/sw/share/wayland-sessions/*.desktop \
               /run/current-system/sw/share/xsessions/*.desktop; do
        [ -f "$f" ] || continue
        name=$(sed -n 's/^Name=//p' "$f" | head -n1)
        echo "  - ''${name:-$(basename "$f" .desktop)}"
      done
      echo
      echo "注销后在 SDDM 右下角的会话菜单中选择，即可切换；无需重建 NixOS。"
    '')

    (pkgs.writeShellScriptBin "desktop-switch" ''
      echo "注销后会在 SDDM 会话菜单中选择桌面。"
      echo "默认会话是 Niri + DMS。"
      read -r -p "现在注销？[y/N] " answer
      case "$answer" in
        y|Y|yes|YES)
          exec loginctl terminate-session "$XDG_SESSION_ID"
          ;;
        *)
          echo "已取消。"
          ;;
      esac
    '')
  ];
}
