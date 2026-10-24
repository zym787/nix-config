# 优化与迁移路线

> 按优先级执行。每完成一项，`sudo nixos-rebuild build --flake .#<主机名>` 验证后再进入下一项。

## 一、当前配置诊断

### 已修复（相比上一版）

- `kde-baloo` 的 `ExecStart` 已从硬编码 `/nix/store` 改为 `${pkgs.kdePackages.baloo}`
- `home.nix` 中 `nmap` / `fzf` / `ipcalc` 重复已去重
- `experimental-features` 已是列表类型

### 仍需处理

| 问题 | 位置 | 严重程度 |
| :--- | :--- | :--- |
| `nixpkgs-stable` 定义但未使用 | `flake.nix` | 🟡 中 |
| `http_proxy` / `https_proxy` 无效注释 | `configuration.nix` 的 `nix.settings` | 🟡 中 |
| 大量注释死代码（clash-verge、模板、hyprpanel） | `flake.nix` / `configuration.nix` / `home.nix` | 🟢 低但影响可读性 |
| 缺少 `nix.gc`、`configurationLimit`、系统级 `substituters` | `configuration.nix` | 🟡 中 |
| 缺少 `formatter` | `flake.nix` | 🟢 低 |
| Avahi 过时选项警告 | 由 `printing` / `ipp-usb` 间接触发 | 🟢 低 |
| `systemd.user.services.kde-baloo` 自定义服务可能不必要 | `configuration.nix` | 🟡 中 |
| `permittedInsecurePackages` 无注释 | `configuration.nix` | 🟢 低 |
| `networking.hostName = "nixos"` | `configuration.nix` | 🔴 高（需改为描述性名称） |
| `inputs` 传入 `configuration.nix` 但未使用 | `configuration.nix` | 🟢 低 |
| 单文件过长（各 400+ 行） | `configuration.nix` / `home.nix` | 🔴 高 |

---

## 二、P0：立即处理（纯清理，零风险）

### P0-1. 删除 `nix.settings` 中的无效注释

文件：`nixos/configuration.nix`

```nix
# 删除这几行
# lader
# http_proxy = "http://127.0.0.1:7890";
# https_proxy = "http://127.0.0.1:7890";
```

理由：`http_proxy` / `https_proxy` 不是 Nix 有效设置项，写进去会报 `unknown setting`。

### P0-2. 删除 clash-verge 相关死代码

文件：`nixos/configuration.nix`，删除以下整段：

```nix
# systemd.services.clash-verge.serviceConfig = { ... };
# systemd.services.clash-verge-rev = { ... };
# programs.clash-verge = { ... };
```

文件：`home-manager/home.nix`，删除 `# Ladder` 区块下所有被注释的代理工具。如需保留一个备选，只留一个并加注释说明。

### P0-3. 决定 `nixpkgs-stable` 去留

文件：`flake.nix`

**方案 A（删除，推荐）**：从 `inputs` 删除 `nixpkgs-stable`，执行 `nix flake update`，`flake.lock` 自动清理。

**方案 B（使用）**：在 `common/nixos/core.nix` 加 overlay：

```nix
nixpkgs.overlays = [
  (final: prev: {
    stable = import inputs.nixpkgs-stable {
      system = prev.system;
      config = prev.config;
    };
  })
];
```

之后可用 `pkgs.stable.xxx`。

### P0-4. 为 `permittedInsecurePackages` 加注释

```nix
permittedInsecurePackages = [
  # Cherry Studio 依赖的 Electron，等待上游更新
  "electron-40.10.5"
  # Codex 相关工具依赖
  "pnpm-10.29.2"
  # Zotero 依赖；不再使用 zotero 时删除
  "firefox-esr-140-bin-unwrapped-140.17.0esr"
  # .NET 6 运行时；不再需要时删除
  "dotnet-runtime_6"
];
```

### P0-5. 修改主机名

文件：`nixos/configuration.nix`

```nix
networking.hostName = "pc-main";  # 或 laptop-main / sbc-home
```

主机名改动后需要重新登录，或重启生效。

---

## 三、P1：本周处理（拆文件 + 补系统设置）

