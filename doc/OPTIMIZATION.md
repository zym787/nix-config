# 优化与整改路线

> **状态（2026-10-31）**：单文件 → `hosts/` + `users/` + `common/` + `settings/` 的迁移
> 已于 2026-10-24 完成（记录见第六节）。本文现在用于跟踪 **2026-10-31 配置审查**发现的
> 问题和整改计划。每完成一项，在第一节的问题清单里把状态改成 ✅，并写上提交号。

---

## 一、2026-10-31 配置审查：问题清单

严重程度：🔴 功能有问题/隐患大　🟡 冗余、冲突或不好维护　🟢 整洁度

### 1.1 架构与分层

| # | 问题 | 位置 | 严重 | 阶段 | 状态 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| A1 | `common/` 里有 e490 专属硬件配置（双显卡、24G 内存调优、1080p gamescope、DCP-7057 驱动），名义上"共享"，实际只适用于 e490 | `common/nixos/{graphics,performance,gaming,printing}.nix` | 🟡 | P2 | ⬜ |
| A2 | `stateVersion` 放在全局 `settings` 里，新主机和新用户会错误继承 `25.05` | `settings/default.nix:7` | 🔴 | P2 | ⬜ |
| A3 | `settings` 通过 `specialArgs` 传入，不是模块选项：不能按主机覆盖，也没有类型检查 | `flake.nix`、`settings/` | 🟡 | P2 | ⬜ |
| A4 | 镜像源列表和 denial 公钥在 `flake.nix` 的 `nixConfig` 与 `settings`/`core.nix` 各写了一份 | `flake.nix:93`、`settings/default.nix:13`、`core.nix:26` | 🟢 | P2 | ⬜ |
| A5 | 没有可开关的模块层，主机入口无条件 import 全部 16 个 common 模块 | `hosts/e490/default.nix` | 🟡 | P2 | ⬜ |
| A6 | 别名 `nrs`/`nrb` 写死 `#e490`；`trusted-users` 写死 `drinkto`；niri 写死 `eDP-1` 缩放 | `common/home/shell.nix:30`、`core.nix:23`、`users/drinkto/niri.nix:37` | 🟡 | P2 | ⬜ |

### 1.2 桌面层

| # | 问题 | 位置 | 严重 | 阶段 | 状态 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| D1 | Plasma、GNOME、Hyprland、niri 同时启用：闭包大；askpass 冲突只能靠 `mkForce` 压住；portal 有 gnome/gtk/kde 三套，`gtk` 还重复；gnome-keyring 和 kwallet 同时启用 | `common/nixos/desktop-sessions.nix` | 🟡 | P1 | ⬜ |
| D2 | `plasma6.enable` 写了两次 | `desktop.nix:7`、`desktop-sessions.nix:20` | 🟢 | P0 | ⬜ |
| D3 | 注释过时："桌面环境：KDE Plasma 6"、"日常仍默认 Plasma"，实际默认会话是 niri；"xserver 是为了 XWayland"的说法不对 | `desktop.nix:1,3`、`gaming.nix:8` | 🟢 | P0 | ⬜ |
| D4 | `services.libinput` 只对 X11 生效，niri/KWin/GNOME 下都不起作用，niri 里又重复配置了触控板 | `desktop.nix:12-30` | 🟢 | P1 | ⬜ |
| D5 | niri 的 KDL 配置是纯字符串，写错要到登录才发现 | `users/drinkto/niri.nix` | 🟡 | P3 | ⬜ |

### 1.3 包与功能

