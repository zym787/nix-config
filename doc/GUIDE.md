> **状态**：本文是设计参考。实际迁移已完成，结构为 `hosts/e490` + `users/drinkto`
> + `common/{nixos,home}` + `settings/`，构建命令 `sudo nixos-rebuild build --flake .#e490`。
> 文中的 `pc-main`、`alice` 等是占位名；实际执行顺序以 `doc/OPTIMIZATION.md` 和迁移记录为准。

在多设备与多用户并存的真实场景里（涵盖笔记本、桌面 PC、SBC 单板计算机，且单台设备上可能同时有日常使用、嵌入式开发、娱乐等多个账号），**最核心的难点是理清“机器”与“人”的边界**。八份优秀配置的共同经验是：**`hosts/` 管机器，`users/` 管人，两者完全正交**；而新手最容易犯的错误，是把用户配置焊死在主机目录里，导致换机或加人只能复制粘贴。

---

## 📊 八份参考配置的对比与启发

| 配置 | 目录骨架 | 多设备/多用户策略 | 适合借鉴的点 | 不直接照搬的原因 |
| :--- | :--- | :--- | :--- | :--- |
| **nix-starter-configs** | `nixos/` + `home-manager/` + `modules/` | 初期单机单用户；扩展时建 `hosts/` 和 `users/` | **极浅入口，新手 10 分钟看懂** | 多主机复用需自己加 abstraction |
| **Foundry** | `hosts/nixos/` + `hosts/common/` + `home/` + `modules/` | feature flags 按机器开关 | `hosts/common/` 共享层清晰 | feature flags/impermanence 过重 |
| **nixy** | `hosts/<host>/`（configuration + home + variables） | 每台机器自带 `variables.nix` | **主机变量集中，复制即用** | 用户和主机耦合在同一个目录 |
| **ryantm** | `nixos/hosts/` + `nixos/users/shared/` | 主机独立目录，用户有 `shared/` | **用户与主机物理分离** | 旧仓库 legacy 文件多 |
| **luochen1990** | `profiles/` + `fact/` + `common/` | fact 按用户/网络/设备/存储拆分 | 变量与配置分离 | `fact/profile` 术语对新手不直观 |
| **vimjoyer** | `modules/nixos/` + `modules/home-manager/` + `hosts/` | 主机和用户分别放 `hosts/` 与 `users/` | **模块双轨分离，命名直白** | 多机复用需自己加一层 |
| **imdomestic** | `modules/` 按 feature + `hosts/` 组合 | dendritic 按能力组织 | 跨平台复用思路 | **dendritic 是进阶模式，新手难消化** |
| **novel2430** | `hosts/` + `settings/` + `system/` + `user/` | settings 集中变量 | `settings/` 层实用 | `system/user` 边界对新手模糊 |

**关键启发**：

- **入口必须极浅**（nix-starter-configs / vimjoyer）：`flake.nix` 只做发现，具体配置全在模块里。
- **机器与人必须分开**（ryantm / 社区多用户讨论）：`hosts/<hostname>/` 和 `users/<username>/` 平级，主机入口负责组合。
- **共享层要有，但不能重**（Foundry 的 `hosts/common/`）：一层 `common/` 足够，不要引入 feature flags。
- **变量要集中**（nixy / novel2430）：`settings/` 放全局，`hosts/<name>/variables.nix` 放主机特有。

---

## 🏗️ 推荐架构：`hosts/` + `users/` + `common/` + `modules/` + `settings/`

### 目录结构（命名直白，无争议词汇）

