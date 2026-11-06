# GNOME

GNOME 是可选桌面，默认关闭；SDDM 仍作为统一显示管理器，不使用 GDM。

## 启用

1. 编辑 `common/nixos/desktop.nix`，取消 GNOME 注释：
   ```nix
   services.desktopManager.gnome.enable = true;
   ```
2. 不需要改用户 import。
3. 构建并切换：
   ```bash
   sudo nixos-rebuild build --flake .#e490
   sudo nixos-rebuild switch --flake .#e490
   ```
4. 注销，在 SDDM 会话菜单选择 **GNOME**。

默认会话仍是 KDE。如果希望 GNOME 默认登录：

```nix
services.displayManager.defaultSession = "gnome";
```

## 设计说明

- **不启用 GDM**：系统已有 SDDM，避免两个 display manager 冲突；
- GNOME 通过 SDDM 启动 `gnome-session`；
- GNOME 的 XDG Portal、GNOME Keyring、GNOME Settings Daemon 由 NixOS
  模块自动安装；
- 与 KDE 同时启用时，SSH askpass 等冲突由统一配置处理；
- GNOME 输入法仍使用系统的 fcitx5/Rime，不使用 IBus 作为默认输入法。

## 关闭

注释掉 `services.desktopManager.gnome.enable`，重新 build/switch。  
已经安装的 GNOME 用户数据不会自动删除。

## 常见问题

### 登录后回到 SDDM

查看日志：

```bash
journalctl -b -u display-manager --no-pager
journalctl --user -b | grep -i -E 'gnome|gdm|portal'
```

### 无法登录时

在 SDDM 选择 **Plasma**，或按 `Ctrl+Alt+F2` 进入 TTY，修复配置后再切换。

### 文件选择器/截图异常

确认 XDG Portal：

```bash
systemctl --user status xdg-desktop-portal
```

GNOME 的 portal 由桌面模块提供，不需要手工安装。
