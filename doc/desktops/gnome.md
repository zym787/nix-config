# GNOME

GNOME 是**当前默认桌面**；SDDM 作为统一显示管理器，不使用 GDM。

## 当前状态

- 桌面：GNOME
- 显示管理器：SDDM
- 默认 Session：
  ```nix
  services.displayManager.defaultSession = "gnome";
  ```
- KDE Plasma 已注释，默认不安装/不启用
- Steam 是另一个常驻的游戏会话

配置位置：`common/nixos/desktop.nix`：

```nix
services.desktopManager.gnome.enable = true;
services.displayManager.gdm.enable = false;
services.displayManager.defaultSession = "gnome";
```

## 设计说明

- **不启用 GDM**：系统已有 SDDM，避免两个 display manager 冲突；
- GNOME 通过 SDDM 启动 `gnome-session`；
- GNOME 的 XDG Portal、GNOME Keyring、GNOME Settings Daemon 由 NixOS
  模块自动安装；
- SSH askpass 由 GNOME 的 seahorse 提供；如果以后同时启用 KDE，需要单独
  处理 KDE KSSHAskPass 与 seahorse 的冲突；
- GNOME 输入法仍使用系统的 fcitx5/Rime，不使用 IBus 作为默认输入法。

## 切换/关闭

如果要切回 KDE：

1. 注释 `services.desktopManager.gnome.enable`；
2. 取消 `services.desktopManager.plasma6.enable` 注释；
3. 把 `defaultSession` 改为 `"plasma"`；
4. build/switch 后注销，在 SDDM 选择 Plasma。

如果只是临时使用 KDE，不要同时启用两个桌面管理器，以免 askpass/portal
冲突。

## 常见问题

### 登录后回到 SDDM

查看日志：

```bash
journalctl -b -u display-manager --no-pager
journalctl --user -b | grep -i -E 'gnome|gdm|portal'
```

### 无法登录时

在 SDDM 选择 **Steam**（如果只是想进入可用会话），或按 `Ctrl+Alt+F2`
进入 TTY 修复；如果已经启用了 KDE，也可以选择 Plasma。

### 文件选择器/截图异常

确认 XDG Portal：

```bash
systemctl --user status xdg-desktop-portal
```

GNOME 的 portal 由桌面模块提供，不需要手工安装。
