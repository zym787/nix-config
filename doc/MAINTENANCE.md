# NixOS 维护手册

> 面向本仓库的日常维护、上手操作和故障排查。
> 改配置前先读 `doc/ARCHITECTURE.md`；迁移历史见 `doc/OPTIMIZATION.md`。

---

## 1. 当前实例

| 项目 | 值 |
| :--- | :--- |
| 主机 | `e490`（Lenovo E490，i7-8565U，24G 内存） |
| 用户 | `drinkto` |
| 桌面 | KDE Plasma 6 + SDDM + Wayland（XWayland 兼容层） |
| 引导 | systemd-boot，保留 10 个代际 |
| 文件系统 | Btrfs：`root` / `home` / `nix` 子卷，zstd |
| 蓝牙 | Realtek RTL8822BE，BlueZ + BlueDevil |
| 打印/扫描 | Brother DCP-7057，CUPS + brlaser；`ipp-usb` 同时启用 sane |
| 代理 | Clash Verge Rev（Mihomo），规则模式 + TUN |
| 性能 | zram、`vm.swappiness=10`、fstrim、PPD balanced；不使用 thermald |

---

## 2. 目录与职责

```text
flake.nix                  inputs / outputs 发现 / formatter / nixConfig
settings/                  stateVersion、substituters、insecure 包、包分组
hosts/e490/                主机入口、硬件配置、hostName
users/drinkto/             个人 Home Manager 配置
common/nixos/              所有主机共享的系统配置
common/home/               所有用户共享的用户配置
doc/                       架构、迁移记录、本维护手册
```

新增内容放哪里：

| 内容 | 位置 |
| :--- | :--- |
| 系统服务 / 内核 / 网络 | `common/nixos/<name>.nix`，在 `hosts/e490/default.nix` import |
| 用户级程序配置 | `common/home/` 或 `users/drinkto/` |
| 全局变量 | `settings/default.nix` |
| 软件包 | `settings/packages.nix`（注意 system 与 home 两个层） |
| 新主机 | 复制 `hosts/e490/`，改 `variables.nix`，在 flake 自动发现 |
| 新用户 | 复制 `users/drinkto/`，改 username，在主机入口挂载 |

---

## 3. 上手流程

```bash
cd ~/Documents/nixos

# 1. 先确认现状
git status
nix flake check --no-build --show-trace
sudo nixos-rebuild build --flake .#e490

# 2. 新建分支，改配置
git switch -c feat/<topic>

# 3. 格式化 + 构建
nix fmt .
nix flake check --no-build --show-trace
sudo nixos-rebuild build --flake .#e490

# 4. 提交（flake 只看到 git 已跟踪文件，必须先 add）
git add -A
git commit -m "feat(scope): subject"
```

切换：

```bash
sudo nixos-rebuild switch --flake .#e490
```

回滚：

```bash
sudo nixos-rebuild switch --rollback
# 或 git revert / git switch main
```

> **重要**：新建 `hosts/`、`users/`、`common/` 文件后如果不 `git add`，
> `nixos-rebuild --flake` 可能看不到这些文件。

### 3.1 Git pre-commit

仓库自带 `.githooks/pre-commit`，首次 clone 后启用：

```bash
git config core.hooksPath .githooks
```

钩子行为：

1. 只对暂存区的 `.nix` 文件执行 `nix fmt`；
2. 格式化后自动 `git add`；
3. 执行 `nix flake check --no-build`，只做评估，不构建系统闭包。

没有 Nix 改动的提交（例如只改 Markdown）会跳过。

注意：如果对同一个 `.nix` 文件做了“部分暂存”，钩子会格式化整个文件并
`git add` 整个文件；建议按文件整体提交，或在提交前先处理好暂存区。

临时跳过 eval：

```bash
SKIP_NIX_CHECK=1 git commit -m "..."
```

**为什么不在 pre-commit 跑完整构建**：