```
.
├── flake.nix                     # 只做：inputs / outputs 发现 / nixConfig / formatter
├── flake.lock
├── settings/
│   ├── default.nix               # 全局：镜像源、insecure 包、stateVersion
│   └── packages.nix              # 包分组：core / desktop / dev / media / utils
├── hosts/                        # 按“机器”组织
│   ├── pc-main/                  # 桌面主力机
│   │   ├── default.nix           # 系统 imports + 启用哪些用户
│   │   ├── hardware-configuration.nix
│   │   └── variables.nix         # 主机名、GPU、显示器等
│   ├── laptop-work/              # 工作笔记本
│   │   ├── default.nix
│   │   ├── hardware-configuration.nix
│   │   └── variables.nix
│   └── sbc-home/                 # 家用 SBC（如树莓派）
│       ├── default.nix
│       ├── hardware-configuration.nix
│       └── variables.nix
├── users/                        # 按“人”组织（与 hosts 正交）
│   ├── alice/
│   │   └── default.nix           # 个人 Home Manager 配置
│   ├── bob/
│   │   └── default.nix
│   └── guest/
│       └── default.nix
├── common/
│   ├── nixos/                    # 所有主机共享的系统级配置
│   │   ├── core.nix              # nix.settings / nixpkgs.config / gc / boot
│   │   ├── network.nix
│   │   ├── proxy.nix             # Clash Verge Rev（Mihomo / TUN）
│   │   ├── bluetooth.nix         # BlueZ + 开机上电
│   │   ├── desktop.nix           # Wayland/XWayland / SDDM / Plasma
│   │   ├── graphics.nix          # Intel/AMD GPU、32-bit Vulkan、switcheroo
│   │   ├── gaming.nix            # Steam / GameMode / MangoHud / gamescope
│   │   ├── audio.nix
│   │   ├── fonts.nix
│   │   ├── ime.nix
│   │   ├── printing.nix
│   │   ├── performance.nix       # zram / sysctl / fstrim（E490 不用 thermald）
│   │   └── systemd.nix
│   └── home/                     # 所有用户共享的用户级基础
│       ├── default.nix           # imports 下列模块
│       ├── git.nix
│       └── shell.nix
├── modules/                      # 可选、按需启用的模块（当前未创建）
│   ├── nixos/                    # 系统级可选模块（steam / gaming / clash）
│   └── home-manager/             # 用户级可选模块（vscode / neovim）
└── wallpapers/
```

### 命名规则（避免争议）

| 名称 | 含义 | 为什么不用其他词 |
| :--- | :--- | :--- |
| `hosts/` | 物理/虚拟机器 | 不用 `machines`、`nodes`、`systems`，`hosts` 最通用 |
| `users/` | 账户 | 不用 `people`、`accounts`，`users` 是系统原生概念 |
| `common/` | 共享配置 | 不用 `shared`、`base`、`core`，`common` 语义最中性 |
| `modules/` | 可复用模块 | 不用 `features`、`aspects`、`parts`，`modules` 是 Nix 原生术语 |
| `settings/` | 变量 | 不用 `vars`、`config`、`facts`，`settings` 直白 |
| `nixos/`、`home/` | 系统级 / 用户级子目录 | 不用 `system`、`user`（单数易混淆） |

**主机名禁用 `nixos`、`default`、`localhost`**。使用描述性名称，如 `pc-main`、`laptop-work`、`sbc-home`。主机名是 DNS 标签，只能包含字母、数字和连字符。

---

## 🔗 多设备多用户的组合方式

### 1. 主机声明“这台机器上有哪些用户”

`hosts/pc-main/default.nix`：

```nix
{ settings, ... }:
let hostVars = import ./variables.nix;
in {
  imports = [
    ./hardware-configuration.nix
    ../../common/nixos/core.nix
    ../../common/nixos/desktop.nix
    ../../common/nixos/audio.nix
    # ...
  ];

  networking.hostName = hostVars.hostName;  # "pc-main"

  # 系统级用户必须存在，Home Manager 才能挂载
  users.users.alice = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
  };
  users.users.bob = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" ];
  };

  # 该主机上启用哪些用户的 Home Manager 配置
  home-manager.users.alice = {
    imports = [ ../../users/alice ];
  };
  home-manager.users.bob = {
    imports = [ ../../users/bob ];
  };
}
```

### 2. 用户配置只写“这个人特有的”

`users/alice/default.nix`：

```nix
{ settings, pkgs, ... }:
{
  imports = [ ../../common/home ];   # 所有用户共享的基础

  home = {
    username = "alice";
    homeDirectory = "/home/alice";
    stateVersion = settings.stateVersion;
  };

  # 个人化包和配置
  home.packages = with pkgs; [ obsidian telegram-desktop ];
  programs.git.settings.user.email = "alice@example.com";
}
```

`common/home/default.nix` 是所有用户的“底座”：

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

### 3. 用户在不同主机上的差异

**不要复制用户配置**。在主机入口做局部覆盖：

