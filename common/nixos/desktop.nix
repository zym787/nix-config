# 桌面环境：KDE Plasma 6 + SDDM + Wayland（XWayland 兼容 X11 应用）。
{...}: {
  # 实际会话是 Wayland；services.xserver 仍开启是为了 XWayland。
  # 如需强制 X11，请在 SDDM 登录界面选择 “Plasma (X11)”。
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

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
