# Niri + DMS

Niri 是可选桌面，默认关闭。启用后使用 **Niri + DankMaterialShell（DMS，
上游已改名 Dux Shell）**。DMS 的 Nix 选项仍叫
`programs.dank-material-shell`，命令行是 `dms`。

> 本配置不是运行时一键切换：需要打开注释、重新 build，再在 SDDM 选择 Niri。

## 1. 启用 Niri + DMS

### 1.1 系统级开关

编辑 `common/nixos/desktop.nix`，取消注释：

```nix
programs.niri.enable = true;
programs.niri.useNautilus = false;
```

### 1.2 Home Manager 开关

编辑 `users/drinkto/default.nix`，取消这几行注释：

```nix
inputs.dms.homeModules.dank-material-shell
./niri.nix
```

同时取消：

```nix
programs.dank-material-shell = {
  enable = true;
  enableSystemMonitoring = true;
  enableCalendarEvents = false;
};
```

### 1.3 构建并登录

```bash
sudo nixos-rebuild build --flake .#e490
sudo nixos-rebuild switch --flake .#e490
```

注销后在 SDDM 会话菜单选择 **Niri**。默认会话仍是 GNOME；如果想让 Niri
默认登录：

```nix
services.displayManager.defaultSession = "niri";
```

## 2. 启用后的结构

```text
users/drinkto/niri.nix              Niri KDL 配置、DMS 启动、键位
~/.config/niri/config.kdl           Home Manager 生成的实际配置
~/.config/dms/settings.json         DMS 用户配置
common/nixos/desktop.nix            Niri 系统开关（注释）
users/drinkto/default.nix           DMS/Niri imports（注释）
```

DMS 由 Niri 的 `spawn-at-startup` 启动，没有单独的 DMS systemd 服务。

## 3. Niri 的核心概念

Niri 是**可滚动平铺窗口管理器**：

- 窗口按横向列排列；
- 新窗口出现在当前列右侧；
- 左右切换列，上下切换同列窗口；
- 工作区是动态的；
- 用 Overview 总览窗口和工作区；
- 配置里的 `Mod` 在 TTY 会话中等于 **Super（Windows）键**。

## 4. 默认快捷键

这些键位来自 `users/drinkto/niri.nix`。

### 启动与 DMS

| 快捷键 | 行动 |
| :--- | :--- |
| `Win+Enter` | Ghostty |
| `Win+Shift+Enter` | Kitty |
| `Win+D` | DMS 启动器 |
| `Win+Space` | DMS 启动器备用 |
| `Win+X` | DMS 电源菜单 |
| `Win+N` | DMS 通知中心 |
| `Win+Alt+V` | DMS 剪贴板 |
| `Super+Alt+L` | DMS 锁屏 |

### 窗口与列

| 快捷键 | 行动 |
| :--- | :--- |
| `Win+Left` / `Win+H` | 聚焦左列 |
| `Win+Right` / `Win+L` | 聚焦右列 |
| `Win+Up` / `Win+K` | 聚焦上方窗口 |
| `Win+Down` / `Win+J` | 聚焦下方窗口 |
| `Win+Ctrl+方向键` | 移动列/窗口 |
| `Win+Q` / `Alt+F4` | 关闭窗口 |
| `Win+F` | 最大化当前列 |
| `Win+Shift+F` | 全屏窗口 |
| `Win+V` | 浮动/平铺切换 |
| `Win+W` | 当前列标签页显示 |
| `Win+R` | 循环列宽 |
| `Win+Shift+R` | 反向循环列宽 |
| `Win+C` | 居中当前列 |

### 工作区

| 快捷键 | 行动 |
| :--- | :--- |
| `Win+O` | Overview |
| `Win+1` … `Win+9` | 切换工作区 |
| `Win+Ctrl+1` … `Win+Ctrl+9` | 把当前列移到工作区 |
| `Win+PageDown` / `PageUp` | 下一个/上一个工作区 |
| `Win+Ctrl+PageDown` / `PageUp` | 移动列到下一个/上一个工作区 |
| `Win+滚轮` | 切换工作区 |
| `Win+Ctrl+滚轮` | 移动列到工作区 |

### 截图/退出

| 快捷键 | 行动 |
| :--- | :--- |
| `Print` | 区域截图 |
| `Ctrl+Print` | 全屏截图 |
| `Alt+Print` | 当前窗口截图 |
| `Win+Shift+Slash` | 快捷键帮助 |
| `Win+Escape` | 暂停/恢复 Niri 快捷键 |
| `Win+Shift+E` | 退出 Niri（确认） |

## 5. DMS

DMS 提供：

- 启动器
- 通知中心
- 控制中心
- 电源/锁屏
- 剪贴板
- 系统监控

检查 DMS：

```bash
pgrep -af dms
dms ipc call spotlight toggle
journalctl --user -b | grep -i -E 'niri|dms|quickshell'
```

如果 DMS 没启动，先在终端运行：

```bash
dms run
```

能启动说明包正常，再检查 Niri 的 `spawn-at-startup` 和会话环境。

## 6. 配置修改

实际配置文件：

```text
~/.config/niri/config.kdl
```

但它是 Home Manager 生成的。修改源文件：

```text
users/drinkto/niri.nix
```

然后：

```bash
niri validate -c ~/.config/niri/config.kdl
sudo nixos-rebuild switch --flake .#e490
```

Niri 通常会自动重载配置；没有生效时重新登录。

查看设备/窗口/工作区：

```bash
niri msg outputs
niri msg windows
niri msg workspaces
```

## 7. 输入与触摸板

Niri 直接读取 libinput，KDE/GNOME 的触摸板设置 **不会**自动作用于 Niri。  
输入设置在 `users/drinkto/niri.nix` 的 `input` 段：

```kdl
input {
    keyboard { xkb { layout "us" } numlock }
    touchpad { tap; natural-scroll; dwt; }
    mouse { accel-profile "adaptive"; }
}
```

如果误触或拖拽异常，可以先删除 `tap`，只使用物理点击；必要时调整
`accel-profile`。

## 8. 关闭 Niri

1. 注销；
2. SDDM 选择 GNOME；
3. 注释掉 `common/nixos/desktop.nix` 和 `users/drinkto/default.nix` 中的
   Niri/DMS 块；
4. 重新 build/switch。

Niri/DMS 的用户数据不会自动删除。

## 9. 故障排查

### 登录后黑屏/回 SDDM

```bash
journalctl --user -b | grep -i niri
niri validate -c ~/.config/niri/config.kdl
```

配置错误时从 TTY 修改 `users/drinkto/niri.nix`，或回 SDDM 选 GNOME。

### `Win+D` 没反应

```bash
pgrep -af dms
dms ipc call spotlight toggle
```

如果第二条命令能打开启动器，检查 Niri 配置是否被覆盖。

### 多桌面冲突

Niri 和 GNOME 可以同时安装，但一次只运行一个桌面。注销后再切换，不要在同一
用户会话里同时启动多个 compositor。

### DMS 依赖

Niri 的 `spawn-at-startup` 使用 DMS 包路径；如果未取消
`inputs.dms.homeModules.dank-material-shell` 和
`programs.dank-material-shell.enable`，Niri 配置会引用不到 DMS，构建或
启动会失败。