- `nixos-rebuild build` 可能耗时数分钟、下载/构建大量包；
- 它依赖本机缓存/网络，失败原因常与本次改动无关；
- 完整构建是 `switch` 前的本地验证，不是每次提交的门槛；
- 把设备/主机名写进共享钩子会造成设备绑定。

### 3.2 CI 的职责

当前 GitHub Actions 只做：

```bash
nix flake check
```

包括：

- 评估 flake 的所有 `nixosConfigurations`；
- 构建 `checks.<system>.formatting`，用 alejandra `--check` 验证格式；
- 不 build 完整系统闭包；
- 不部署、不绑定具体主机。

CI **不是 CD**。个人 NixOS 设备的部署需要 root、硬件、磁盘和本机密钥，
应由本人在设备上执行：

```bash
sudo nixos-rebuild build --flake .#e490
sudo nixos-rebuild switch --flake .#e490
```

如果以后确实需要 CI 构建验证，建议用 `workflow_dispatch` 手动触发，
并动态遍历 `nixosConfigurations`，不要写死 `e490`；不要自动部署到设备。

### 3.3 CI/CD 功能取舍

参考 8 份公开配置后的结论：**只有 Foundry 有完整 CI/CD**（Hydra 构建所有
host、binary cache、pull 自动升级）；大多数个人配置没有 GitHub Actions，
主要靠本地 `nixos-rebuild`。

| 功能 | 当前是否启用 | 说明 |
| :--- | :--- | :--- |
| flake eval | ✅ | 必选，能拦住大多数配置错误 |
| 格式检查 | ✅ | alejandra check |
| pre-commit | ✅ | 暂存文件格式化 + eval |
| statix/deadnix 静态检查 | ⬜ 可选 | 先确认不会产生大量噪音 |
| 完整闭包构建 | ⬜ 本地 | `nixos-rebuild build`，不放进每次提交 |
| CI 自动 build | ⬜ 可选 | 多主机/有缓存时再加 |
| binary cache | ⬜ 可选 | 自建 Hydra/Cachix 才有意义 |
| CD / 自动部署 | ❌ | 笔记本不建议；需要 root/硬件/密钥 |
| 自动升级 | ❌ | 服务器可用 pull 模式；笔记本手动 switch |
| Hydra/self-hosted runner | ❌ | 单机配置过重 |

CI 的目的不是“证明能在你的设备上启动”，而是：

1. 防止 flake 评估失败；
2. 防止格式回退；
3. 给 PR/分支提供一个统一的检查结果；
4. 不接触设备、不持有部署密钥。

真正的“编译通过”由本地 `nixos-rebuild build` 完成；真正的部署由本地
`nixos-rebuild switch` 完成。CI 不应替代这两步。

---

## 4. 日常维护

### 4.1 更新

```bash
nix flake update nixpkgs
sudo nixos-rebuild build --flake .#e490
sudo nixos-rebuild switch --flake .#e490
git add flake.lock && git commit -m "chore: flake update"
```

- 不要用 Clash Verge GUI 的自更新；NixOS 包是只读的，更新走 nixpkgs。
- 更新后先 `build`，确认包/服务没有 breaking change，再 `switch`。

### 4.2 清理与代际

```bash
sudo nix-env -p /nix/var/nix/profiles/system --list-generations
sudo nix-collect-garbage --delete-older-than 30d
```

`nix.gc` 已配置为每周、保留 14 天；`configurationLimit = 10` 限制 boot 条目。

### 4.3 包变更检查

```bash
# 迁移/改包前后对比，避免漏包
nix eval --json .#nixosConfigurations.e490.config.environment.systemPackages \
  --apply 'ps: map (p: p.name) ps' | jq -S 'sort'
nix eval --json .#nixosConfigurations.e490.config.home-manager.users.drinkto.home.packages \
  --apply 'ps: map (p: p.name) ps' | jq -S 'sort'

# 看闭包变化
nix store diff-closures /run/current-system ./result
```

