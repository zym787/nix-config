# Flatpak 支持：启用 flatpak 服务和 XDG Desktop Portal。
# Flathub 远程仓库不在这里硬编码；首次使用按 README 的命令添加。
{...}: {
  # Flatpak 需要门户来提供文件选择、剪贴板、截图等桌面集成。
  # Plasma 已经启用 xdg.portal；这里显式写出，避免以后换桌面时遗漏。
  xdg.portal.enable = true;

  services.flatpak.enable = true;
}