| # | 问题 | 位置 | 严重 | 阶段 | 状态 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| P1 | `wireshark` 放在 `home.packages`，但没启用 `programs.wireshark`，用户不在 `wireshark` 组，非 root 无法抓包 | `settings/packages.nix:135` | 🔴 | P0 | ⬜ |
| P2 | `localsend` 装了，但防火墙没放行 53317 端口，只能发不能收 | `settings/packages.nix:42` | 🔴 | P0 | ⬜ |
| P3 | 字体回退：emoji 第一位是文本字体 `Maple Mono CN`；sans/serif 第一位是等宽字体 `JetBrainsMono Nerd Font`，界面正文会变等宽 | `common/nixos/fonts.nix:28-51` | 🔴 | P0 | ⬜ |
| P4 | `packages.desktop` 大多已被 DMS 替代：waybar/mako/fuzzel/swaylock/hyprlock/swayidle/wlogout/swaybg/waypaper/wlsunset；`uwsm`、`zsh` 由系统模块提供 | `settings/packages.nix:79-94` | 🟡 | P1 | ⬜ |
| P5 | 无效或重复的包：`polkit`（用户包里没意义）、`gnused/gnutar/gawk/which`（基础环境已有）、`vulkan-tools`/`mangohud` 各装两处、`vulkan-loader` 放在 `hardware.graphics.extraPackages`（那里应该放驱动） | `packages.nix`、`graphics.nix`、`gaming.nix` | 🟢 | P1 | ⬜ |
| P6 | SSH 公钥配了，但 `services.openssh.enable = false`，两者矛盾 | `hosts/e490/default.nix:41` | 🟡 | P0 | ⬜ |

### 1.4 命令式状态与脆弱补丁

| # | 问题 | 位置 | 严重 | 阶段 | 状态 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| S1 | HM activation 每次 switch 都联网执行 `flatpak install`，错误被 `>/dev/null 2>&1 \|\| true` 吞掉；flathub remote 在系统层和用户层各加一次 | `users/drinkto/default.nix:105`、`common/nixos/flatpak.nix:10` | 🟡 | P3 | ⬜ |
| S2 | 用 yq 改 Clash Verge 的 `verge.yaml`，GUI 会写回覆盖 | `users/drinkto/default.nix:119` | 🟢 | P3 | ⬜ |
| S3 | Ghostty `.desktop` 整份复制改写，上游修复后没有提醒删除的机制 | `users/drinkto/default.nix:80` | 🟡 | P1 | ⬜ |

### 1.5 Flake 与工程化

| # | 问题 | 位置 | 严重 | 阶段 | 状态 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| E1 | `dms`/`denial` 用 `?rev=` 写死，`nix flake update` 不会更新它们，也没写锁定原因 | `flake.nix:19,25` | 🟡 | P1 | ⬜ |
| E2 | denial 没有 follows，lock 里共三份 nixpkgs；`programs.denial.enable = false`，但模块仍无条件 import，每次 eval 都要拉源码 | `flake.nix:24`、`desktop-sessions.nix:11` | 🟡 | P1 | ⬜ |
| E3 | CI 只做 eval，不 build；GitHub runner 在海外，却优先走 TUNA 镜像；每个分支都触发 | `.github/workflows/flake_evaltests.yml` | 🟡 | P3 | ⬜ |
| E4 | pre-commit 执行 `nix fmt` 后 `git add`，会把没暂存的改动也一起提交 | `.githooks/pre-commit:36` | 🔴 | P0 | ⬜ |
| E5 | `wallpapers/` 约 9MB，没有代码引用；`checks.formatting` 用 `${./.}`，每次都把整个仓库复制进 store | `wallpapers/`、`flake.nix:81` | 🟢 | P1 | ⬜ |
| E6 | 文档约 2700 行，是 nix 代码的两倍；部分内容已过时 | `doc/` | 🟢 | P4 | ⬜ |
| E7 | 没有 `statix`/`deadnix` 静态检查 | — | 🟢 | P3 | ⬜ |

### 1.6 缺失能力（笔记本 + Btrfs）

| # | 问题 | 严重 | 阶段 | 状态 |
| :--- | :--- | :--- | :--- | :--- |
| M1 | Btrfs 没有 scrub，也没有快照，`/home` 误删后无法恢复 | 🔴 | P3 | ⬜ |
| M2 | 电池充电上限目前读出来是 80，但配置里没有声明（可能来自 BIOS 或之前手动设置），重置后不会自动恢复 | 🟡 | P3 | ⬜ |
| M3 | 有 24G 磁盘 swap，但没配 `boot.resumeDevice`，没法休眠 | 🟡 | P3 | ⬜ |
| M4 | `nh` 装了但没有利用（`programs.nh` 的 `clean` 可以代替 `nix.gc`） | 🟢 | P3 | ⬜ |
| M5 | 没有密钥管理方案，以后 Wi-Fi、代理订阅、token 进仓库前需要先接入 | 🟢 | P4 | ⬜ |