---

## 5. 故障排查

### 5.1 Nix / flake

| 现象 | 原因 | 处理 |
| :--- | :--- | :--- |
| `does not provide attribute 'nixosConfigurations.xxx'` | attr 名写错 | `nix flake show`，当前只有 `e490` |
| `undefined variable 'settings'` | 拆模块早于 flake 传参 | 先改 flake `specialArgs`，再拆模块 |
| `path ... does not exist` | 旧文件已删但仍 import | 全局搜 import，按依赖顺序删 |
| 新文件不生效 | flake 只认 git 跟踪文件 | `git add -A` 后再 build |
| `The option ... does not exist` | 系统级/用户级层级错 | 查 search.nixos.org / HM options |
| `Refusing to evaluate package ... insecure` | 包被标记不安全 | 加 `permittedInsecurePackages` 并注释；卸载后删除 |
| `nix flake check` 里 formatter 报错 | `formatter` 不是按 system 索引 | 用 `formatter.${system} = ...` |
| `unknown flake output 'nixConfig'` | `nixConfig` 写进 outputs | 放到顶层 |

### 5.2 systemd / 桌面

**kde-baloo ordering cycle**

- 不要覆盖上游 `kde-baloo.service`。
- baloo 包自带正确 unit，包含 `After=plasma-workspace.target`。
- 自定义 unit 缺这个排序会形成 loop，服务被 systemd 删除。
- 检查：

```bash
systemctl --user status kde-baloo.service --no-pager
journalctl --user -b --no-pager | grep -i 'ordering cycle'
balooctl6 status
```

**KDE 蓝牙 QML 模块缺失**

现象：

```text
module "org.kde.plasma.private.bluetooth" is not installed
module "org.kde.bluezqt" is not installed
```

原因：

- Plasma 6 的 NixOS 模块在 `hardware.bluetooth.enable = true` 时会自动把
  `bluedevil` / `bluez-qt` 加到 **系统** 包。
- 如果又在 `home.packages` 加 `kdePackages.bluedevil`，会出现重复的 QML 路径，
  运行中的 plasmashell 还可能保留旧环境。

处理：

1. 不要在 home 里重复装 `kdePackages.bluedevil`。
2. 切换后重启 plasmashell 或注销重新登录：

```bash
systemctl --user restart plasma-plasmashell.service
# 或注销重新登录
```

3. 确认系统 QML 路径存在：

```bash
ls /run/current-system/sw/lib/qt-6/qml/org/kde/bluezqt/
ls /run/current-system/sw/lib/qt-6/qml/org/kde/plasma/private/bluetooth/
```

### 5.3 打印 / 扫描

- `services.ipp-usb` 不只是 IPP 打印，它还会启用 `services.printing` 和 `hardware.sane`。
  **关闭 ipp-usb 会同时关闭 sane/skanpage 扫描功能**。
- DCP-7057 驱动：`brlaser` 优先，Brother 官方/`gutenprint` 作为备选。
- avahi obsolete 警告来自 ipp-usb 内部仍设置旧的 `services.avahi.publish.*`。
  当前用 `lib.mkForce null` 清空旧选项，再设置 `services.avahi.settings.publish.*`。
- 检查：

```bash
lpstat -p
lpstat -v
systemctl status ipp-usb --no-pager
scanimage -L
```

打印机显示 `disabled ... Unplugged or turned off` 时先检查 USB/电源，不是配置问题。

### 5.4 代理（Clash Verge）

#### 结构

- NixOS 只管理包、service、capabilities：`common/nixos/proxy.nix`。
- Clash Verge 的应用状态在：

