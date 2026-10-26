# 配置架构

> 本文档面向人类和 AI agent。修改配置前必须先读本文档。

## 1. 设计目标

- 支持多设备（桌面 PC、笔记本、SBC）和多用户（同一设备可能有日常、开发、娱乐多个账号）
- 新手可在 10 分钟内理解目录结构
- 单文件不超过 100 行，每份文件只负责一件事
- 加设备、加用户时只新增文件，不复制粘贴
- 系统级与用户级物理隔离

> **当前实例**：`hosts/e490` + `users/drinkto`。下文示例中的 `pc-main`、`alice` 等都是
> 多设备/多用户场景的占位名，实际替换为 `e490`、`drinkto`。

## 2. 目录结构

```
.
├── flake.nix                     # 仅：inputs / outputs 发现 / nixConfig / formatter
├── flake.lock                    # 由 nix flake update 生成，不手动编辑
├── settings/
│   ├── default.nix               # 全局变量：stateVersion、镜像源、insecure 包、packages 入口
│   └── packages.nix              # 包分组：system / core / desktop / dev / media / utils
├── hosts/                        # 按“机器”组织
│   └── e490/                     # 当前唯一主机
│       ├── default.nix           # 系统 imports + 启用哪些用户
│       ├── hardware-configuration.nix
│       └── variables.nix         # 主机名
│   # 计划中：laptop-work/、sbc-home/ 等按同样结构新增
├── users/                        # 按“人”组织，与 hosts 正交
│   └── drinkto/                  # 当前唯一用户
│       └── default.nix
│   # 计划中：drinkto-dev/、sega/ 等
├── common/
│   ├── nixos/                    # 所有主机共享的系统级配置
│   │   ├── core.nix              # nix.settings / nixpkgs.config / gc / boot / locale
│   │   ├── network.nix
│   │   ├── proxy.nix             # Clash Verge Rev（Mihomo / TUN）
│   │   ├── bluetooth.nix         # BlueZ + 开机上电
│   │   ├── desktop.nix           # Wayland/XWayland / SDDM / Plasma / libinput
│   │   ├── graphics.nix          # Intel/AMD GPU、32-bit Vulkan、switcheroo
│   │   ├── gaming.nix            # Steam / GameMode / MangoHud / gamescope
│   │   ├── audio.nix             # PipeWire
│   │   ├── fonts.nix
│   │   ├── ime.nix               # fcitx5
│   │   ├── printing.nix          # CUPS + Brother 驱动
│   │   ├── performance.nix       # zram / sysctl / fstrim（E490 不用 thermald）
│   │   └── systemd.nix           # fwupd；不覆盖 kde-baloo
│   └── home/                     # 所有用户共享的用户级基础
│       ├── default.nix           # imports 下列模块
│       ├── git.nix
│       └── shell.nix             # starship
├── modules/                      # 可选；当前未创建，需要时再建
│   ├── nixos/
│   └── home-manager/
└── wallpapers/
```

## 3. 分层职责

| 层 | 位置 | 放什么 | 不放什么 |
| :--- | :--- | :--- | :--- |
| 入口 | `flake.nix` | inputs、outputs 发现、`nixConfig`、`formatter` | 任何具体 `services.*`、包列表 |
| 变量 | `settings/` | `stateVersion`、镜像源、insecure 包、包分组 | 直接写 `services.xxx = ...` |
| 主机 | `hosts/<hostname>/` | `hardware-configuration.nix`、主机变量、启用哪些用户 | 通用桌面/音频/字体配置 |
| 用户 | `users/<username>/` | 个人包、个人 dotfiles、个人变量引用 | 系统级服务、其他用户的配置 |
| 共享系统 | `common/nixos/` | 所有主机共享的系统服务 | 主机特有硬件、可选软件 |
| 共享用户 | `common/home/` | 所有用户共享的用户基础 | 个人化内容 |
| 可选模块 | `modules/` | Steam、代理、编辑器等按需启用的功能；当前未创建 | 基础系统必备配置 |

## 4. 命名规则

### 4.1 目录与文件

| 名称 | 含义 | 禁止使用的词 |
| :--- | :--- | :--- |
| `hosts/` | 物理/虚拟机器 | `machines`、`nodes`、`systems` |
| `users/` | 用户账户 | `people`、`accounts` |
| `common/` | 共享配置 | `shared`、`base`、`core` |
| `modules/` | 可复用模块 | `features`、`aspects`、`parts` |
| `settings/` | 变量 | `vars`、`facts`、`config` |
| `nixos/`、`home/` | 系统级/用户级子目录 | `system`、`user`（单数易混淆） |

### 4.2 主机名

- 使用描述性名称：`e490`（当前）、`laptop-work`、`sbc-home` 等；示例中的 `pc-main` 是占位名
- **禁止**：`nixos`、`default`、`localhost`、`test`、`tmp`
- 主机名是 DNS 标签，只能包含字母、数字和连字符

### 4.3 用户名

- 使用描述性名称：`alice`、`bob`、`alice-dev`
- 同一台设备上的多个账号用后缀区分用途：`alice`（日常）、`alice-dev`（嵌入式开发）、`alice-game`（娱乐）

## 5. 多设备多用户策略

### 5.1 核心原则

**`hosts/` 管机器，`users/` 管人，两者平级且正交。**

- 同一用户可以出现在多台主机上
- 同一主机可以有多个用户
- 主机入口负责把“机器”和“人”组合起来

### 5.2 主机入口示例

`hosts/pc-main/default.nix`：

