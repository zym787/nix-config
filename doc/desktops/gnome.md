# GNOME

GNOME 是**当前默认桌面**，显示管理器使用 GNOME 官方配套的 **GDM**。

## 当前状态

- 桌面：GNOME
- 显示管理器：GDM
- 默认 Session：
  ```nix
  services.displayManager.defaultSession = "gnome";
  ```
- KDE Plasma 已注释，默认不安装/不启用
- Steam 是另一个常驻的游戏会话

配置位置：`common/nixos/desktop.nix`：

```nix
services.desktopManager.gnome.enable = true;
services.displayManager.gdm.enable = true;
services.displayManager.sddm.enable = false;
services.displayManager.defaultSession = "gnome";
```

## 设计说明

- **GDM** 是 GNOME 官方显示管理器，登录界面由 GNOME Shell 提供；
- GDM 默认使用 Wayland greeter，登录后的 GNOME 会话也是 Wayland；
- `services.xserver.enable = true` 仍然保留，用于 XWayland 和 X11 兼容应用；
- GNOME 的 XDG Portal、GNOME Keyring、GNOME Settings Daemon 由 NixOS
  模块自动安装；
- GNOME 输入法仍使用系统的 fcitx5/Rime，不使用 IBus 作为默认输入法。

## 光标/图标主题（灰色方块问题）

如果鼠标指针显示为灰色方块、没有箭头，通常是光标主题不存在导致的。
从 KDE 切到 GNOME 后，用户目录里可能还保留：

```text
dconf: org.gnome.desktop.interface cursor-theme = 'breeze_cursors'
dconf: org.gnome.desktop.interface icon-theme   = 'breeze-dark'
```

KDE 被注释后，`breeze_cursors` / `breeze-dark` 不再出现在 GNOME 会话的
`XDG_DATA_DIRS` 中，GTK/GNOME 找不到光标文件，就会显示灰色方块或空指针。

当前修复配置在 `common/home/gnome.nix`：

```nix
home.pointerCursor = {
  enable = true;
  name = "Adwaita";
  package = pkgs.adwaita-icon-theme;
  size = 24;
  gtk.enable = true;
  x11.enable = true;
};

gtk = {
  enable = true;
  font = {
    name = "Fira Code";
    size = 10;
  };
  iconTheme = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
  };
  colorScheme = "dark";
};
```

Home Manager 会同时写入：

- `~/.icons/Adwaita` 和 `~/.icons/default/index.theme`
- `~/.config/gtk-3.0/settings.ini`、`~/.config/gtk-4.0/settings.ini`
- dconf 的 `cursor-theme`、`cursor-size`、`icon-theme`

### 立即恢复（不重新登录）

当前会话可以直接执行：

```bash
gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita'
gsettings set org.gnome.desktop.interface cursor-size 24
gsettings set org.gnome.desktop.interface icon-theme 'Adwaita'
```

部分 GTK/Flatpak 应用需要重启，必要时注销再登录。

检查：

```bash
gsettings get org.gnome.desktop.interface cursor-theme
gsettings get org.gnome.desktop.interface cursor-size
gsettings get org.gnome.desktop.interface icon-theme
ls -l ~/.icons/Adwaita/cursors/default
```

如果仍然异常，检查是否还有其他配置覆盖：

```bash
dconf read /org/gnome/desktop/interface/cursor-theme
grep -n -i cursor ~/.config/gtk-3.0/settings.ini ~/.config/gtk-4.0/settings.ini
journalctl --user -b | grep -i -E 'cursor|gnome-shell'
```

不要继续把光标主题设成未安装的 Breeze 主题；如果确实想用 Breeze，
需要把对应的 KDE 包加入 `home.packages`，而不是只改 gsettings。

## GNOME Shell 扩展

当前扩展由 Home Manager 的 `programs.gnome-shell` 管理，配置在
`common/home/gnome.nix`：

```nix
programs.gnome-shell = {
  enable = true;
  extensions = [
    { package = pkgs.gnome50Extensions."appindicatorsupport@rgcjonas.gmail.com"; }
    { package = pkgs.gnome50Extensions."kimpanel@kde.org"; }
  ];
};
```