```text
~/.local/share/io.github.clash-verge-rev.clash-verge-rev/
├── verge.yaml               # GUI 设置（TUN、自动更新、自启等）
├── config.yaml              # 当前基础配置
├── clash-verge.yaml         # 生成的运行配置
├── dns_config.yaml          # Clash Verge 的全局 DNS 覆写
└── profiles/
    ├── Merge.yaml           # 全局 merge
    └── <uid>.yaml           # 机场订阅 profile
```

**不要只改 `clash-verge.yaml`**：它会在 Clash Verge 重启时被重新生成。

#### DNS 分层：谁改了 DNS？

先把四层 DNS 分开：

| 层 | 位置 | 谁管理 | 作用 |
| :--- | :--- | :--- | :--- |
| 系统 DNS | `/etc/resolv.conf`、NetworkManager | NixOS/路由器 | 普通系统解析 |
| 机场 profile DNS | `profiles/<uid>.yaml` 的 `dns:` | 机场订阅 | 机场自己的解析策略，例如节点域名专用 DoH |
| Clash Verge 全局 DNS | `dns_config.yaml` | Clash Verge GUI | “DNS 覆写”开启时覆盖 profile 的 DNS |
| 运行时 DNS | `clash-verge.yaml` 的 `dns:` | Clash Verge 生成 | mihomo 实际加载的配置 |

关键点：

- **订阅可以携带 DNS 配置**（`nameserver`、`nameserver-policy`、`proxy-server-nameserver` 等），
  但订阅更新不会改 `/etc/resolv.conf`。
- Clash Verge 的 `verge.yaml` 里 `enable_dns_settings: true` 时，
  它用自己的 `dns_config.yaml` 做全局覆写；默认的 `nameserver-policy: {}`
  会盖掉机场 profile 里的 `nameserver-policy`。
- 本次失败就是：机场 profile 为 `+.quandao.com` / `+.jiandaoyun.com`
  配了专用 DoH；Clash Verge 全局 DNS 把它覆盖成空策略，并让
  `proxy-server-nameserver` 走 `doh.pub` / 阿里 DNS，节点域名被解析到
  `overdue.aliyun.com`。
- GUI 里保存 DNS 设置、切换“DNS 覆写”、应用升级/迁移、或重新导入 profile，
  都可能重写 `dns_config.yaml`；所以修好后仍要在订阅更新时复查。
- 如果机场更换了 DoH 地址/令牌，需要把新 profile 的
  `dns.nameserver-policy` 重新同步到 `dns_config.yaml` 和 `Merge.yaml`。
- 只设置 `nameserver-policy` 还不够；代理节点域名解析还受
  `proxy-server-nameserver` 影响，两者要一起配置。

**推荐做法（当前配置）**：在 Clash Verge 中关闭 **DNS 覆写**
（`verge.yaml` 的 `enable_dns_settings: false`），让订阅 profile 自己的
`dns:` 生效。实测：

- profile DNS 监听 `127.0.0.1:5335`，TUN 仍然正常；
- `nameserver-policy` 自动随订阅更新，不需要手动复制 DoH token；
- 代理节点、TUN 直连、7897 混合端口都正常。

只有在必须使用 Clash Verge 全局 DNS 时，才需要把机场 policy 复制到
`dns_config.yaml` / `Merge.yaml`。否则不建议开启覆写，因为它会多一层覆盖，
也是本次故障的直接原因。

#### 应用配置的持久性与 NixOS 管理边界

- `verge.yaml`、`config.yaml`、`dns_config.yaml`、`profiles/Merge.yaml`
  都是 Clash Verge 的应用数据，不是 NixOS 声明式配置。
- 普通 `nixos-rebuild switch` **不会**重置节点、模式、TUN、DNS 覆写；
  唯一会被 Home Manager activation 改的是 `auto_check_update`。
- Clash Verge 升级、重置设置、重新导入 profile、或清理应用数据，可能重写
  `dns_config.yaml` / `Merge.yaml`；重装系统时如果保留 `/home`，这些文件会保留；
  如果清空家目录/新用户，则会丢失。