---

## 二、整改路线总览

| 阶段 | 目标 | 包含 | 风险 | 预计 |
| :--- | :--- | :--- | :--- | :--- |
| **P0** 修 bug | 让已有功能真正可用 | E4、P1、P2、P3、P6、D2、D3 | 低 | 1 次会话 |
| **P1** 瘦身 | 缩小闭包、去掉重复和冲突 | D1、D4、P4、P5、S3、E1、E2、E5 | 低到中 | 1–2 次会话 |
| **P2** 分层 | 让"多设备多用户"名副其实 | A1–A6 | 中 | 2–3 次会话 |
| **P3** 声明式与可靠性 | 消除命令式状态，补齐数据保护 | S1、S2、D5、E3、E7、M1–M4 | 中 | 2–3 次会话 |
| **P4** 扩展与收尾 | 用第二台主机验证分层，压缩文档 | E6、M5、新主机 | — | 按需 |

**执行规则（所有阶段通用）**

1. 每项单独提交，提交信息写上问题编号，如 `fix(P1): 启用 programs.wireshark`。
2. 每项都先 `nix flake check --no-build`，再 `sudo nixos-rebuild build --flake .#e490`；`switch` 由用户确认后再执行。
3. P2 是结构调整，重构前后系统闭包应当一致（见 4.0 的闭包对比）。
4. 完成后在第一节问题清单里把状态改成 ✅，并写上提交号。

---

## 三、P0：修 bug（低风险，立即执行）

### P0-1. pre-commit 不再自动 `git add`（E4）

文件：`.githooks/pre-commit`

把"格式化后重新暂存"改成"只检查，不通过就失败"，由用户自己执行 `nix fmt` 后重新暂存：

```bash
if ((${#nix_files[@]})); then
  echo "==> pre-commit: 检查 ${#nix_files[@]} 个暂存 .nix 文件的格式"
  if ! alejandra --check "${nix_files[@]}"; then
    echo "格式不符：执行 nix fmt 后重新 git add，再提交。" >&2
    exit 1
  fi
fi
```

> 注意：`alejandra --check` 检查的是工作区文件，不是暂存区内容。要严格检查暂存区，可以改用 P3-6 的 git-hooks.nix。

验证：先暂存 A 文件，再改 B 文件但不暂存，然后提交，确认 B 没有被带进提交。

### P0-2. Wireshark 抓包权限（P1）

- `settings/packages.nix`：从 `systemTools` 删除 `wireshark`。
- 新建 `common/nixos/wireshark.nix`（或者合并进 P2 的 `my.dev` 模块）：

```nix
{pkgs, ...}: {
  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark; # 默认是 CLI 版，这里换成带 Qt GUI 的
  };
}
```

- `hosts/e490/default.nix`：import 这个模块，并把 `"wireshark"` 加进 `extraGroups`。

验证：重新登录后执行 `groups | grep wireshark`，然后 `dumpcap -D` 能列出网卡。

### P0-3. LocalSend 放行防火墙（P2）

- `settings/packages.nix`：从 `networking` 删除 `localsend`。
- 系统模块里加：

```nix
programs.localsend = {
  enable = true;
  openFirewall = true; # 53317/TCP+UDP
};
```

验证：`nix eval .#nixosConfigurations.e490.config.networking.firewall.allowedTCPPorts` 输出包含 `53317`，并用手机实际给电脑发一次文件。

### P0-4. 修正字体回退顺序（P3）

文件：`common/nixos/fonts.nix`

```nix
defaultFonts = {
  emoji = ["Noto Color Emoji"];
  monospace = ["Maple Mono NF CN" "JetBrainsMono Nerd Font" "Sarasa Mono SC" "Noto Color Emoji"];
  sansSerif = ["Noto Sans CJK SC" "Noto Sans" "Noto Color Emoji"];
  serif = ["Noto Serif CJK SC" "Noto Serif" "Noto Color Emoji"];
};
```

顺便精简 Maple Mono 的四个变体：保留 `NF-CN-unhinted` 一个，覆盖等宽、Nerd 图标和中文；`source-code-pro`、`hack-font` 如果确实不用也可以删掉。

