# NixOS 维护手册

> 面向本仓库的日常维护、上手操作和故障排查。
> 改配置前先读 `doc/ARCHITECTURE.md`；迁移历史见 `doc/OPTIMIZATION.md`。

---

## 1. 当前实例

| 项目 | 值 |
| :--- | :--- |
| 主机 | `e490`（Lenovo E490，i7-8565U，24G 内存） |
| 用户 | `drinkto` |
| 桌面 | KDE Plasma 6 + SDDM + X11 |
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

#### 常见问题：节点测速全 timeout，但 Android/flclash 正常

本次实际案例：

- 机场 profile 里有 `nameserver-policy`，对 `+.quandao.com` / `+.jiandaoyun.com`
  使用机场自己的 DoH 解析真实节点 IP。
- Clash Verge 的 `dns_config.yaml` 默认 `nameserver-policy: {}`，
  并用 `proxy-server-nameserver` 走 `doh.pub` / 阿里 DNS。
- 结果节点域名被解析到 `overdue.aliyun.com`（170.33.12.185），TCP 全部超时。
- 这不是机场节点失效；Android/flclash 使用 profile 自带 DNS 策略所以正常。

处理：

1. 从机场 profile 复制 `dns.nameserver-policy` 到
   `dns_config.yaml` 和 `profiles/Merge.yaml`。
2. 把 `proxy-server-nameserver` 改为机场提供的 DoH 列表。
3. 重启 Clash Verge，验证节点延迟和代理。

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
| **修改 DNS 设置/DNS 覆写** | **谨慎** | 可能重写 `dns_config.yaml`，丢失机场 `nameserver-policy`，导致节点解析失败 |

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

#### 安全

- `profiles.yaml`、机场订阅 URL、DoH token、代理密码都在用户目录，
  不能提交到 git，也不要贴到公开 issue。
- 备份应用配置时注意备份文件同样含敏感信息。

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
