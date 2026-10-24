# 桌面环境：KDE Plasma 6 + SDDM + X11，以及 libinput 输入设备行为。
{...}: {
  # 当前使用 X11 会话；如需 Wayland，需另行调整 SDDM/Plasma 配置。
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # 鼠标/触控板设置：触控板自然滚动、轻触点击、双指滚动。
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