```nix
# hosts/laptop-work/default.nix
home-manager.users.alice = {
  imports = [ ../../users/alice ];
  # 笔记本特有的用户级补充
  home.packages = [ pkgs.laptop-battery-tool ];
};
```

### 4. 同一台设备多个账号（娱乐 / 嵌入式开发 / 日常）

假设 `pc-main` 上有 `alice`（日常）和 `alice-dev`（嵌入式开发）：

```nix
# hosts/pc-main/default.nix
users.users.alice = { isNormalUser = true; extraGroups = [ "wheel" ]; };
users.users.alice-dev = { isNormalUser = true; extraGroups = [ "dialout" "plugdev" ]; };

home-manager.users.alice = {
  imports = [ ../../users/alice ];   # 日常配置
};
home-manager.users.alice-dev = {
  imports = [ ../../users/alice-dev ];  # 嵌入式开发配置（含 arm-none-eabi 等）
};
```

`users/alice-dev/default.nix` 只放开发工具：

```nix
{ pkgs, ... }:
{
  imports = [ ../../common/home ];
  home.packages = with pkgs; [ gcc-arm-embedded openocd picocom minicom ];
}
```

这样**账号级隔离**，不会互相污染包和环境。

---

## 📄 详细文档

### `README.md`（项目说明）

````markdown
# NixOS 配置

基于 Flake + Home Manager 的多设备多用户 NixOS 配置。

## 设备

| 主机名 | 类型 | 说明 |
| :--- | :--- | :--- |
| `pc-main` | 桌面 PC | 主力工作机 |
| `laptop-work` | 笔记本 | 移动办公 |
| `sbc-home` | SBC | 家用服务 |

## 用户

| 用户名 | 说明 |
| :--- | :--- |
| `alice` | 日常使用 |
| `bob` | 家庭成员 |
| `alice-dev` | 嵌入式开发专用账号 |

## 常用命令

```bash
# 构建（不切换）
sudo nixos-rebuild build --flake .#e490

# 切换
sudo nixos-rebuild switch --flake .#e490

# 更新
sudo nix flake update
sudo nixos-rebuild switch --flake .#e490

# 格式化
nix fmt
```

## 新增设备

1. 复制 `hosts/e490/` 为 `hosts/<新主机名>/`。
2. 替换 `hardware-configuration.nix`（来自 `nixos-generate-config`）。
3. 修改 `variables.nix` 中的 `hostName`。
4. 在 `default.nix` 中声明启用哪些用户。
5. `sudo nixos-rebuild switch --flake .#<新主机名>`。

## 新增用户

1. 复制 `users/drinkto/` 为 `users/<新用户名>/`。
2. 修改 `default.nix` 中的 `username` 和 `homeDirectory`。
3. 在目标主机的 `hosts/<主机名>/default.nix` 中启用该用户。
````

### `ARCHITECTURE.md`（架构说明）

````markdown
# 架构

## 分层

| 层 | 位置 | 职责 |
| :--- | :--- | :--- |
| 入口 | `flake.nix` | inputs / outputs / nixConfig / formatter |
| 变量 | `settings/` | 全局变量 + 包分组 |
| 主机 | `hosts/<hostname>/` | hardware + 主机变量 + 启用哪些用户 |
| 用户 | `users/<username>/` | 个人 Home Manager 配置 |
| 共享系统 | `common/nixos/` | 所有主机共享的系统配置 |
| 共享用户 | `common/home/` | 所有用户共享的用户基础 |
| 可选模块 | `modules/` | 按需启用的软件 |

## 规则

1. `hosts/` 和 `users/` 平级，互不嵌套。
2. `flake.nix` 不写具体 `services.*`。
3. 禁止硬编码 `/nix/store` 路径，用 `${pkgs.xxx}`。
4. 系统级选项不进 `users/`，用户级选项不进 `hosts/`（除 `home-manager.users.<name>` 挂载）。
5. 文件只留生效配置，旧代码交给 `git log`。
````

---

## 🚚 迁移步骤

### Step 0：提交当前状态

```bash
cd ~/Documents/nixos
git add -A && git commit -m "checkpoint: before architecture refactor"
```

### Step 1：创建骨架

实际只创建当前需要的目录；`modules/` 等出现可选模块时再加，不创建空模板。

```bash
mkdir -p settings hosts/e490 users/drinkto common/{nixos,home}
```