- 手动编辑 `dns_config.yaml` / `Merge.yaml` 只对当前应用数据有效，不是永久的
  NixOS 配置；订阅更新后要复查，应用升级后也可能失效。
- NixOS 没有原生的 Clash Verge DNS/节点/模式选项。可以写 Home Manager
  activation 或 systemd user service 去改应用文件，但应用运行时会重写，
  且把机场 DoH token 放进 Nix store 会泄露给所有本机用户，不建议。
- 因此当前策略是：NixOS 管包、service、capabilities；DNS/节点/模式交给
  Clash Verge 和订阅 profile；维护手册记录检查方法。

检查命令（不要公开输出 token）：

```bash
cd ~/.local/share/io.github.clash-verge-rev.clash-verge-rev

# 机场 profile 里的 DNS 策略
yq '.dns."nameserver-policy"' profiles/<uid>.yaml

# Clash Verge 的全局覆盖
yq '."nameserver-policy", ."proxy-server-nameserver"' dns_config.yaml

# 运行时实际值
yq '.dns."nameserver-policy", .dns."proxy-server-nameserver"' clash-verge.yaml
```

#### 常见问题：节点测速全 timeout，但 Android/flclash 正常

本次实际案例：

- 机场 profile 里有 `nameserver-policy`，对 `+.quandao.com` / `+.jiandaoyun.com`
  使用机场自己的 DoH 解析真实节点 IP。
- Clash Verge 的 `dns_config.yaml` 默认 `nameserver-policy: {}`，
  并用 `proxy-server-nameserver` 走 `doh.pub` / 阿里 DNS。
- 结果节点域名被解析到 `overdue.aliyun.com`（170.33.12.185），TCP 全部超时。
- 这不是机场节点失效；Android/flclash 使用 profile 自带 DNS 策略所以正常。

处理（推荐顺序）：

1. 先关闭 Clash Verge 的 DNS 覆写，让机场 profile 的 `dns:` 生效。
2. 重启 Clash Verge，验证节点延迟、TUN 和 7897 混合端口。
3. 如果必须保留 DNS 覆写，再从机场 profile 复制 `dns.nameserver-policy`
   到 `dns_config.yaml` / `profiles/Merge.yaml`，并把
   `proxy-server-nameserver` 改为机场提供的 DoH 列表。
4. 重启 Clash Verge，检查 `clash-verge.yaml` 里实际生效的 `dns.listen`
   和 `nameserver-policy`。

排查命令：

```bash
# Clash API（secret 在 clash-verge.yaml，不要贴到公开日志）
curl -s -H "Authorization: Bearer $SECRET" http://127.0.0.1:9097/configs | jq '{mode, tun: .tun.enable}'

# 节点测速
curl -s -H "Authorization: Bearer $SECRET" \
  "http://127.0.0.1:9097/proxies/<urlencoded-node>/delay?url=http%3A%2F%2Fwww.gstatic.com%2Fgenerate_204&timeout=5000"

# 混合端口测试
curl -x http://127.0.0.1:7897 -I https://www.google.com

# 直连/TUN 测试
curl -I https://www.google.com
```

#### 模式 vs 代理组

- `mode: rule` 才是规则模式；`direct` 会把所有请求直连。
- “规则代理组”是代理组选择，不等于模式。
- 日志出现 `using DIRECT` 先检查 `mode`，不要先怀疑节点。
- GUI 的 TUN/模式状态会覆盖手改的生成配置；持久化要在 GUI 中设置，
  或在应用停止时改 `verge.yaml` / `config.yaml` 后重启。

#### GUI 操作边界

正常使用 GUI 不会破坏 NixOS 配置；NixOS 只管理包、service、capabilities，
不管理节点、模式、TUN、订阅等运行态。

