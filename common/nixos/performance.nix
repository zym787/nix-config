# 系统响应性/性能调优。
# 这里不做强制超频或固定 performance governor，避免笔记本发热和续航明显变差；
# 需要极限性能时用 `powerprofilesctl set performance` 或 KDE 电源管理切换。
{...}: {
  # zram：用压缩内存做优先 swap，减少磁盘 swap 抖动。
  # 24G 内存取 25% ≈ 6G；磁盘 swap（24G）仍保留为后备。
  zramSwap = {
    enable = true;
    memoryPercent = 25;
    priority = 5;
  };

  # 尽量保留 RAM 和文件缓存，减少不必要的换出和脏页回写。
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "vm.vfs_cache_pressure" = 50;
    "vm.dirty_background_ratio" = 5;
    "vm.dirty_ratio" = 15;
  };

  # SSD 定期 TRIM，维持长期写入性能。
  services.fstrim.enable = true;

  # 不在 E490 上启用 thermald：
  # 该机的 thinkpad_acpi dytc_lapmode 会让 thermald 报
  # "Unsupported cpu model or platform" 并直接退出。
  # 温度/频率由 intel_pstate + power-profiles-daemon 管理。
  #
  # 电源配置由 PPD 管理，KDE 可切换 balanced / performance / power-saver。
  # 默认保持 balanced，不在这里强制 performance。
  services.power-profiles-daemon.enable = true;
}
