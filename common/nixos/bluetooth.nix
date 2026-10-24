# 蓝牙支持：BlueZ + 开机自动上电。
{...}: {
  # Plasma 6 的 NixOS 模块会在 hardware.bluetooth.enable = true 时
  # 自动把 bluedevil / bluez-qt 加入系统包，提供 KDE 蓝牙托盘和 QML 模块。
  # 不要再把 kdePackages.bluedevil 放进 home.packages，否则会出现重复的
  # QML 搜索路径，甚至 applet 找不到 org.kde.bluezqt。
  hardware.bluetooth = {
    enable = true;
    # 开机时自动解除 rfkill 软阻塞，避免每次手动打开。
    powerOnBoot = true;

    # 启用蓝牙音频（A2DP/HFP）和串口/网络等常用 profile。
    settings.General = {
      Enable = "Source,Sink,Media,Socket";
    };
  };
}
