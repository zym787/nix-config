# Niri + DMS 初学者指南

本文面向第一次使用 Niri 的人。Niri 不是传统的“窗口漂浮在桌面上”的窗口管理器，
而是一个 **可滚动的平铺窗口管理器（scrollable tiling compositor）**。第一次使用会觉得
操作逻辑和 KDE/GNOME 很不一样，但熟悉后很适合键盘操作和多窗口工作。

当前机器默认会话是：

```text
Niri + DankMaterialShell（上游已改名为 Dux Shell，CLI 仍叫 dms）
```

KDE Plasma、GNOME、Hyprland 和 DenialWM 也都注册到了 SDDM，可随时切换。

---

## 1. 登录与切换桌面

### 登录 Niri

注销后，在 SDDM 登录界面：

1. 点击用户名/密码输入框附近或右下角的 **会话菜单**；
2. 选择 **Niri**；
3. 输入密码登录。

默认会话已经设置为 Niri，直接登录通常就是 Niri + DMS。

### 切换到其他桌面

注销，回到 SDDM，在会话菜单选择：

| 会话 | 说明 |
| :--- | :--- |
| **Niri** | 默认；Niri + DMS，推荐日常使用 |
| **Plasma** | KDE Plasma，兼容性最好 |
| **GNOME** | GNOME 尝鲜 |
| **Hyprland** | 另一套平铺 Wayland 合成器 |
| **Denial** | Flutter 原生 Wayland 合成器；默认关闭，需手动开启 |
| **Steam** | 专用 gamescope + Steam Big Picture 游戏会话 |

也可以在终端运行：

```bash
desktop-sessions   # 列出系统中的桌面会话
desktop-switch     # 提示注销，随后在 SDDM 选择会话
```

**真正的“一键切换”发生在 SDDM 会话菜单**：注销后点一下目标会话即可，
不需要重新构建 NixOS。

Denial 默认关闭，因为首次启用可能需要构建 Flutter engine。想尝鲜时把
`common/nixos/desktop-sessions.nix` 的 `programs.denial.enable` 改为
`true` 后重新 switch；首次构建可能较久。

如果想改默认会话，编辑：

```nix
# common/nixos/desktop-sessions.nix
services.displayManager.defaultSession = "niri";
```

---

## 2. Niri 的核心概念

### 窗口是“列”

Niri 把窗口组织成横向排列的列：

```text
[ 终端 ] [ 浏览器 ] [ 编辑器 ]
```

- 新窗口通常出现在当前列右侧；
- 左右移动是在列之间移动；
- 上下移动是在同一列里的多个窗口之间移动；
- 窗口可以垂直堆叠在同一列；
- 通过滚动/切换焦点浏览工作区，而不是拖动窗口。

### 工作区是动态的

Niri 的工作区不是固定数量的虚拟桌面，而是按需创建/回收的。用
`Win+1` 到 `Win+9` 切换工作区；`Win+Ctrl+1` 到 `Win+Ctrl+9` 把当前列移动到
对应工作区。

### Mod 键

Niri 配置里的 `Mod` 在 TTY 会话中等于 **Super 键**，也就是 Windows 键。
本文写作 `Win`。

---

## 3. 默认快捷键

以下快捷键已经写入 `users/drinkto/niri.nix`。

### 启动应用

| 快捷键 | 功能 |
| :--- | :--- |
| `Win+Enter` | 启动 Ghostty |
| `Win+Shift+Enter` | 启动 Kitty |
| `Win+D` | 打开/关闭 DMS 启动器 |
| `Win+Space` | 同上（备用） |
| `Win+X` | DMS 电源菜单 |
| `Win+N` | DMS 通知中心 |
| `Win+Alt+V` | DMS 剪贴板 |
| `Super+Alt+L` | 锁屏 |

### 窗口

| 快捷键 | 功能 |
| :--- | :--- |
| `Win+Q` / `Alt+F4` | 关闭当前窗口 |
| `Win+Left` / `Win+H` | 聚焦左列 |
| `Win+Right` / `Win+L` | 聚焦右列 |
| `Win+Up` / `Win+K` | 聚焦上方窗口 |
| `Win+Down` / `Win+J` | 聚焦下方窗口 |
| `Win+Ctrl+方向键` | 移动当前列/窗口 |
| `Win+F` | 最大化当前列 |
| `Win+Shift+F` | 全屏当前窗口 |
| `Win+V` | 切换浮动/平铺 |
| `Win+W` | 当前列切换标签页显示 |
| `Win+R` | 循环列宽 |
| `Win+Shift+R` | 反向循环列宽 |
| `Win+C` | 居中当前列 |

