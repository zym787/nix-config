# 桌面环境：GNOME + SDDM + Wayland（XWayland 兼容 X11 应用）。
{...}: {
  # 实际会话是 GNOME Wayland；services.xserver 仍开启是为了 XWayland/SDDM。
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;

  # GNOME 是当前默认桌面；GDM 不启用，继续使用 SDDM。
  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = false;
  services.displayManager.defaultSession = "gnome";

  # KDE Plasma 已完全注释；需要切回 KDE 时取消这一行，并同时关闭 GNOME。
  # services.desktopManager.plasma6.enable = true;

  # 可选桌面会话（默认注释）：
  # 取消对应块后执行 sudo nixos-rebuild switch --flake .#e490。
  #
  # Niri（还需在 users/drinkto/default.nix 取消 DMS/niri imports）：
  # programs.niri.enable = true;
  # programs.niri.useNautilus = false;
  #
  # Hyprland（还需取消 users/drinkto/default.nix 的 hyprland import）：
  # programs.hyprland.enable = true;
  # programs.hyprland.withUWSM = true;

  # 鼠标/触控板设置：主要作为 X11/Xorg 的 fallback。
  # GNOME Wayland 下触摸板、手势、轻触点击由 GNOME 控制中心管理，
  # 这里的一些选项不会直接覆盖 Mutter 的运行时设置。
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
