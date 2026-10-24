# NixOS 配置

基于 Flake + Home Manager 的多设备多用户 NixOS 配置。

## 设备

| 主机名 | 类型 | 说明 |
| :--- | :--- | :--- |
| `pc-main` | 桌面 PC | 主力工作机 |
| `laptop-work` | 笔记本 | 移动办公 |
| `sbc-home` | SBC | 家用服务 |

> 新增设备时按 `OPTIMIZATION.md` P2-4 操作。

## 用户

| 用户名 | 说明 |
| :--- | :--- |
| `alice` | 日常使用 |
| `alice-dev` | 嵌入式开发专用账号 |
| `bob` | 家庭成员 |

> 同一设备上的多个账号用后缀区分用途，如 `alice` / `alice-dev` / `alice-game`。

## 技术栈

| 项目 | 值 |
| :--- | :--- |
| 系统通道 | `nixos-unstable`（清华 Git 镜像） |
| 桌面环境 | KDE Plasma 6 + SDDM + X11 |
| 音频 | PipeWire（PulseAudio 兼容层） |
| 输入法 | fcitx5 + Rime，启用 Wayland 前端 |
| 引导 | systemd-boot（保留 10 个代际） |
| 文件系统 | Btrfs（`@root` / `@home` / `@nix` 子卷，zstd 压缩） |
| 打印 | CUPS + brlaser（Brother DCP-7057） |

## 快速开始

```bash
git clone <仓库地址> ~/Documents/nixos
cd ~/Documents/nixos

# 首次构建（不切换）
sudo nixos-rebuild build --flake .#pc-main

# 切换
sudo nixos-rebuild switch --flake .#pc-main
```

## 常用命令

### 构建与切换

```bash
sudo nixos-rebuild build --flake .#pc-main    # 只构建，验证配置
sudo nixos-rebuild switch --flake .#pc-main   # 构建并切换
sudo nixos-rebuild switch --rollback          # 回滚到上一个代际
```

### 更新

```bash
sudo nix flake update                 # 更新所有输入
sudo nix flake update nixpkgs         # 只更新 nixpkgs
sudo nixos-rebuild switch --flake .#pc-main
```

### 查看代际

```bash
sudo nix-env -p /nix/var/nix/profiles/system --list-generations
nh os info                            # 带闭包大小
```

### 清理

```bash
sudo nix-collect-garbage --delete-older-than 14d   # 清理 14 天前的代际
sudo nix-collect-garbage -d                        # 清理所有旧代际（慎用）
```

### 格式化

```bash
nix fmt                               # 需要 flake.nix 中有 formatter
```

## 镜像与网络

- **Git 源**：`https://mirrors.tuna.tsinghua.edu.cn/git/nixpkgs.git`
- **二进制缓存**：清华 / 中科大 / 官方（在 `settings/default.nix` 和 `common/nixos/core.nix` 中配置）
- **代理**：如需为 `nix-daemon` 配置代理，参考 `common/nixos/core.nix` 注释

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

选项层级写错了。系统级选项（如 `programs.clash-verge`）不能写在 `users/` 里。
查选项：`https://search.nixos.org/options` 和 `https://nix-community.github.io/home-manager/options.xhtml`

### 软件已从配置删除，但开机仍自启

检查命令式残留：

```bash
ls ~/.config/autostart/ | grep -i 软件名
```

删除对应 `.desktop` 文件后注销重新登录。

### Avahi 过时选项警告

在 `common/nixos/avahi.nix` 中显式设置 `services.avahi.settings.publish.*`（见 `OPTIMIZATION.md` P1-3）。

## 目录结构

详见 `ARCHITECTURE.md`。

## 相关文档

- `ARCHITECTURE.md`：架构设计 + 编码规则（改配置前必读）
- `OPTIMIZATION.md`：优化与迁移路线（P0/P1/P2）
- NixOS 选项搜索：https://search.nixos.org/options
- Home Manager 选项：https://nix-community.github.io/home-manager/options.xhtml
- NixOS Wiki：https://wiki.nixos.org