### 工作区与总览

| 快捷键 | 功能 |
| :--- | :--- |
| `Win+O` | 打开/关闭 Overview（工作区总览） |
| `Win+1` … `Win+9` | 切换到工作区 |
| `Win+Ctrl+1` … `Win+Ctrl+9` | 把当前列移到对应工作区 |
| `Win+PageDown` / `Win+PageUp` | 下一个/上一个工作区 |
| `Win+Ctrl+PageDown` / `PageUp` | 把列移到下一个/上一个工作区 |
| `Win+滚轮` | 切换工作区 |
| `Win+Ctrl+滚轮` | 移动列到工作区 |

### 截图和其他

| 快捷键 | 功能 |
| :--- | :--- |
| `Print` | 区域截图 |
| `Ctrl+Print` | 整个屏幕 |
| `Alt+Print` | 当前窗口 |
| `Win+Shift+Slash` | 显示 Niri 快捷键帮助 |
| `Win+Escape` | 临时停止/恢复 Niri 处理快捷键 |
| `Win+Shift+E` | 退出 Niri（会确认） |

> `Win+Shift+E` 和电源菜单都可以退出会话。不要用强制结束 niri 的方式退出，
> 否则 DMS、剪贴板和 systemd 用户服务可能残留。

---

## 4. DMS（DankMaterialShell / Dux Shell）

DMS 是一个基于 Quickshell 的完整桌面外壳，替代传统 waybar、通知守护进程、
启动器、锁屏、剪贴板等组件。你会看到：

- 顶部/屏幕边缘的 DMS 面板；
- 启动器（Spotlight）；
- 通知中心；
- 控制中心（网络、蓝牙、音量、亮度）；
- 锁屏/电源菜单；
- 剪贴板、系统监控等小工具。

DMS 由 Niri 的 `spawn-at-startup` 启动。启动命令在：

```text
users/drinkto/niri.nix
```

如果 DMS 没有出现，先在终端运行：

```bash
dms run
```

如果终端能启动，说明包没问题，只是 Niri 启动项/DMS 进程异常；检查：

```bash
pgrep -af dms
journalctl --user -b | grep -i -E 'dms|quickshell'
```

DMS 的配置由 Home Manager 管理：

```text
~/.config/dms/settings.json
```

---

## 5. 配置文件在哪里

Niri 配置由 Home Manager 生成到：

```text
~/.config/niri/config.kdl
```

**不要长期直接编辑这个文件**，因为下一次 `nixos-rebuild switch` 会覆盖它。
请修改仓库中的：

```text
users/drinkto/niri.nix
```

然后执行：

```bash
cd ~/Documents/nixos
sudo nixos-rebuild switch --flake .#e490
```

Niri 通常会热加载配置；如果没有生效，退出 Niri 重新登录。配置语法错误会
导致 Niri 启动失败，建议先验证：

```bash
niri validate -c ~/.config/niri/config.kdl
```

查看输出和显示器：

```bash
niri msg outputs
niri msg windows
niri msg workspaces
```

---

## 6. 触摸板、键盘和输入法

Niri 自己读取 libinput，**KDE 系统设置里的触摸板设置不会自动作用于 Niri**。
当前 Niri 输入配置在 `users/drinkto/niri.nix` 的 `input` 段：

```kdl
input {
    keyboard {
        xkb { layout "us" }
        numlock
    }
    touchpad {
        tap
        natural-scroll
        dwt
    }
    mouse {
        accel-profile "adaptive"
    }
}
```

- `tap`：轻触点击
- `natural-scroll`：自然滚动
- `dwt`：打字时禁用触摸板
- 如果误触/拖拽，可以删除 `tap`，只用物理点击
- 需要传统点击区域时，先检查当前 Niri 版本是否支持 `click-method`，不支持就
  不要强行添加
- 修改后建议 `niri validate` 再重新登录

输入法仍是系统的 fcitx5 + Rime，和桌面会话无关。

---

## 7. 终端与 zsh

Ghostty 和 Kitty 都已安装：

```bash
ghostty
kitty
```

系统用户 shell 已设置为 zsh；Home Manager 负责 `.zshrc`、oh-my-zsh、
插件和 starship 提示符：

