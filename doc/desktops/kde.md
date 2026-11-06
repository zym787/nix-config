# KDE Plasma

KDE 是当前默认桌面，默认会话名为 `plasma`。

## 当前状态

- 桌面：KDE Plasma 6
- 显示管理器：SDDM
- 会话：Wayland；保留 XWayland 兼容 X11 应用
- 默认 Session：
  ```nix
  services.displayManager.defaultSession = "plasma";
  ```
- KDE 与 Steam 是当前默认启用的两个会话

## 相关配置

```text
common/nixos/desktop.nix     KDE / SDDM / libinput
common/nixos/audio.nix       PipeWire
common/nixos/ime.nix         fcitx5 + Rime
users/drinkto/default.nix    用户级桌面相关配置
```

KDE 的运行时设置由 KDE 自己保存，例如：

```text
~/.config/kcminputrc        鼠标/触摸板
~/.config/kwinrc            KWin
~/.config/kdeglobals        主题/字体
```

这些文件不是 NixOS 声明式配置；修改 Nix 文件不会覆盖当前 KDE 会话里的
KCM 设置。

## X11 / Wayland

`services.xserver.enable = true` 仍然保留，主要用于：

- XWayland
- SDDM
- 需要 X11 的兼容应用
- 可选的 Plasma X11 会话

登录时如果 SDDM 显示 X11 选项，可以选择 **Plasma (X11)** 做兼容性排查。
日常使用 Wayland。

## 输入设备

`common/nixos/desktop.nix` 的 `services.libinput` 是 X11/Xorg 的兜底配置。
KDE Wayland 下实际由 KDE 系统设置管理：

```text
系统设置 → 输入设备 → 鼠标和触摸板
```

如果触摸板行为不符合预期，优先调整 KDE KCM，而不是只改 Nix 的
`services.libinput`。

## 切换与禁用

KDE 默认启用，不需要手动开关。临时切到 Steam 会话：

1. 注销；
2. SDDM 会话菜单选择 **Steam**；
3. 游戏结束后退出 Steam，回到 SDDM；
4. 选择 **Plasma**。

如果未来要把 KDE 改成可选：

```nix
# common/nixos/desktop.nix
services.desktopManager.plasma6.enable = false;
```

并确保至少还有一个可登录桌面，否则 SDDM 可能没有可用会话。

## 故障排查

```bash
# 当前会话
echo "$XDG_SESSION_TYPE"
echo "$XDG_CURRENT_DESKTOP"

# SDDM / KDE 日志
journalctl -b -u display-manager --no-pager
journalctl --user -b | grep -i -E 'kwin|plasma|sddm'

# KDE 输入设置
cat ~/.config/kcminputrc
```

如果 KDE 登录失败，可先选择 Steam 或 TTY，修复后再回到 Plasma。
