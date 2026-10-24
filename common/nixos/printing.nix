{
  lib,
  pkgs,
  ...
}: {
  services.printing.enable = true;
  services.printing.drivers = with pkgs; [
    brlaser
    brgenml1lpr
    brgenml1cupswrapper
    gutenprint
    gutenprintBin
  ];

  # ipp-usb 会启用 avahi 和 sane（扫描）功能，不能简单关闭。
  # 它仍在使用旧的 services.avahi.publish.* 选项，这里强制清空旧选项，
  # 并用新的 settings.publish.* 等价表达，消除 obsolete 警告。
  services.ipp-usb.enable = true;
  services.avahi.publish.enable = lib.mkForce null;
  services.avahi.publish.userServices = lib.mkForce null;
  services.avahi.settings.publish = {
    "disable-publishing" = false;
    "disable-user-service-publishing" = false;
    "publish-addresses" = true;
  };
}