- oh-my-zsh 插件：`git`、`sudo`、`extract`、`colored-man-pages`、`z`、
  `history-substring-search`
- 自动建议：zsh-autosuggestions
- 语法高亮：zsh-syntax-highlighting
- 提示符：starship

检查：

```bash
echo $SHELL
getent passwd drinkto
```

如果登录后仍是 bash，注销重新登录即可；NixOS 的系统用户 shell 已修改。

常用别名：

```bash
ll      # eza -l
la      # eza -la
lt      # eza --tree
cat     # bat
nrs     # nixos-rebuild switch
nrb     # nixos-rebuild build
```

---

## 8. 初次使用建议

1. 登录 Niri，等待 DMS 面板出现。
2. `Win+Enter` 打开 Ghostty。
3. `Win+D` 打开启动器，搜索并启动浏览器。
4. 再开一个终端，用 `Win+Right` 切到右边列。
5. `Win+O` 查看 Overview。
6. `Win+2` 切到工作区 2，再打开应用。
7. `Win+Ctrl+1` 把当前列送回工作区 1，体验移动工作区。
8. `Win+X` 打开 DMS 电源菜单，注销并切回 KDE 对比。

Niri 的核心不是“拖动窗口”，而是“用键盘移动列、切换工作区”。
前 30 分钟不习惯是正常的。

---

## 9. 常见问题

### 登录后黑屏 / 回到 SDDM

在 SDDM 按 `Ctrl+Alt+F2` 进入 TTY，登录后查看：

```bash
journalctl --user -b | grep -i niri
niri validate -c ~/.config/niri/config.kdl
```

如果配置错误，修正 `users/drinkto/niri.nix` 后重新 switch；也可以先在 SDDM
选择 Plasma 登录。

### `Win+D` 没反应

```bash
pgrep -af dms
dms ipc call spotlight toggle
```

如果第二条命令能打开启动器，说明 DMS 正常，检查 Niri 配置键位是否被覆盖。
如果 `dms` 命令不存在，确认 Home Manager 配置成功并重新登录。

### Niri 面板/窗口没有边框

这是 Niri 的正常设计；DMS 负责面板。窗口边框和焦点环在 `layout` 段配置。

### 触摸板仍然不对劲

先确认当前是 Niri 会话，并修改 `input.touchpad`，不要期待 KDE 的鼠标设置
生效。必要时用 `libinput debug-events`/`evtest` 判断是硬件还是配置问题。

### 多桌面会不会互相影响

它们共享系统服务、输入设备和用户配置，但各自有独立会话。一次只运行一个
桌面；注销后再切换。GNOME 和 KDE 同时启用时，SSH askpass 等冲突已在
`desktop-sessions.nix` 中显式处理。

### Denial 启动失败

Denial 是实验性 Flutter 合成器，优先使用官方二进制缓存；如果失败，回到
SDDM 选择 Niri 或 KDE。不要为尝鲜会话影响主会话。

---

## 10. 回滚与恢复

所有桌面会话都不需要单独分区或双系统。切回 KDE：

1. 注销；
2. SDDM 会话菜单选择 Plasma；
3. 登录。

如果 Niri 配置导致无法登录：

1. TTY 登录；
2. 编辑仓库 `users/drinkto/niri.nix`；
3. `sudo nixos-rebuild switch --flake .#e490`；
4. 或选择旧的 NixOS generation 回滚。

NixOS 代际回滚不会删除用户数据，但会恢复当时的系统和 Home Manager 配置。

---

## 11. 常用命令速查

```bash
# 查看会话
desktop-sessions

# 注销到 SDDM 会话菜单
desktop-switch

# 验证 Niri 配置
niri validate -c ~/.config/niri/config.kdl

# 查看输出/窗口/工作区
niri msg outputs
niri msg windows
niri msg workspaces

# DMS
dms run
dms ipc call spotlight toggle
dms ipc call powermenu toggle

# 当前会话
echo "$XDG_SESSION_TYPE"
echo "$XDG_CURRENT_DESKTOP"

# 系统日志
journalctl --user -b | grep -i -E 'niri|dms'
```

更多 Niri 配置和键位可参考：

- Niri 官方文档：<https://niri-wm.github.io/niri/>
- Niri 配置示例：<https://github.com/YaLTeR/niri/blob/main/resources/default-config.kdl>
- DMS / Dux Shell：<https://github.com/duxlabs-dev/dux-shell>
