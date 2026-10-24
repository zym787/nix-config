# NixOS 配置

基于 Flake + Home Manager 的多设备多用户 NixOS 配置。

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
| 桌面环境 | KDE Plasma 6 + SDDM + X11 |
| 音频 | PipeWire（PulseAudio 兼容层） |
| 输入法 | fcitx5 + Rime，启用 Wayland 前端 |
| 引导 | systemd-boot（保留 10 个代际） |
| 文件系统 | Btrfs（`root` / `home` / `nix` 子卷，zstd 压缩） |
| 打印 | CUPS + brlaser（Brother DCP-7057） |
| 蓝牙 | BlueZ + BlueDevil（Realtek RTL8822BE） |
| 性能 | zram + sysctl 调优 + thermald + fstrim；PPD 默认 balanced |

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
`vm.vfs_cache_pressure=50`、SSD 定期 TRIM、thermald 温度管理。
没有强制 `performance` governor，避免笔记本发热和续航变差。

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

## 目录结构

详见 `doc/ARCHITECTURE.md`。

## 相关文档

- `doc/ARCHITECTURE.md`：架构设计 + 编码规则（改配置前必读）
- `doc/OPTIMIZATION.md`：迁移记录与长期维护
- NixOS 选项搜索：https://search.nixos.org/options
- Home Manager 选项：https://nix-community.github.io/home-manager/options.xhtml
- NixOS Wiki：https://wiki.nixos.org