### P1-1. 建立新目录骨架

```bash
cd ~/Documents/nixos
mkdir -p settings hosts/pc-main users/alice \
         common/{nixos,home} modules/{nixos,home-manager}
git mv nixos/hardware-configuration.nix hosts/pc-main/hardware-configuration.nix
```

### P1-2. 抽出 `settings/`

`settings/default.nix`：

```nix
{ inputs }:
{
  stateVersion = "25.05";
  substituters = [
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
    "https://mirrors.ustc.edu.cn/nix-channels/store"
    "https://cache.nixos.org"
  ];
  permittedInsecurePackages = [
    # Cherry Studio 依赖的 Electron，等待上游更新
    "electron-40.10.5"
    # Codex 相关工具依赖
    "pnpm-10.29.2"
    # Zotero 依赖；不再使用 zotero 时删除
    "firefox-esr-140-bin-unwrapped-140.17.0esr"
    # .NET 6 运行时；不再需要时删除
    "dotnet-runtime_6"
  ];
}
```

`settings/packages.nix`：把 `home.nix` 里的包按现有注释分组搬过来（`core`、`desktop`、`dev`、`media`、`utils`、`networking`、`system-tools`、`nix-tools` 等），**不增删任何包**。

### P1-3. 拆分 `configuration.nix` → `common/nixos/`

按功能一块一块搬，每搬一块删掉原块，`build` 一次：

1. **`core.nix`**：`nix.settings`、`nixpkgs.config`、`boot.loader`、`nix.gc`、`nix.optimise`、`formatter`
2. **`network.nix`**：`networkmanager`、`firewall`（`hostName` 迁到主机变量）
3. **`desktop.nix`**：`xserver`、`sddm`、`plasma6`
4. **`audio.nix`**：`pipewire`、`pulseaudio.enable = false`
5. **`fonts.nix`**：`fonts.packages`、`fonts.fontconfig`
6. **`ime.nix`**：`i18n.inputMethod`
7. **`printing.nix`**：`services.printing`、`ipp-usb`
8. **`avahi.nix`**：显式 `settings.publish.*`（消除警告）
9. **`systemd.nix`**：`fwupd-refresh` 屏蔽；评估 `kde-baloo` 是否仍必要

`common/nixos/core.nix` 示例：

```nix
{ settings, pkgs, ... }:
{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "alice" ];
    substituters = settings.substituters;
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nix.optimise.automatic = true;

  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = settings.permittedInsecurePackages;
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 10;
}
```

`common/nixos/avahi.nix` 示例：

```nix
{ ... }:
{
  services.avahi.settings.publish = {
    "disable-publishing" = false;
    "disable-user-service-publishing" = false;
    "publish-addresses" = true;
  };
}
```

`common/nixos/systemd.nix` 示例：

```nix
{ pkgs, ... }:
{
  systemd.services.fwupd-refresh.enable = false;
  systemd.timers.fwupd-refresh.enable = false;

  # 如确认 Plasma 6 下 baloo 能自启，删除以下整段
  systemd.user.services.kde-baloo = {
    enable = true;
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.kdePackages.baloo}/libexec/kf6/baloo_file";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
```

### P1-4. 拆分 `home.nix` → `common/home/` + `users/<name>/`

**`common/home/default.nix`**（所有用户共享）：

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

**`common/home/git.nix`**：

```nix
{ ... }:
{
  programs.git = {
    enable = true;
    settings.user.name = "alice";
  };
}
```

**`common/home/shell.nix`**：

```nix
{ ... }:
{
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      aws.disabled = true;
      gcloud.disabled = true;
      line_break.disabled = true;
    };
  };
}
```

**`users/alice/default.nix`**（个人化内容）：

```nix
{ settings, pkgs, ... }:
{
  imports = [ ../../common/home ];

  home = {
    username = "alice";
    homeDirectory = "/home/alice";
    stateVersion = settings.stateVersion;
  };

  home.packages = with pkgs; [
    # 从原 home.nix 搬入个人化包
    fastfetch
    obsidian
    telegram-desktop
    qq
    wechat
    # ... 其余按原分组搬入
  ];

  programs.git.settings.user.email = "alice@example.com";
}
```