验证：`fc-match sans-serif`、`fc-match monospace`、`fc-match emoji` 的结果符合预期；浏览器打开带 emoji 的页面确认显示正常。

### P0-5. SSH 二选一（P6）

- **方案 A（推荐，笔记本一般不需要被远程登录）**：删除 `openssh.authorizedKeys.keys`。
- **方案 B**：启用并加固：

```nix
services.openssh = {
  enable = true;
  settings = {
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
    PermitRootLogin = "no";
  };
};
```

### P0-6. 清理重复项和过时注释（D2、D3）

- 删除 `desktop.nix:7` 的 `plasma6.enable`，只保留 `desktop-sessions.nix` 里那处。
- `desktop.nix` 的文件头改成"SDDM + 输入设备"，删掉"xserver 是为了 XWayland"的说法。如果去掉 `services.xserver.enable` 后 SDDM 和 Plasma X11 会话仍然正常，就一起删掉。
- `gaming.nix:8` 改为"日常默认 niri"。

**P0 完成标准**：`nixos-rebuild build` 通过；wireshark 能抓包、localsend 能接收、`fc-match` 结果正确。

---

## 四、P1：瘦身（去重、减负）

### P1-1. 桌面会话改成开关（D1）

在 `desktop-sessions.nix` 里定义开关，默认只启用 niri 和 Plasma：

```nix
{config, lib, inputs, pkgs, ...}: let
  cfg = config.my.desktop;
in {
  options.my.desktop = {
    gnome.enable = lib.mkEnableOption "GNOME 会话";
    hyprland.enable = lib.mkEnableOption "Hyprland 会话";
  };

  config = lib.mkMerge [
    { programs.niri.enable = true; services.desktopManager.plasma6.enable = true; }
    (lib.mkIf cfg.gnome.enable { services.desktopManager.gnome.enable = true; })
    (lib.mkIf cfg.hyprland.enable { programs.hyprland = { enable = true; withUWSM = true; }; })
  ];
}
```

- 关掉 GNOME 后，试着删除 `programs.ssh.askPassword = lib.mkForce ...`，确认是否还需要。
- `users/drinkto/hyprland.nix` 改成按 `osConfig.my.desktop.hyprland.enable` 条件生成（HM 模块可以通过 `osConfig` 读取系统配置）。
- 对比前后闭包大小：`nix path-info -Sh ./result`。

### P1-2. 精简 `packages.desktop`（P4）

只保留 `kitty`、`ghostty`，其余删除。如果 Hyprland 会话还要用其中某个组件，把它放进 Hyprland 开关里。

### P1-3. 清理无效和重复的包（P5）

| 包 | 处理 |
| :--- | :--- |
| `polkit`、`gnused`、`gnutar`、`gawk`、`which`、`zsh`、`uwsm` | 删除 |
| `vulkan-loader`（graphics extraPackages / extraPackages32） | 删除，Mesa 已提供 RADV/ANV |
| `vulkan-tools` | 只在 `gaming.nix` 的 `systemPackages` 里保留一处 |
| `mangohud` | 保留 `programs.steam.extraPackages` 和 `systemPackages` 各一处，删除其他重复 |

### P1-4. `libinput` 去冗余（D4）

只保留 X11 兜底需要的最少配置，或者整段删除：Wayland 会话由 niri 配置和 KDE 设置各自管理。

### P1-5. Ghostty 覆盖加过期提醒（S3）

在 `users/drinkto/default.nix` 里加断言，Ghostty 升级后让构建失败，提醒人工复查：

```nix
assertions = [{
  assertion = lib.versionOlder pkgs.ghostty.version "1.4";
  message = "Ghostty 已升级到 ${pkgs.ghostty.version}：确认 SIGUSR2/notify-reload 问题是否已修复，修复了就删掉 desktop 覆盖。";
}];
```

### P1-6. Flake 输入整理（E1、E2）

- `dms`/`denial` 如果没有必须锁定的理由，去掉 `?rev=`，交给 `flake.lock` 锁定；如果必须锁定，在注释里写明原因和升级步骤。
- denial 默认不启用：把 `imports = [inputs.denial.nixosModules.denial]` 移到 `my.desktop.denial.enable` 的说明里，需要时再加回来（模块 import 不能写在 `mkIf` 里）。也可以先接受 eval 开销，只在注释里说明。
- 如果保留 denial 但不追求命中 cachix，可以加 `inputs.nixpkgs.follows = "nixpkgs"` 减少 nixpkgs 份数（代价是要本地编译 Flutter）。

