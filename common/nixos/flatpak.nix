# Flatpak 支持：启用 flatpak 服务、XDG Portal，并自动使用国内镜像。
{pkgs, ...}: {
  # Flatpak 需要门户来提供文件选择、剪贴板、截图等桌面集成。
  xdg.portal.enable = true;

  services.flatpak.enable = true;

  # Flathub 上海交大镜像。系统级 remote 在启动时确保存在；
  # 用户级 remote 由 Home Manager activation 同步（见 users/drinkto）。
  systemd.services.flatpak-flathub-cn = {
    description = "Configure Flathub China mirror";
    wantedBy = ["multi-user.target"];
    after = ["network-online.target"];
    wants = ["network-online.target"];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.flatpak}/bin/flatpak remote-add --system --if-not-exists flathub https://mirror.sjtu.edu.cn/flathub/flathub.flatpakrepo || true; ${pkgs.flatpak}/bin/flatpak remote-modify --system --url=https://mirror.sjtu.edu.cn/flathub flathub || true'";
    };
  };
}