```nix
{ settings, ... }:
let hostVars = import ./variables.nix;
in {
  imports = [
    ./hardware-configuration.nix
    ../../common/nixos/core.nix
    ../../common/nixos/network.nix
    ../../common/nixos/desktop.nix
    ../../common/nixos/audio.nix
    ../../common/nixos/fonts.nix
    ../../common/nixos/ime.nix
    ../../common/nixos/printing.nix
    ../../common/nixos/systemd.nix
  ];

  networking.hostName = hostVars.hostName;
  system.stateVersion = settings.stateVersion;

  # 系统级用户必须存在，Home Manager 才能挂载
  users.users.alice = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
  };
  users.users.alice-dev = {
    isNormalUser = true;
    extraGroups = [ "dialout" "plugdev" ];
  };

  # 该主机上启用哪些用户的 Home Manager 配置
  home-manager.users.alice = {
    imports = [ ../../users/alice ];
  };
  home-manager.users.alice-dev = {
    imports = [ ../../users/alice-dev ];
  };
}
```

### 5.3 用户配置示例

`users/alice/default.nix`：

```nix
{ settings, pkgs, ... }:
{
  imports = [ ../../common/home ];

  home = {
    username = "alice";
    homeDirectory = "/home/alice";
    stateVersion = settings.stateVersion;
  };

  home.packages = with pkgs; [ obsidian telegram-desktop ];
  programs.git.settings.user.email = "alice@example.com";
}
```

`common/home/default.nix`：

```nix
{ ... }:
{
  imports = [
    ./git.nix
    ./shell.nix
  ];
  programs.home-manager.enable = true;
}
```

### 5.4 同一用户多设备差异

不要复制用户配置。在主机入口做局部覆盖：

```nix
# hosts/laptop-work/default.nix
home-manager.users.alice = {
  imports = [ ../../users/alice ];
  home.packages = [ pkgs.laptop-battery-tool ];
};
```

### 5.5 单设备多账号

不同账号使用不同 `users/<name>/` 目录，主机入口分别启用：

```nix
# hosts/pc-main/default.nix
users.users.alice = { isNormalUser = true; extraGroups = [ "wheel" ]; };
users.users.alice-dev = { isNormalUser = true; extraGroups = [ "dialout" "plugdev" ]; };
users.users.alice-game = { isNormalUser = true; extraGroups = [ "gamemode" ]; };

home-manager.users.alice = { imports = [ ../../users/alice ]; };
home-manager.users.alice-dev = {
  imports = [ ../../users/alice-dev ];   # 含 gcc-arm-embedded、openocd、picocom
};
home-manager.users.alice-game = {
  imports = [ ../../users/alice-game ];  # 含 steam、gamemode
};
```

## 6. 编码规则

### R1. 禁止硬编码 `/nix/store` 路径

- ❌ `"/nix/store/abc...-baloo-6.31.0/libexec/kf6/baloo_file"`
- ✅ `"${pkgs.kdePackages.baloo}/libexec/kf6/baloo_file"`

### R2. 文件只保留生效配置和解释性注释

- 被替换的旧写法、试过没用的配置 → 删除，交给 `git log`
- ❌ 大段 `# programs.xxx = { ... };` 注释块
- ✅ `# 用 PipeWire 替代 PulseAudio，避免音频冲突`

### R3. 选项类型必须匹配文档

- `experimental-features` 是 `list of string` → `[ "nix-command" "flakes" ]`
- 不确定时查 `https://search.nixos.org/options`

### R4. 系统级 vs 用户级选对层

- `services.*`、`users.*`、`boot.*` → 系统级（`hosts/` 或 `common/nixos/`）
- `home.packages`、`programs.git`、`xdg.*` → 用户级（`users/` 或 `common/home/`）
- 报错 `The option ... does not exist` 时先确认层级

### R5. 自启动用声明式管理

- ❌ 在 GUI 里点“开机自启”（会写 `~/.config/autostart/*.desktop`）
- ✅ 优先用模块的 `autoStart` 选项；没有则用 `xdg.configFile."autostart/xxx.desktop"`

### R6. `permittedInsecurePackages` 必须带注释

```nix
permittedInsecurePackages = [
  # Cherry Studio 依赖的 Electron，等待上游更新
  "electron-40.10.5"
  # Codex 相关工具依赖
  "pnpm-10.29.2"
];
```

软件卸载后，同步删除对应条目。

### R7. 每次只改一件事，先 build 再 switch

```bash
sudo nixos-rebuild build --flake .#e490
sudo nixos-rebuild switch --flake .#e490
```

### R8. 用 git 管理，小步提交

```bash
git add -A && git commit -m "feat(fonts): 添加 Maple Mono NF CN"
```

提交信息格式：`<type>(<scope>): <subject>`，type 用 `feat` / `fix` / `chore` / `refactor` / `docs`。

### R9. 删除软件时的清理清单

```bash
# 1. 配置里搜引用
grep -rn "软件名" ~/Documents/nixos --include="*.nix"
# 2. 用户级 autostart 残留
ls ~/.config/autostart/ | grep -i 软件名
# 3. 用户数据（按需）
ls ~/.local/share/ ~/.config/ | grep -i 软件名
```

### R10. 每 1–2 个月做一次配置体检

```bash
# 搜整段注释
grep -rn "^\s*#.*=.*{" --include="*.nix"
# 搜硬编码路径
grep -rn "/nix/store/" --include="*.nix"
# 清理旧代际
sudo nix-collect-garbage --delete-older-than 14d
```

## 7. 更新与回滚

```bash
# 更新
sudo nix flake update
sudo nixos-rebuild build --flake .#e490
sudo nixos-rebuild switch --flake .#e490
git add flake.lock && git commit -m "chore: flake update $(date +%F)"

# 回滚
sudo nixos-rebuild switch --rollback
```

遇到 `Refusing to evaluate package ...` → 按提示追加到 `permittedInsecurePackages`。
遇到 `Failed to connect` / `i/o timeout` → 检查 `substituters` 或代理。