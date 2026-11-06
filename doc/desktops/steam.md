# Steam gamescope 会话

Steam 会话是当前**始终启用**的第二个 SDDM 会话，和 KDE 并列；它不是
完整桌面，而是 gamescope + Steam Big Picture。

## 当前配置

```text
common/nixos/gaming.nix
  programs.steam.gamescopeSession.enable = true
  args = [ "-W" "1920" "-H" "1080" "-f" "-r" "60" ]
  env.MANGOHUD = "1"
```

SDDM 中显示为 **Steam**。默认会话仍是 Plasma。

## 使用流程

1. 先在 **Plasma** 里打开 Steam，完成登录、Steam Play/Proton、下载、
   手柄和界面设置。
2. 注销，SDDM 选择 **Steam**。
3. 进入 Big Picture 后启动游戏。
4. 游戏内按 `Shift_R+F12` 切换 MangoHud。
5. 退出：Steam 按钮 → 电源 → **退出 Steam**。

Steam 会话没有桌面环境；Big Picture 的“退出到桌面/切换到桌面”不会回到
Plasma。

## 无法退出时

按 `Ctrl+Alt+F2` 进入 TTY，登录后：

```bash
loginctl list-sessions
loginctl terminate-session <session-id>
```

或：

```bash
sudo systemctl restart display-manager
```

## Wi-Fi

Steam 会话没有 KDE Wallet/secret agent，NetworkManager 的 Wi-Fi PSK 必须是
系统级存储：

```bash
nmcli -g 802-11-wireless-security.psk-flags connection show '<Wi-Fi>'
nmcli connection modify '<Wi-Fi>' wifi-sec.psk-flags 0
nmcli connection up '<Wi-Fi>'
```

Steam Big Picture 的网络页可能只显示 HTTP proxy；只要系统网络已连接，
游戏下载/在线功能通常可用。

## 性能与画质

- `-W 1920 -H 1080 -f -r 60` 匹配 E490 屏幕；
- `MANGOHUD=1` 在游戏会话默认启用覆盖层；
- 如果 Steam UI 网页视图文字乱码，可在 Steam 设置关闭
  “GPU accelerated rendering in web views”，或在 `steamArgs` 加
  `-cef-disable-gpu`；
- 独显游戏可在启动项加：
  ```text
  DRI_PRIME=1 MESA_VK_DEVICE_SELECT=1002:699f PROTON_LOG=1 %command%
  ```

## 诊断

```bash
ls /run/current-system/sw/share/wayland-sessions/steam.desktop
pgrep -af 'steam|gamescope'
journalctl --user -b | grep -i -E 'steam|gamescope'
```

如果 Steam 会话不显示，重新 build/switch 并检查 SDDM 会话菜单。
