# 桌面配置总览

本目录按桌面分别记录 **KDE、GNOME、Niri、Hyprland 和 Steam** 的启用方式、
配置位置与注意事项。

## 当前默认状态

| 会话 | 默认 | 说明 |
| :--- | :---: | :--- |
| **GNOME** | ✅ | 默认桌面，GDM 登录 |
| **Steam** | ✅ | gamescope + Steam Big Picture 游戏会话 |
| KDE Plasma | ⬜ | 注释开关，需要时手动启用 |
| Niri + DMS | ⬜ | 注释开关，需要时手动启用 |
| Hyprland | ⬜ | 注释开关，需要时手动启用 |

当前**没有**运行时“一键切换”脚本。切换方式是：

1. 修改 Nix 配置中的注释开关；
2. 执行 `sudo nixos-rebuild switch --flake .#e490`；
3. 注销后在 GDM 会话菜单中选择目标桌面。

默认会话固定为 GNOME：

```nix
# common/nixos/desktop.nix
services.displayManager.defaultSession = "gnome";
```

如果希望在 GDM 中默认选中 Niri，可改为 `"niri"`，但这不改变“手动 build”
的启停方式。

## 配置入口

| 配置 | 位置 |
| :--- | :--- |
| GNOME / GDM / 输入设备 | `common/nixos/desktop.nix` |
| GNOME 光标/图标/GTK | `common/home/gnome.nix` |
| Steam 游戏会话 | `common/nixos/gaming.nix` |
| KDE 可选开关 | `common/nixos/desktop.nix` 注释 |
| Niri 可选开关 | `common/nixos/desktop.nix` + `users/drinkto/default.nix` |
| Hyprland 可选开关 | `common/nixos/desktop.nix` + `users/drinkto/default.nix` |
| Niri 键位/DMS | `users/drinkto/niri.nix` |
| Hyprland 键位 | `users/drinkto/hyprland.nix` |
| Zsh/Starship | `common/home/shell.nix` |
| Flatpak / AppImage | `common/nixos/flatpak.nix`、`common/nixos/appimage.nix` |
| Obsidian AppImage | `users/drinkto/obsidian-appimage.nix` |

## 通用启用流程

1. 打开 `common/nixos/desktop.nix`。
2. 取消目标桌面注释块。
3. 如果目标是 Niri 或 Hyprland，再到 `users/drinkto/default.nix` 取消对应
   Home Manager import；Niri/Hyprland 还需要 DMS 的 import 和
   `programs.dank-material-shell` 块。
4. 执行：
   ```bash
   sudo nixos-rebuild build --flake .#e490
   sudo nixos-rebuild switch --flake .#e490
   ```
5. 注销，在 GDM 会话菜单中选择桌面。

GNOME 和 Steam 始终启用，不需要额外操作。

## 通用回滚

- 注释掉新增桌面块，重新 build/switch；
- 不会删除用户数据；
- 如果桌面无法登录，可在 GDM 选择 GNOME，或按 `Ctrl+Alt+F2` 进 TTY 修复。

## 相关文档

- [KDE Plasma](kde.md)
- [GNOME](gnome.md)
- [Niri + DMS](niri.md)
- [Hyprland](hyprland.md)
- [Steam gamescope](steam.md)
- 全局维护：[../MAINTENANCE.md](../MAINTENANCE.md)
- 架构规则：[../ARCHITECTURE.md](../ARCHITECTURE.md)
