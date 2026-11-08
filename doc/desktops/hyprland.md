# Hyprland

Hyprland 是可选桌面，默认关闭。配置在
`users/drinkto/hyprland.nix`，使用 DMS 作为启动器/通知/电源菜单。

## 启用

### 1. 系统级开关

编辑 `common/nixos/desktop.nix`，取消注释：

```nix
programs.hyprland.enable = true;
programs.hyprland.withUWSM = true;
```

### 2. Home Manager 开关

Hyprland 配置依赖 DMS 包，因此需要在
`users/drinkto/default.nix` 取消这些注释：

```nix
inputs.dms.homeModules.dank-material-shell
./hyprland.nix
```

并取消：

```nix
programs.dank-material-shell = {
  enable = true;
  enableSystemMonitoring = true;
  enableCalendarEvents = false;
};
```

### 3. 构建和登录

```bash
sudo nixos-rebuild build --flake .#e490
sudo nixos-rebuild switch --flake .#e490
```

注销，在 GDM 选择 **Hyprland**。默认会话仍是 GNOME；如果想默认 Hyprland：

```nix
services.displayManager.defaultSession = "hyprland";
```

## 当前键位

来自 `users/drinkto/hyprland.nix`：

| 快捷键 | 行动 |
| :--- | :--- |
| `Win+Enter` | Ghostty |
| `Win+Shift+Enter` | Kitty |
| `Win+D` | DMS 启动器 |
| `Win+Q` | 关闭窗口 |
| `Win+M` | 退出 Hyprland |
| `Win+V` | 浮动/平铺 |
| `Win+F` | 全屏 |
| `Win+Shift+F` | 全屏（模式 1） |
| `Win+方向键` | 聚焦窗口 |
| `Win+Shift+方向键` | 移动窗口 |
| `Win+1..5` | 工作区 1–5 |
| `Win+Shift+1..5` | 移动窗口到工作区 |
| `Win+X` | DMS 电源菜单 |
| `Win+N` | DMS 通知 |
| `Win+Alt+V` | DMS 剪贴板 |

## 配置结构

```text
users/drinkto/hyprland.nix          Hyprland 配置源
~/.config/hypr/hyprland.conf        Home Manager 生成的实际配置
common/nixos/desktop.nix            Hyprland 系统开关（注释）
users/drinkto/default.nix           DMS/Hyprland imports（注释）
```

DMS 由 Hyprland 的 `exec-once` 启动：

```text
exec-once = /nix/store/.../bin/dms run
```

## 验证

启用后可以在 TTY 或当前会话验证配置：

```bash
hyprland --verify-config -c ~/.config/hypr/hyprland.conf
```

查看日志：

```bash
journalctl --user -b | grep -i -E 'hyprland|dms|portal'
```

## 关闭

注销到 GDM，选择 GNOME，然后注释掉：

- `common/nixos/desktop.nix` 中 Hyprland 两行；
- `users/drinkto/default.nix` 中 `./hyprland.nix` 和 DMS import/配置块。

重新 build/switch。Hyprland/DMS 用户数据不会自动删除。

## 注意

- 不要同时启动 Hyprland 和 Niri/GNOME/KDE 会话。
- Hyprland 的 `withUWSM = true` 依赖系统 UWSM/systemd 集成。
- 如果 DMS 没启动，可先运行 `dms run` 排查；构建时如果 DMS import
  没打开，`users/drinkto/hyprland.nix` 会找不到 `programs.dank-material-shell.package`。
- Hyprland 与 Niri 共用 DMS 时，只启用实际要用的 compositor。
