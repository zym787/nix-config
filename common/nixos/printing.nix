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

  # P5 决策：DCP-7057 如果不需要 IPP-over-USB，关闭它可消除 avahi 警告。
  services.ipp-usb.enable = true;
}