| GUI 操作 | 安全性 | 说明 |
| :--- | :--- | :--- |
| 切换节点 | 安全 | 选择会持久化（`store-selected: true`），`nixos-rebuild` 不会重置 |
| 切换代理组为 DIRECT | 安全 | 只影响匹配到该组的流量；适合“部分流量直连” |
| 切换模式 rule/direct | 安全 | `direct` 是全局直连，不是只让某个软件直连 |
| 开/关 TUN | 安全 | TUN 关闭后混合端口 7897 仍可用；NixOS 的 capabilities 保留 |
| 开/关系统代理 | 安全 | 与 FoxyProxy 二选一，避免双重代理 |
| 检查更新/自动更新 | 会被 GUI 覆盖 | NixOS activation 只做 best-effort；更新走 `nix flake update` |
| **DNS 覆写** | **建议关闭** | 关闭后使用机场 profile DNS；开启时可能重写 `dns_config.yaml`，覆盖机场 `nameserver-policy` |

选择性直连的建议：

- 只让某类流量直连：保持 `mode: rule`，把对应代理组设为 `DIRECT`，
  或用规则（`PROCESS-NAME`/`DOMAIN-SUFFIX`）指向 `DIRECT`。
- 临时完全关闭代理：模式改 `direct`，并关闭 TUN/系统代理；
  FoxyProxy 也要关掉或切到 direct，否则浏览器仍会连 7897。
- 不要用全局 `direct` 来“只让某个软件直连”，那会让所有流量直连。

#### TUN / DNS 权限

- TUN 需要 mihomo 监听 53 做 DNS 接管。
- NixOS 的 `programs.clash-verge` 模块默认 `CapabilityBoundingSet` 不含
  `CAP_NET_BIND_SERVICE`，会出现：

```text
Start DNS server(TCP/UDP) error: listen :53: bind: permission denied
```

- 当前 `common/nixos/proxy.nix` 已补：

```nix
systemd.services.clash-verge.serviceConfig = {
  CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
  AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
};
```

- 节点不可用时先关 TUN，避免全系统断网。
- 需要时设置 `routing-mark`（当前 Merge profile 使用 6666）避免核心出站回环。

#### 版本提示

- NixOS 包版本由 nixpkgs 决定；GUI 提示的 v2.5.8 不代表 NixOS 仓库已更新。
- 不要用 GUI 自更新覆盖 Nix store；更新走：

```bash
nix flake update nixpkgs
sudo nixos-rebuild switch --flake .#e490
```

- 自动检查更新已通过 Home Manager activation 尽力关闭；GUI 里再次打开则以 GUI 为准。

#### Wayland 下标题栏按钮失效

Clash Verge 是 Tauri/GTK 应用；在原生 Wayland 下可能使用客户端装饰，
出现最小化/最大化/关闭按钮点不动。可先用 XWayland 验证：

```bash
GDK_BACKEND=x11 clash-verge
```

如果 KWin 的标题栏按钮恢复正常，可以把 GUI 启动方式固定为 XWayland
（例如 XDG autostart 的 `Exec=env GDK_BACKEND=x11 clash-verge`）。
不要把这个环境变量设成全局，否则会影响其他 GTK 应用。

#### 安全

- `profiles.yaml`、机场订阅 URL、DoH token、代理密码都在用户目录，
  不能提交到 git，也不要贴到公开 issue。
- 备份应用配置时注意备份文件同样含敏感信息。

#### 敏感信息审计

本次对 48 个提交做了全历史扫描（`gitleaks` + git grep），结果：

- 未发现私钥、密码、API key、GitHub token、机场订阅 URL、DoH token。
- 仓库中没有 `.env`、`*.pem`、`id_rsa`、`secrets/` 等文件。
- 存在以下**非凭据但属于个人信息/设备标识**的内容：
  - `users/drinkto/default.nix` 的 git 邮箱
  - `hosts/e490/default.nix` 的 SSH **公钥**（公钥本身按设计可公开，
    私钥不在仓库）
  - `hosts/e490/hardware-configuration.nix` 的磁盘/分区 UUID
  - git 提交作者邮箱（历史元数据）