> 这里使用 `gnome50Extensions` 而不是 `gnomeExtensions`：`gnomeExtensions`
> 是 GNOME 49/50/51 的联合集，`kimpanel` 会被 GNOME 51 的 v94 覆盖，而 v94
> 只声明支持 Shell 51。GNOME 50 对应的 kimpanel 版本是 v92。

Home Manager 会：

- 把扩展包安装到用户 profile；
- 写入 dconf：
  ```text
  org.gnome.shell.disable-user-extensions = false
  org.gnome.shell.enabled-extensions = [
    appindicatorsupport@rgcjonas.gmail.com
    kimpanel@kde.org
  ]
  ```

因此**不要再用 Extensions 应用手工启用/禁用这两个扩展**：下次
Home Manager activation 会按 Nix 列表重写 `enabled-extensions`。要新增扩展，
在列表里加对应包，然后 rebuild；先确认该包的 `metadata.json` 里
`shell-version` 包含 `50`，nixpkgs 没收录的扩展需要自行打包。

> NixOS 本身可以通过 `environment.systemPackages` 安装
> `pkgs.gnomeExtensions.*`，但 NixOS 文档也说明它不能完全声明式地启用扩展；
> Home Manager 的 `programs.gnome-shell.extensions` 同时负责安装和启用。

### Input Method Panel（kimpanel）

原来的 `kimpanel@kde.org` 是手工放在
`~/.local/share/gnome-shell/extensions/` 的。现在改用 nixpkgs 的
`pkgs.gnome50Extensions."kimpanel@kde.org"`（版本 92，兼容 GNOME Shell 50）。

`common/home/gnome.nix` 里有一个 activation 步骤，会在首次 switch 时把旧目录
改名为 `kimpanel@kde.org.manual-backup.<时间戳>`，避免用户目录版本遮蔽 Nix
版本。切换并重新登录后检查：

```bash
gnome-extensions list --enabled
gsettings get org.gnome.shell enabled-extensions
```

应该同时看到：

```text
appindicatorsupport@rgcjonas.gmail.com
kimpanel@kde.org
```

### 状态栏显示后台应用图标

GNOME 顶栏默认不显示系统托盘/后台应用图标。当前已通过
**AppIndicator and KStatusNotifierItem Support** 扩展恢复：

- Clash Verge、Steam、Telegram 等使用 StatusNotifierItem/AppIndicator 的应用
  会出现在顶栏右侧；
- 旧式 tray 图标也由该扩展兼容；
- 切换/重新登录后如果图标没出现，先确认应用本身有托盘功能，再到
  **Extensions → AppIndicator** 的设置里检查；
- 如果只是想要“运行中应用的 Dock 图标”，那是 Dash to Dock/Ubuntu Dock 的
  功能，不是 AppIndicator。

## 切换/关闭

如果要切回 KDE：

1. 注释 `services.desktopManager.gnome.enable`；
2. 取消 `services.desktopManager.plasma6.enable` 注释；
3. 把 `defaultSession` 改为 `"plasma"`；
4. 保持 GDM，或按 `doc/desktops/kde.md` 的说明切回 SDDM；
5. build/switch 后注销，在 GDM 选择 Plasma。

如果只是临时使用 KDE，不要同时启用两个桌面管理器，以免 askpass/portal
冲突。

## 常见问题

### 登录后回到 GDM

查看日志：

```bash
journalctl -b -u gdm --no-pager
journalctl -b -u display-manager --no-pager
journalctl --user -b | grep -i -E 'gnome|gdm|portal'
```

### 无法登录时

在 GDM 选择 **Steam**（如果只是想进入可用会话），或按 `Ctrl+Alt+F2`
进入 TTY 修复；如果已经启用了 KDE，也可以选择 Plasma。

### 文件选择器/截图异常

确认 XDG Portal：

```bash
systemctl --user status xdg-desktop-portal
```

GNOME 的 portal 由桌面模块提供，不需要手工安装。
