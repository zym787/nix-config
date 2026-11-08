# KDE Plasma（可选）

KDE Plasma 当前**默认关闭**，SDDM 默认进入 GNOME。KDE 仅作为注释开关保留，
需要时手动启用并 build。

## 当前状态

- 桌面：KDE Plasma 6
- 显示管理器：SDDM
- 默认会话：GNOME（`defaultSession = "gnome"`）
- KDE 系统级开关在 `common/nixos/desktop.nix` 中注释
- KDE 与 Steam 都可以在 SDDM 选择；当前只默认启用 GNOME + Steam

## 启用 KDE

编辑 `common/nixos/desktop.nix`：

1. 注释 GNOME：
   ```nix
   # services.desktopManager.gnome.enable = true;
   # services.displayManager.gdm.enable = false;
   ```
2. 取消 KDE 注释：
   ```nix
   services.desktopManager.plasma6.enable = true;
   ```
3. 把默认会话改为：
   ```nix
   services.displayManager.defaultSession = "plasma";
   ```
4. 构建并切换：
   ```bash
   sudo nixos-rebuild build --flake .#e490
   sudo nixos-rebuild switch --flake .#e490
   ```
5. 注销，在 SDDM 选择 **Plasma**。

> 不建议同时启用 KDE 和 GNOME。两者会争抢 SSH askpass/portal，
> 需要额外处理 `programs.ssh.askPassword` 和 portal 配置。

## 相关配置

```text
common/nixos/desktop.nix     SDDM / KDE 开关 / libinput
common/nixos/audio.nix       PipeWire
common/nixos/ime.nix         fcitx5 + Rime
users/drinkto/default.nix    用户级配置
```

KDE 运行时设置由 KDE 自己保存：

```text
~/.config/kcminputrc        鼠标/触摸板
~/.config/kwinrc            KWin
~/.config/kdeglobals        主题/字体
```

这些不是 NixOS 声明式配置；修改 Nix 不会覆盖当前 KDE 会话里的 KCM 设置。

## X11 / Wayland

`services.xserver.enable = true` 仍然保留，主要用于 XWayland、SDDM 和
需要 X11 的兼容应用。登录时如果 SDDM 显示 X11 选项，可以用
**Plasma (X11)** 做兼容性排查；日常使用 Wayland。

## 输入设备

`common/nixos/desktop.nix` 的 `services.libinput` 是 X11/Xorg 的兜底配置。
KDE Wayland 下实际由 KDE 系统设置管理：

```text
系统设置 → 输入设备 → 鼠标和触摸板
```

## 关闭 KDE

1. 注销到 SDDM；
2. 选择 GNOME 或 Steam；
3. 注释 `services.desktopManager.plasma6.enable`；
4. 恢复 GNOME 开关和 `defaultSession = "gnome"`；
5. 重新 build/switch。

KDE 用户数据不会自动删除。

## 故障排查

```bash
echo "$XDG_SESSION_TYPE"
echo "$XDG_CURRENT_DESKTOP"
journalctl -b -u display-manager --no-pager
journalctl --user -b | grep -i -E 'kwin|plasma|sddm'
cat ~/.config/kcminputrc
```

如果 KDE 登录失败，SDDM 选择 GNOME/Steam，或按 `Ctrl+Alt+F2` 进 TTY 修复。
