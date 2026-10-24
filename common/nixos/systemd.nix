# systemd 相关调整。
{...}: {
  # 关闭 fwupd 自动刷新，避免后台定时器；
  # 需要更新固件时手动执行：sudo fwupdmgr refresh && sudo fwupdmgr update
  systemd.services.fwupd-refresh.enable = false;
  systemd.timers.fwupd-refresh.enable = false;

  # 不再覆盖 kde-baloo.service。
  # baloo 包自带正确的 unit：
  #   PartOf=graphical-session.target
  #   After=graphical-session.target
  #   After=plasma-workspace.target
  #   WantedBy=graphical-session.target
  # 自定义版本缺少 plasma-workspace.target 的排序，会导致 ordering cycle。
}
