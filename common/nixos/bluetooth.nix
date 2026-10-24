# 蓝牙支持：BlueZ + 开机自动上电。
{...}: {
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
