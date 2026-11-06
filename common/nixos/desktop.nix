# 桌面环境：KDE Plasma 6 + SDDM + Wayland（XWayland 兼容 X11 应用）。
{...}: {
  # 实际会话是 Wayland；services.xserver 仍开启是为了 XWayland。
  # 如需强制 X11，请在 SDDM 登录界面选择 “Plasma (X11)”。
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # 只保留 KDE 作为默认桌面；Steam 会话由 gaming.nix 提供。
  services.displayManager.defaultSession = "plasma";

  # 可选桌面会话（默认注释）：
  # 取消对应块后执行 sudo nixos-rebuild switch --flake .#e490。
  #
  # GNOME：
  # services.desktopManager.gnome.enable = true;
  #
  # Niri（还需在 users/drinkto/default.nix 取消 DMS/niri imports）：
  # programs.niri.enable = true;
  # programs.niri.useNautilus = false;
  #
  # Hyprland（还需取消 users/drinkto/default.nix 的 hyprland import）：
  # programs.hyprland.enable = true;
  # programs.hyprland.withUWSM = true;

  # 鼠标/触控板设置：主要作为 X11/Xorg 的 fallback。
  # KDE Wayland 下触摸板、手势、轻触点击由 KDE 系统设置（KCM）管理，
  # 这里的一些选项不会直接覆盖 KWin 的运行时设置。
  services.libinput = {
    enable = true;

    mouse = {
      accelProfile = "adaptive"; # 自适应加速；"flat" 可关闭加速
      naturalScrolling = false; # 鼠标保持传统滚动方向
      middleEmulation = false; # 不用左右键模拟中键
    };

    touchpad = {
      naturalScrolling = true; # 类似 macOS 的自然滚动
      tapping = true; # 允许轻触点击
      tappingButtonMap = "lrm"; # 左/右/中键映射
      clickMethod = "clickfinger"; # 双指右键、三指中键
      accelProfile = "adaptive";
      disableWhileTyping = true; # 打字时禁用触控板
      scrollMethod = "twofinger"; # 双指滚动
    };
  };
}