### P1-7. 壁纸与检查源（E5）

- 用不到的壁纸用 `git rm` 删除；要保留就在 DMS 或 SDDM 主题里实际引用。
- `checks.formatting` 只拷贝 `.nix` 文件：

```nix
checks.${system}.formatting = let
  src = nixpkgs.lib.fileset.toSource {
    root = ./.;
    fileset = nixpkgs.lib.fileset.fileFilter (f: f.hasExt "nix") ./.;
  };
in
  pkgs.runCommand "check-formatting" {nativeBuildInputs = [pkgs.alejandra];} ''
    alejandra --check ${src}
    touch $out
  '';
```

> 仓库历史里的大文件依然存在；如果要真正缩小 `.git`，需要 `git filter-repo`，这一步要单独确认，不在本计划内默认执行。

**P1 完成标准**：闭包大小有可见下降（记录前后的 `nix path-info -Sh` 数值）；SDDM 里的会话列表符合开关设置；niri 和 Plasma 都能正常登录。

---

## 五、P2：分层（让多设备多用户成立）

### P2-0. 重构前先保存闭包基线

P2 的每一步都应该是"等价重构"：

```bash
nix build .#nixosConfigurations.e490.config.system.build.toplevel -o /tmp/before
# …改动…
nix build .#nixosConfigurations.e490.config.system.build.toplevel -o /tmp/after
nix store diff-closures /tmp/before /tmp/after   # 应为空，或只有预期的变化
```

### P2-1. `stateVersion` 下沉（A2）

- `settings/default.nix`：删除 `stateVersion`。
- `hosts/e490/default.nix`：`system.stateVersion = "25.05";`
- `users/drinkto/default.nix`：`home.stateVersion = "25.05";`
- `core.nix`：删除对应的那一行。
- 同步更新 `doc/ARCHITECTURE.md` 和 `doc/GUIDE.md` 里的示例。

### P2-2. 建立 `modules/` 和 `my.*` 选项（A3、A5）

```
modules/
├── nixos/
│   ├── default.nix        # imports 下列模块，并在 flake 的 mkHost 里统一导入
│   ├── desktop.nix        # my.desktop.{gnome,hyprland,denial}.enable（从 P1-1 迁来）
│   ├── gaming.nix         # my.gaming.enable
│   ├── printing.nix       # my.printing.enable + drivers
│   └── laptop.nix         # my.laptop.enable：PPD、电池阈值、休眠
└── home/
    └── ...
```

以开关模式为例：

```nix
# modules/nixos/gaming.nix
{config, lib, pkgs, ...}: {
  options.my.gaming = {
    enable = lib.mkEnableOption "Steam 游戏环境";
    resolution = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["-W" "1920" "-H" "1080" "-r" "60"];
      description = "gamescope 会话参数";
    };
  };
  config = lib.mkIf config.my.gaming.enable { /* 原 gaming.nix 内容，args 用 cfg.resolution */ };
}
```

`common/nixos/` 只保留真正所有主机都需要的：core、network、audio、fonts、ime、systemd。

### P2-3. e490 专属配置移回主机目录（A1、A6）

| 内容 | 迁移到 |
| :--- | :--- |
| Intel + AMD 双显卡、`amdgpu`、switcheroo | `hosts/e490/hardware.nix` |
| zram 和 sysctl 里按内存量调的值 | `hosts/e490/default.nix`（通用部分留在 common） |
| DCP-7057 驱动 | `hosts/e490/default.nix` 里设 `my.printing.drivers` |
| niri 的 `output "eDP-1"` | 按主机拆分：`users/drinkto/niri.nix` 读取 `osConfig.networking.hostName`，或者主机侧提供 `my.display.outputs` |
| `trusted-users = ["drinkto"]` | 改为 `["@wheel"]` |
| 别名 `nrs`/`nrb` | 改用 `nh os switch` / `nh os build`，配合 P3-5 的 `programs.nh.flake` 自动识别当前主机 |

