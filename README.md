# NixOS 配置

[![flake-check](https://github.com/zym787/nix-config/actions/workflows/flake_evaltests.yml/badge.svg?branch=main)](https://github.com/zym787/nix-config/actions/workflows/flake_evaltests.yml)
[![last commit](https://img.shields.io/github/last-commit/zym787/nix-config?label=last%20commit)](https://github.com/zym787/nix-config/commits/main)
[![NixOS](https://img.shields.io/badge/NixOS-unstable-5277C3?logo=nixos&logoColor=white)](https://nixos.org)
[![platform](https://img.shields.io/badge/platform-x86__64--linux-blue)](#支持平台)
[![built with Nix](https://img.shields.io/static/v1?logo=nixos&logoColor=white&label=&message=Built%20with%20Nix&color=41439a)](https://builtwithnix.org)

基于 Flake + Home Manager 的多设备多用户 NixOS 配置。

## 项目状态

| 项目 | 状态 |
| :--- | :--- |
| CI | flake 评估 + alejandra 格式检查（不部署设备） |
| 最近更新 | 见顶部 `last commit` 徽章 |
| 系统 | NixOS `nixos-unstable` |
| 平台 | `x86_64-linux` |
| 桌面 | KDE Plasma 6 + SDDM + Wayland（XWayland 兼容层） |
| 配置方式 | Flake + Home Manager（system module 集成） |

## 支持平台

当前只支持 **`x86_64-linux`**。`aarch64-linux`、Darwin 尚未配置；
新增平台需要在 `flake.nix` 扩展 `system`，并补对应 host/module。

## 设备

目前只启用1台主机 `e490`

| 是否启用 | 主机名 | 类型 | 说明 |
| :--- | :--- | :--- | :--- |
| 启用 | `e490` | 笔记本（laptop-work） | 主力工作机 |
| 未配置 | `a200i-dk` | SBC（sbc-home） | 推理服务器（计划） |
| 未配置 | `bikini` | 桌面 PC（pc-main） | 桌面机（计划） |

> 新增设备时按 `doc/OPTIMIZATION.md` P2-4 操作：复制 `hosts/e490/`。

## 用户

目前只启用1个用户 `drinkto`

| 是否启用 | 用户名 | 说明 |
| :--- | :--- | :--- |
| 启用 | `drinkto` | 日常使用 |
| 未配置 | `drinkto-dev` | 嵌入式开发专用账号（计划） |
| 未配置 | `sega` | 家庭成员（计划） |

> 同一设备上的多个账号用后缀区分用途，如 `drinkto` / `drinkto-dev` / `drinkto-game`。
> 新增用户时按 `doc/OPTIMIZATION.md` P2-4 操作：复制 `users/drinkto/`。

## 技术栈

| 项目 | 值 |
| :--- | :--- |
| 系统通道 | `nixos-unstable`（清华 Git 镜像） |
| 桌面环境 | KDE Plasma 6 + SDDM + Wayland（XWayland） |
| 音频 | PipeWire（PulseAudio 兼容层） |
| 输入法 | fcitx5 + Rime（雾凇拼音 rime-ice），启用 Wayland 前端 |
| 引导 | systemd-boot（保留 10 个代际） |
| 文件系统 | Btrfs（`root` / `home` / `nix` 子卷，zstd 压缩） |
| 打印 | CUPS + brlaser（Brother DCP-7057） |
| 蓝牙 | BlueZ + BlueDevil（Realtek RTL8822BE） |
| 代理 | Clash Verge Rev（Mihomo，TUN + 系统服务） |
| GPU | Intel UHD 620 + AMD Radeon 540X/550X（amdgpu + Mesa RADV） |
| 游戏 | Steam + GameMode + MangoHud + gamescope（按需） |
| 性能 | zram + sysctl 调优 + fstrim；PPD 默认 balanced（E490 不使用 thermald） |

## 代理

默认使用 Clash Verge Rev（Mihomo 内核），已启用：

- 系统服务模式：`systemctl status clash-verge`
- TUN 透明代理：需要特权，模块已处理 capabilities 和 reverse path
- 登录后自动启动：首次打开 GUI 后导入订阅/节点

```bash
clash-verge                 # 打开 GUI
systemctl status clash-verge --no-pager
```

如果 Clash Verge 右上角最小化/最大化/关闭按钮点不动：这是 Tauri 在
Wayland 下使用系统标题栏的上游问题。打开 **设置 → 界面设置**，关闭
**“优先使用系统标题栏”**，改用应用自绘标题栏即可；这不是 X11 通病。

配置和订阅通常保存在 `~/.local/share/io.github.clash-verge-rev.clash-verge-rev/`。
建议关闭 Clash Verge 的 **DNS 覆写**，让机场订阅自带的 DNS 策略生效；
否则全局 DNS 可能覆盖 `nameserver-policy`，导致节点域名解析失败。
如果更想要无 GUI、eBPF 透明代理，可改用 `services.dae`（需要自己维护 `.dae` 配置）。

Steam 下载也会被 TUN 接管。当前在订阅的规则编辑器里把 Steam
下载 CDN（`steamcontent.com`、`pphimalayanrt.com`、`clngaa.com` 等）
设为 `DIRECT`，避免下载走代理节点；商店/社区仍按订阅规则走代理。
如果仍然慢，在 Steam **设置 → 下载 → 下载区域**换一个就近区域再试。

## 游戏与独显

硬件是双显卡：

- Intel UHD 620：主显示/桌面合成
- AMD Radeon 540X/550X（Lexa PRO，2GB）：独显

AMD 使用内核 `amdgpu` + Mesa RADV，不需要闭源驱动。Steam/Proton
需要 32-bit 图形库，已在 `common/nixos/graphics.nix` 开启。
`services.switcherooControl` 让 KDE 可以提供“使用独立显卡运行”。

### 独显启动方式

- KDE 应用菜单右键 → “使用独立显卡运行”
- 或命令行：

```bash
switcherooctl list
switcherooctl launch -g 1 <程序>
```

Steam 游戏可在 **属性 → 启动选项** 使用：

```bash
# OpenGL 游戏走独显
DRI_PRIME=1 gamemoderun mangohud %command%

# Vulkan 游戏强制 AMD 独显（vendor:device）
MESA_VK_DEVICE_SELECT=1002:699f gamemoderun mangohud %command%
```

用 `vulkaninfo --summary` 可以确认 AMD 设备是否可见。

如果游戏启动后白屏/黑屏，先在 Plasma 里用上面的启动项测试，
并在 Steam 属性里打开 `PROTON_LOG=1`，日志会写到
`~/steam-<appid>.log`。这台机器只有 2GB 显存，像
*Little Nightmares Enhanced Edition* 这类新游戏不要开 Ultra/光追：
改用 1280x720、Low、关闭 RT/FSR，并确认使用的是 AMD 独显。
低于游戏推荐配置时，即使能启动也可能严重掉帧或显存不足。

### Steam 与 gamescope

已启用 NixOS 自带的 **Steam gamescope 会话**：

- SDDM 登录界面会多一个 “Steam” 会话
- 一键进入 gamescope + Steam Big Picture，适合专门玩游戏
- 日常仍选择 Plasma 会话，工作和游戏环境分离
- 普通桌面里也可以按需使用 `gamescope`：

```bash
gamescope -W 1920 -H 1080 -f -r 60 -- gamemoderun mangohud %command%
```

首次使用建议先在 **Plasma 会话**里完成 Steam 登录、Steam Play/Proton、
游戏下载、手柄和界面设置；这些数据与 Steam 会话共享。

Steam 桌面版 Big Picture 没有 Steam Deck 的“性能”菜单。本配置在专用
会话里设置 `MANGOHUD=1`，进入游戏后按 `Shift_R+F12` 切换 MangoHud
帧率/CPU/GPU 覆盖层；也可以在单个游戏的启动项里加 `MANGOHUD=1`。

专用会话没有桌面环境，所以 Big Picture 的“退出到桌面/切换到桌面”
不会回到 Plasma，只会留下黑屏。请使用 **Steam 按钮 → 电源 → 退出
Steam**；如果只退出了游戏或界面卡住，按 `Ctrl+Alt+F2` 到 TTY，
执行 `loginctl list-sessions` 和 `loginctl terminate-session <id>`。

Wi-Fi 要在 Steam 会话里自动连接，NetworkManager 的 PSK 必须是
**系统级存储**（`psk-flags=0`），不能只由 KDE Wallet 管理：

```bash
nmcli -g 802-11-wireless-security.psk-flags connection show '<Wi-Fi 名称>'
# 如果是 1：
nmcli connection modify '<Wi-Fi 名称>' wifi-sec.psk-flags 0
nmcli connection up '<Wi-Fi 名称>'
```

退出 Steam 会话：Big Picture 里 **Steam 按钮 → 电源 → 退出**。
如果界面没有退出项或卡死，按 `Ctrl+Alt+F2` 切到 TTY，登录后执行：

```bash
loginctl list-sessions
loginctl terminate-session <session-id>
```

然后回 SDDM 选 Plasma。如果不想保留专用会话，把
`common/nixos/gaming.nix` 的 `gamescopeSession.enable` 改为 `false`。

专用会话更适合电视/手柄/Steam Deck 式体验；日常办公仍用 Plasma。

## 蓝牙与性能

```bash
# 蓝牙状态 / 配对
systemctl status bluetooth --no-pager
bluetoothctl
# KDE 托盘里也可以直接用 BlueDevil 配对

# 查看 zram 和 TRIM
zramctl
systemctl status fstrim.timer --no-pager

# 电源配置（默认 balanced）
powerprofilesctl get
powerprofilesctl set performance   # 需要高性能时
powerprofilesctl set balanced      # 恢复
```

性能调优在 `common/nixos/performance.nix`：zram 压缩交换、`vm.swappiness=10`、
`vm.vfs_cache_pressure=50`、SSD 定期 TRIM。没有强制 `performance` governor，
避免笔记本发热和续航变差。

E490 上 **不启用 thermald**：该机的 `thinkpad_acpi dytc_lapmode` 会让 thermald
报 `Unsupported cpu model or platform` 并退出；温度/频率由 `intel_pstate` +
`power-profiles-daemon` 管理。

## 快速开始

```bash
# 首次构建/调试配置（仅构建，不切换）
sudo nixos-rebuild build --flake .#e490

# 切换
sudo nixos-rebuild switch --flake .#e490
```

## 常用命令

### 构建与切换

```bash
sudo nixos-rebuild build --flake .#e490       # 只构建，验证配置
sudo nixos-rebuild switch --flake .#e490      # 构建并切换
sudo nixos-rebuild switch --rollback          # 回滚到上一个代际
```

### 更新

```bash
sudo nix flake update                 # 更新所有输入
sudo nix flake update nixpkgs         # 只更新 nixpkgs
sudo nixos-rebuild switch --flake .#e490
```

### 查看代际

```bash
sudo nix-env -p /nix/var/nix/profiles/system --list-generations
nh os info                            # 带闭包大小
```

### 清理

```bash
sudo nix-collect-garbage --delete-older-than 365d   # 清理 365 天前的代际
sudo nix-collect-garbage -d                         # 清理所有旧代际（慎用）
```

### 格式化

```bash
nix fmt .                             # 使用 flake formatter（alejandra）
```

### Git hooks 与 CI

首次 clone 后启用仓库自带的 pre-commit：

```bash
git config core.hooksPath .githooks
```

pre-commit 会：

- 对暂存的 `.nix` 文件执行 `nix fmt`，并自动 `git add`
- 执行 `nix flake check --no-build`（只评估，不构建系统闭包）

完整 `nixos-rebuild build` **不放进 pre-commit**：它慢、依赖网络/构建缓存，
且属于本机切换前的验证。提交前需要完整验证时手动执行：

```bash
sudo nixos-rebuild build --flake .#e490
```

CI（GitHub Actions）只做通用的 flake 评估 + 格式检查：

```bash
nix flake check
```

不绑定具体主机、不部署设备。CI 的职责是防止 eval/格式回归，不是替代
`nixos-rebuild switch`。

## 镜像与网络

- **Git 源**：`https://mirrors.tuna.tsinghua.edu.cn/git/nixpkgs.git`
- **二进制缓存**：清华 / 中科大 / 官方（在 `settings/default.nix` 和 `common/nixos/core.nix` 中配置）
- **代理**：如需为 `nix-daemon` 配置代理，参考下方 `systemd.services.nix-daemon.environment` 示例

> 注意：`flake.nix` 中的 `nixConfig` 只影响 flake 自身评估，`sudo nixos-rebuild` 构建时使用系统 `nix.settings.substituters`。

## 常见问题

### 构建报 `Refusing to evaluate package ... is marked as insecure`

按提示把包名追加到 `settings/default.nix` 的 `permittedInsecurePackages`，并加注释说明原因。

### 构建报 `Failed to connect` / `i/o timeout`

1. 检查 `substituters` 是否包含国内镜像
2. 如果卡在 GitHub 或特定软件源，为 `nix-daemon` 配置代理：

   ```nix
   systemd.services.nix-daemon.environment = {
     https_proxy = "http://127.0.0.1:7897";
   };
   ```

### 报 `The option ... does not exist`

选项层级写错了。系统级选项（如 `services.*`、`boot.*`）不能写在 `users/` 里。
查选项：`https://search.nixos.org/options` 和 `https://nix-community.github.io/home-manager/options.xhtml`

### 软件已从配置删除，但开机仍自启

检查命令式残留：

```bash
ls ~/.config/autostart/ | grep -i 软件名
```

删除对应 `.desktop` 文件后注销重新登录。

### Avahi 过时选项警告

警告来自 `services.ipp-usb`：它内部仍设置旧的 `services.avahi.publish.enable`。
`common/nixos/printing.nix` 现在保留 `ipp-usb`（同时保留 sane/扫描功能），
用 `lib.mkForce null` 清空旧选项，并以 `services.avahi.settings.publish.*` 等价表达，
因此警告消失。仅设置 `settings.publish.*` 而不清空旧选项是无效的。

## 设计参考与取舍

本项目参考了以下配置，但没有照搬它们的重型基础设施：

- **nix-starter-configs / Foundry**：`hosts/`、`users/`、`common/`、`modules/` 的分层。
- **ryantm / luochen / novel2430**：主机与用户分离、变量集中。
- **vimjoyer**：极简 flake 入口，适合单机起步。
- **nixy**：dendritic/flake-parts 和硬化方案，适合多机/多模块的大仓库。
- **imdomestic**：当前仓库无法访问，未能核对。

当前只保留一个主机、一个用户，因此**不引入**：

- Hydra/自建 binary cache、pull 自动升级
- deploy-rs/colmena 自动部署
- dendritic、flake-parts、import-tree 等大型架构
- impermanence、disko、sops-nix（没有多机/服务器/密钥管理需求前）

值得后续按需吸收的：

- `nixos-hardware` 的 E490/ThinkPad 硬件模块（电池、热管理、触摸板）
- 可选 `modules/` 目录（出现第一个按需模块时再建）
- `statix` / `deadnix` 等静态检查（先确保不产生噪音）
- 多主机出现后，再考虑动态构建矩阵和远程部署

## 目录结构

详见 `doc/ARCHITECTURE.md`。

## 相关文档

- `doc/ARCHITECTURE.md`：架构设计 + 编码规则（改配置前必读）
- `doc/MAINTENANCE.md`：维护手册、上手指南、故障排查与共性经验
- `doc/OPTIMIZATION.md`：迁移记录与长期维护
- NixOS 选项搜索：https://search.nixos.org/options
- Home Manager 选项：https://nix-community.github.io/home-manager/options.xhtml
- NixOS Wiki：https://wiki.nixos.org