- `git remote` 是 HTTPS，没有把 token 写进 URL；没有 `.git-credentials` 进仓库。

如果要把仓库公开，建议：

1. 邮箱可换成 GitHub noreply 或删除 `settings.user.email`；
2. 磁盘 UUID 可考虑只保留在私有部署仓库；
3. SSH 公钥可以保留（不是秘密），但不要提交私钥；
4. 若要彻底清除历史中的邮箱/设备标识，需要 `git filter-repo` 重写并
   force-push，会影响所有 clone；普通配置仓库通常不值得这样做。

审计命令：

```bash
# 历史里的常见凭据模式
git log --all -p | grep -iE 'password|passwd|secret|token|api[_-]?key|BEGIN .*PRIVATE KEY'

# 可疑文件名
git rev-list --objects --all | grep -Ei '\.(pem|key|env|p12|pfx|age)$|id_rsa|id_ed25519|secrets'

# 用 gitleaks 扫描全历史
nix run nixpkgs#gitleaks -- detect --source . --redact
```

### 5.5 性能 / 蓝牙

- zram：24G 内存的 25%，优先于磁盘 swap。
- `vm.swappiness=10`、`vm.vfs_cache_pressure=50`、`vm.dirty_*`。
- `fstrim.timer` 每周 TRIM。
- **E490 不启用 thermald**：`thinkpad_acpi dytc_lapmode` 会让它报
  `Unsupported cpu model or platform` 并退出。
- PPD 默认 balanced；临时高性能：

```bash
powerprofilesctl set performance
powerprofilesctl set balanced
```

- 蓝牙：`hardware.bluetooth.powerOnBoot = true`；用 KDE BlueDevil 或 `bluetoothctl`。

### 5.6 Wayland / 触摸板 / 输入延迟

当前实际会话是 **Wayland**（`startplasma-wayland`），不是 X11。
`services.xserver.enable` 只用于 XWayland，不能据此判断会话类型。

输入法：

- fcitx5 + Rime，数据方案为雾凇拼音 `rime-ice`，用户配置在
  `~/.local/share/fcitx5/rime/default.custom.yaml`。
- Rime 的词库/方案由 `common/nixos/ime.nix` 的
  `fcitx5-rime.override { rimeDataPkgs = [ rime-ice rime-data ]; }` 提供。
- 切换或改了 Rime 配置后，如果方案没生效：
  - 在 fcitx5-configtool 里重新选择 Rime；
  - 或删除 `~/.local/share/fcitx5/rime/build` 后执行 `fcitx5-remote -r`，
    让 Rime 重新部署。
- 个人常用词可以加到 `~/.local/share/fcitx5/rime/custom_phrase.txt`
  （Rime 用户词库也会自动学习）。

触摸板：

- 设备：`Synaptics TM3471-020`（I2C/RMI4），内核已识别。
- KDE Plasma 6 + Wayland 原生支持触摸板手势，入口：
  **系统设置 → 输入设备 → 触摸板 → 手势**。
- 可配置三指/四指滑动、捏合等；KDE 不提供 macOS 的全部手势集合。
- `common/nixos/desktop.nix` 里的 `services.libinput` 主要面向 X11/Xorg；
  KDE Wayland 下实际由 KWin 读取 KDE 的触摸板设置（`kcminputrc`），
  不要误以为 NixOS 里的 `tapping/disableWhileTyping` 一定生效。
- 如果“打字后不久点击无效”，先关闭 KDE 触摸板的
  “打字时禁用触摸板”（Disable while typing）再测。

输入延迟/点击丢失：

- 外部鼠标是 `MicLink AiMouse`（USB 无线），KWin 日志曾出现
  `event processing lagging behind by 46ms`。先换鼠标/换 USB 口对比，
  排除无线接收器/硬件问题。