### P2-4. 镜像源只保留一处（A4）

`flake.nix` 的 `nixConfig` 必须是字面量，不能 import 别的文件。所以保留 `settings.substituters` 作为系统级唯一来源，`nixConfig` 只留 denial cachix（以及确实需要的条目），并在注释里说明两者的分工。也可以干脆删除 `nixConfig`：系统级 substituters 已经对本机生效，`nixConfig` 只对 untrusted 用户和 CI 有意义。

**P2 完成标准**：`diff-closures` 只有预期的变化；新建 `hosts/_template/`，复制成一台假主机后能通过 `nix eval`（不需要真实硬件）。

---

## 六、P3：声明式与可靠性

### P3-1. Flatpak 声明式（S1）

引入 [nix-flatpak](https://github.com/gmodena/nix-flatpak)：

```nix
# flake.nix inputs
nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
```

```nix
# users/drinkto/default.nix
imports = [inputs.nix-flatpak.homeManagerModules.nix-flatpak];
services.flatpak = {
  remotes = [{
    name = "flathub";
    location = "https://mirror.sjtu.edu.cn/flathub/flathub.flatpakrepo";
  }];
  packages = ["com.baidu.NetDisk"];
  update.auto.enable = false;
};
```

然后删除 `home.activation.flatpakChinaMirror`。系统级 `flatpak-flathub-cn` 服务如果只给用户级安装用，也可以删除。

### P3-2. Clash Verge 自更新（S2）

确认 nixpkgs 版本是否已经禁用自更新（打包时常会 patch 掉）。如果已禁用，删掉这个 activation；如果没有，保留，并把注释改清楚：这是尽力而为，GUI 改动会覆盖它。

### P3-3. Btrfs 维护与快照（M1）

```nix
services.btrfs.autoScrub = {
  enable = true;
  interval = "monthly";
  fileSystems = ["/"]; # 同一块盘只需要 scrub 一次
};

services.snapper.configs.home = {
  SUBVOLUME = "/home";
  ALLOW_USERS = ["drinkto"];
  TIMELINE_CREATE = true;
  TIMELINE_CLEANUP = true;
  TIMELINE_LIMIT_HOURLY = 6;
  TIMELINE_LIMIT_DAILY = 7;
  TIMELINE_LIMIT_WEEKLY = 4;
};
```

前置步骤：`sudo btrfs subvolume create /home/.snapshots`。注意，快照不等于备份，异地备份（restic/borg 到 NAS 或网盘）列为 P4。

### P3-4. 笔记本电源（M2、M3）

放进 P2 的 `my.laptop` 模块：

```nix
# 充电上限 80%，不引入 TLP，避免和 PPD 冲突
systemd.tmpfiles.rules = [
  "w /sys/class/power_supply/BAT0/charge_control_start_threshold - - - - 75"
  "w /sys/class/power_supply/BAT0/charge_control_end_threshold - - - - 80"
];

# 休眠：swap 24G ≥ 内存 24G
boot.resumeDevice = "/dev/disk/by-uuid/77bb4264-88d5-4c5f-ae9b-84e6da2007ba";
```

验证：`cat /sys/class/power_supply/BAT0/charge_control_end_threshold`；执行 `systemctl hibernate` 后能正常恢复会话。

### P3-5. 用 nh 管理 GC（M4）

```nix
programs.nh = {
  enable = true;
  flake = "/home/drinkto/Documents/nixos";
  clean = {
    enable = true;
    extraArgs = "--keep-since 14d --keep 10";
  };
};
nix.gc.automatic = false; # nh.clean 和 nix.gc 互斥
```

然后从 `packages.nixTools` 删除 `nh`。

### P3-6. CI 与本地检查（E3、E7、D5）

- CI 只在 `main` 和 PR 上触发，并把官方源放到最前：

```yaml
on:
  push:
    branches: [main]
  pull_request:

- name: Flake check
  run: nix flake check --show-trace --option substituters https://cache.nixos.org
- name: Dry-run build
  run: nix build .#nixosConfigurations.e490.config.system.build.toplevel --dry-run
```

- 在 `checks` 里加 `statix check`、`deadnix --fail`。
- niri 配置校验：

```nix
checks.${system}.niri-config = pkgs.runCommand "niri-validate" {} ''
  ${pkgs.niri}/bin/niri validate -c ${hmCfg.xdg.configFile."niri/config.kdl".source}
  touch $out
'';
```

（其中 `hmCfg = self.nixosConfigurations.e490.config.home-manager.users.drinkto`）

- 可选：用 [git-hooks.nix](https://github.com/cachix/git-hooks.nix) 替代手写 pre-commit，由 `nix develop` 自动安装，统一管理 alejandra、statix、deadnix。

**P3 完成标准**：一次 `switch` 不再产生任何网络副作用（除了 nix 下载）；`snapper list -c home` 有快照；CI 通过并包含 dry-run build。

---

## 七、P4：扩展与收尾

1. **第二台主机**：优先把台式机 `bikini` 跑起来，按第八节步骤新增。它是对 P2 分层的真实检验：不应该改动 `common/` 就能启用。
2. **SBC `a200i-dk`**：需要在 `flake.nix` 引入 `aarch64-linux`，`mkHost` 改为由 host 声明 `system`；考虑交叉编译或远程构建。
3. **密钥管理（M5）**：第一个密钥入仓前接入 sops-nix（age 密钥由 SSH host key 派生）。在此之前，`.gitignore` 继续兜底。
4. **异地备份**：restic 定时备份 `/home/drinkto` 关键目录。
5. **文档压缩（E6）**：
   - 保留 `README.md`、`ARCHITECTURE.md`（含编码规则）、`NIRI.md`、`MAINTENANCE.md`（只保留排障部分）、本文件。
   - `GUIDE.md` 的调研内容并入 ARCHITECTURE 的"设计参考"一节，或直接删除。
   - 本文件在 P0–P3 完成后，把第一到第六节压缩成一张"已完成"表格。

---

## 八、新增设备/用户

**新增设备**：

1. 复制 `hosts/e490/` 为 `hosts/<新主机名>/`（P2 完成后改为复制 `hosts/_template/`）
2. 替换 `hardware-configuration.nix`（用 `nixos-generate-config` 生成）
3. 修改 `variables.nix` 里的 `hostName`，并为新机设置**它自己首次安装时的** `system.stateVersion`
4. 在 `default.nix` 里打开需要的 `my.*` 开关，并调整要启用的用户
5. `sudo nixos-rebuild switch --flake .#<新主机名>`

**新增用户**：

1. 复制 `users/drinkto/` 为 `users/<新用户名>/`
2. 修改 `default.nix` 里的 `username`、`homeDirectory`、`home.stateVersion`
3. 在目标主机的 `hosts/<主机名>/default.nix` 里加上 `users.users.<name>` 和 `home-manager.users.<name>`

---

## 九、历史：2026-10-24 结构迁移记录

从"单文件 `configuration.nix` + `home.nix`"迁移到当前结构，实际执行顺序：

```
预检 + 基线
  → 改 flake（hosts 自动发现 + settings + 临时 nixos 别名）
  → 拆系统配置到 common/nixos
  → 拆 Home 配置到 common/home + users/drinkto
  → 主机名改为 e490，移除 nixos 别名
  → 清理 baloo / ipp-usb / insecure / nixpkgs-stable
  → 同步文档 + CI
  → 最终验证
```

当时修正过的几个坑（仍然有参考价值）：

- **先改 flake/settings 再拆文件**：否则 `settings` 没有经 `specialArgs` 传进来，拆分时会报 `undefined variable 'settings'`。
- **`formatter` 必须按 system 索引**：直接写成 derivation，`nix flake check` 会把它当成 system 名。
- **`nixConfig` 必须写在 `outputs` 外面**：否则报 unknown flake output。
- **Avahi 过时选项警告来自 `ipp-usb`**：只设置 `services.avahi.settings.publish.*` 消除不了；关闭 ipp-usb 又会连带关掉扫描。最终在 `printing.nix` 里用 `lib.mkForce null` 清空旧选项。
- **自定义的 `kde-baloo` 用户服务会导致 ordering cycle**：已删除，改用包自带的 unit。
- 已删除未使用的 `nixpkgs-stable` 输入、无效的 `http_proxy` 设置，以及大段注释掉的模板代码。
