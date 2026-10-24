{ pkgs, ... }:
{
  services.printing.enable = true;
  services.printing.drivers = with pkgs; [
    brlaser
    brgenml1lpr
    brgenml1cupswrapper
    gutenprint
    gutenprintBin
  ];

  # DCP-7057 是 USB GDI 打印机，由 brlaser 驱动；不使用 IPP-over-USB。
  # 关闭后 avahi 的 publish 旧选项不再被设置，警告消失。
  services.ipp-usb.enable = false;
}