搬完后删除旧的 `home-manager/home.nix`。

### P1-5. 建立主机入口与变量

`hosts/pc-main/variables.nix`：

```nix
{
  hostName = "pc-main";
  gpu = "intel";
}
```

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
    ../../common/nixos/avahi.nix
    ../../common/nixos/systemd.nix
  ];

  networking.hostName = hostVars.hostName;
  system.stateVersion = settings.stateVersion;

  users.users.alice = {
    isNormalUser = true;
    description = "alice";
    extraGroups = [ "networkmanager" "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIIN0efXDzfUMXzuI26CiV2xTAkxp/b4HIphsUVQXxU4 alice@pc-main"
    ];
  };

  home-manager.users.alice = {
    imports = [ ../../users/alice ];
  };
}
```

### P1-6. 重写 `flake.nix`

```nix
{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "git+https://mirrors.tuna.tsinghua.edu.cn/git/nixpkgs.git?ref=nixos-unstable&shallow=1";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... } @ inputs:
  let
    system = "x86_64-linux";
    settings = import ./settings { inherit inputs; };
    hostNames = builtins.filter
      (n: !(nixpkgs.lib.hasPrefix "_" n))
      (builtins.attrNames (builtins.readDir ./hosts));
  in {
    formatter = nixpkgs.legacyPackages.${system}.alejandra;

    nixosConfigurations = nixpkgs.lib.genAttrs hostNames (host:
      nixpkgs.lib.nixosSystem {
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

  nixConfig = {
    substituters = [
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store?priority=10"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
    ];
  };
}
```

### P1-7. 验证

```bash
sudo nixos-rebuild build --flake .#pc-main
sudo nixos-rebuild switch --flake .#pc-main
```

失败时优先查：

- `imports` 路径漏写
- `specialArgs` 没传 `settings`
- 模块函数参数没接 `settings`
- `users.users.<name>` 未定义就挂载 `home-manager.users.<name>`

---

## 四、P2：长期维护

### P2-1. 清理 `home.nix` 模板残留

删除以下已注释的模板块：

- `# programs.alacritty = { ... };`
- `# programs.bash = { ... };`
- `# programs.hyprpanel = { ... };`
- `# programs.steam = { ... };`
- `# programs.appimage = { ... };`
- `# nixpkgs = { ... };`（home.nix 顶部）

### P2-2. 清理 `flake.nix` 注释

删除 `# catppuccin`、`# homeConfigurations`、`# packages`、`# overlays`、`# nixosModules`、`# homeManagerModules` 等大段注释。这些模板代码没有保留价值。

### P2-3. 建立定期更新节奏

- 每两周：`nix flake update` + `build` + `switch` + `git commit`
- 每月：配置体检（`ARCHITECTURE.md` R10）
- 每季度：清理不再使用的包和 `permittedInsecurePackages` 条目

### P2-4. 新增设备/用户

**新增设备**：

1. 复制 `hosts/pc-main/` 为 `hosts/<新主机名>/`
2. 替换 `hardware-configuration.nix`（来自 `nixos-generate-config`）
3. 修改 `variables.nix` 中的 `hostName`
4. 在 `default.nix` 中调整启用的用户
5. `sudo nixos-rebuild switch --flake .#<新主机名>`

**新增用户**：

1. 复制 `users/alice/` 为 `users/<新用户名>/`
2. 修改 `default.nix` 中的 `username` 和 `homeDirectory`
3. 在目标主机的 `hosts/<主机名>/default.nix` 中加 `users.users.<name>` 和 `home-manager.users.<name>`

---

## 五、迁移顺序总览

```
P0（清理，零风险）
  → P1-1 建骨架
  → P1-2 抽 settings
  → P1-3 拆 configuration.nix
  → P1-4 拆 home.nix
  → P1-5 建 hosts 入口
  → P1-6 重写 flake.nix
  → P1-7 验证
  → P2 长期维护
```

每步完成后：

```bash
sudo nixos-rebuild build --flake .#pc-main
git add -A && git commit -m "refactor: <本步说明>"
```
> 原子化修改，每步完成后，尝试修改以通过构建