- `rtw88_8822be` 有大量 PCIe AER correctable 错误（本次检查约 19035 条）。
  这是 Realtek Wi-Fi 网卡的 PCIe/ASPM 问题，可能造成日志刷屏和偶发卡顿。
  可测试内核参数：

  ```nix
  boot.kernelParams = [ "pcie_aspm=off" ];
  ```

  代价是功耗可能略增；先确认问题是否与 Wi-Fi/PCIe 相关，再保留。
  如果错误持续且影响使用，检查网卡是否松动/更换网卡。
- KWin 当前使用 OpenGL ES / Intel UHD 620，硬件合成正常，不是软件渲染。
- 屏幕是 1920x1080 @ 60Hz，缩放 1.25；如仍觉得卡，可临时试 1.0 缩放
  或关闭部分桌面特效，以区分是缩放/特效还是输入设备问题。

---

## 6. 之前问题的共性经验

1. **先区分“声明式配置”和“应用运行态”**  
   NixOS 管包/服务/权限；Clash Verge、KDE、CUPS 的 GUI 状态在用户目录，
   改了生成文件不等于持久化。要找应用的源配置（`verge.yaml`、`dns_config.yaml`）。

2. **不要只看一个症状**  
   节点 timeout 可能是节点、DNS、TUN 路由、模式、代理组、订阅。  
   对比一个能用的客户端（Android/flclash）能快速定位是服务端还是本机。

3. **DNS 是透明代理的第一嫌疑**  
   `dig`/`getent` 看到 `198.18.x.x` 是 fake-ip，不代表真实解析；要看
   `nameserver-policy`、`proxy-server-nameserver` 和 mihomo DNS 日志。

4. **NixOS 模块会做“隐藏的依赖”**  
   `hardware.bluetooth.enable` 自动装 bluedevil/bluez-qt；  
   `services.ipp-usb` 自动启用 sane；`services.pipewire.pulse` 自动装 plasma-pa。  
   重复安装或盲目关闭会引入 QML/扫描问题。

5. **不要覆盖上游 systemd unit**  
   kde-baloo 的 ordering cycle 就是自定义 unit 缺 `After=plasma-workspace.target`。  
   优先用上游 unit；需要覆盖时先 `systemctl cat`/对比包内 unit。

6. **flake 只认 git 跟踪文件**  
   新建文件先 `git add`；否则 build 看不到，容易误判为路径错误。

7. **行为保持式迁移**  
   拆文件时对比 `home.packages` / `environment.systemPackages` 和闭包差异；
   先 build 再 switch；保留回滚代际。

8. **敏感信息不入库**  
   订阅 URL、DoH token、代理密码、SSH 私钥都不要进 git；  
   维护手册只记录路径和方法，不记录 token。

---

## 7. 常用检查清单

### 切换后

```bash
hostnamectl --static
systemctl --user status kde-baloo.service --no-pager
balooctl6 status
systemctl status bluetooth --no-pager
bluetoothctl show
zramctl
sysctl vm.swappiness vm.vfs_cache_pressure
systemctl status fstrim.timer --no-pager
powerprofilesctl get
lpstat -p
```

### 代理检查

```bash
systemctl status clash-verge --no-pager
systemctl show clash-verge -p CapabilityBoundingSet -p AmbientCapabilities
curl -x http://127.0.0.1:7897 -I https://www.google.com
curl -I https://www.google.com
```

### 配置体检

```bash
nix flake check --no-build --show-trace
nix fmt .
grep -rn "/nix/store/" --include="*.nix" .
grep -rn "TODO\|FIXME" --include="*.nix" .
```

---

## 8. 相关文档

- `doc/ARCHITECTURE.md`：架构与编码规则
- `doc/OPTIMIZATION.md`：迁移记录与长期维护
- `doc/GUIDE.md`：设计参考
- `doc/AGENT.md`：AI agent 操作指引
