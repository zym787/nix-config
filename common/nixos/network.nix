# 所有主机共享的网络配置。
# hostName 属于主机特有信息，放在 hosts/<host>/variables.nix，由 host 入口设置。
{...}: {
  # 桌面/笔记本统一使用 NetworkManager 管理有线和无线连接。
  networking.networkmanager.enable = true;
}
