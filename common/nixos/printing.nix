# 打印/扫描：CUPS + Brother DCP-7057 驱动。
{
  lib,
  pkgs,
  ...
}: {
  services.printing.enable = true;

  # DCP-7057 优先使用 brlaser；其余 Brother/通用驱动作为备选。
  services.printing.drivers = with pkgs; [
    brlaser # Brother 激光打印机开源驱动
    brgenml1lpr # Brother 官方 LPR 驱动
    brgenml1cupswrapper # Brother 官方 CUPS wrapper
    gutenprint # 通用驱动
    gutenprintBin # Gutenprint 二进制插件
  ];

  # ipp-usb 会启用 avahi 和 sane（扫描）功能，不能简单关闭。
  # 它仍在使用旧的 services.avahi.publish.* 选项，这里强制清空旧选项，
  # 并用新的 settings.publish.* 等价表达，消除 obsolete 警告。
  # 如果以后 nixpkgs 的 ipp-usb 模块迁移到新选项，可删除 mkForce 两行。
  services.ipp-usb.enable = true;
  services.avahi.publish.enable = lib.mkForce null;
  services.avahi.publish.userServices = lib.mkForce null;
  services.avahi.settings.publish = {
    "disable-publishing" = false;
    "disable-user-service-publishing" = false;
    "publish-addresses" = true;
  };
}