把当前 `hardware-configuration.nix` 移入 `hosts/e490/`：

```bash
git mv nixos/hardware-configuration.nix hosts/e490/hardware-configuration.nix
```

### Step 2：抽出 `settings/`

从现有 `configuration.nix` 和 `home.nix` 提取**变量**，不改逻辑：

- `settings/default.nix`：`stateVersion`、`substituters`、`permittedInsecurePackages`。
- `settings/packages.nix`：把 `home.packages` 按现有注释分组搬入。

此步 `build` 应仍通过。

### Step 3：拆分 `configuration.nix` → `common/nixos/`

逐块搬迁，每搬一块删掉原块，`build` 一次：

1. `core.nix`：`nix.settings`、`nixpkgs.config`、`boot.loader`、`nix.gc`
2. `network.nix`：`hostName`（先留空，迁到主机变量）、`networkmanager`、`firewall`
3. `desktop.nix`：`xserver`、`sddm`、`plasma6`
4. `audio.nix`：`pipewire`、`pulseaudio.enable = false`
5. `fonts.nix`
6. `ime.nix`
7. `printing.nix`
8. `systemd.nix`（fwupd；不覆盖 kde-baloo）
   - Avahi 警告实际来自 `ipp-usb`；保留 ipp-usb（扫描），用 `lib.mkForce null` 清空旧选项并设置 `settings.publish.*`。

搬完后旧 `configuration.nix` 只留 `users.users`（下一步迁入主机）。

### Step 4：拆分 `home.nix` → `common/home/`

1. `git.nix`、`shell.nix` 放入 `common/home/`（所有用户共享）。
2. 个人化包和配置放入 `users/alice/default.nix`（假设当前用户是 alice）。
3. `common/home/default.nix` 聚合上述共享模块。

### Step 5：建立主机入口与变量

`hosts/e490/variables.nix`：

```nix
{
  hostName = "e490";
}
```

`hosts/e490/default.nix`：

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

  users.users.alice = { isNormalUser = true; extraGroups = [ "wheel" "networkmanager" ]; };
  home-manager.users.alice = { imports = [ ../../users/alice ]; };
}
```

### Step 6：重写 `flake.nix`

```nix
{
  outputs = { self, nixpkgs, home-manager, ... } @ inputs:
  let
    system = "x86_64-linux";
    settings = import ./settings { inherit inputs; };
  in {
    # formatter 必须按 system 索引，否则 nix flake check 会失败
    formatter.${system} = nixpkgs.legacyPackages.${system}.alejandra;

    nixosConfigurations = nixpkgs.lib.genAttrs
      (builtins.attrNames (builtins.readDir ./hosts))
      (host: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs settings; };
        modules = [
          ./hosts/${host}/default.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs settings; };
          }
        ];
      });
  };
}
```

**注意**：如果将来创建 `hosts/_template`，它会被 `readDir` 发现，需要过滤以 `_` 开头的目录：

```nix
(builtins.filter (n: !(nixpkgs.lib.hasPrefix "_" n))
  (builtins.attrNames (builtins.readDir ./hosts)))
```

### Step 7：验证与清理

```bash
sudo nixos-rebuild build --flake .#e490
sudo nixos-rebuild switch --flake .#e490
```

通过后删除旧 `nixos/configuration.nix`、`home-manager/home.nix`，运行 `nix fmt`，提交：

```bash
git add -A && git commit -m "refactor: migrate to hosts/users architecture"
```

---

## 💡 这套架构为什么适合你的场景

| 场景 | 解法 |
| :--- | :--- |
| laptop / PC / SBC 混合 | `hosts/<描述性主机名>/` 各自独立，共享 `common/nixos/` |
| 单设备多账号（日常/开发/娱乐） | `users/<username>/` 独立目录，主机入口按需启用 |
| 同一用户多设备 | `users/<username>/` 被多个 `hosts/` import，差异在主机入口局部覆盖 |
| 新手看得懂 | 目录名全部是 `hosts`、`users`、`modules`、`common`、`settings` 等原生术语 |
| 加设备/加人 | 复制 `hosts/e490` / `users/drinkto`，改 `variables.nix` 或在主机入口加一行 `home-manager.users.<name>` |
| 避免“越写越乱” | 入口极简，变量集中，共享层薄，旧代码交给 git |