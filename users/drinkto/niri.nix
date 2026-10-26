# Niri 主会话配置。Niri 的键位使用 Mod = Super（Windows 键）。
# 该文件由 Home Manager 写入 ~/.config/niri/config.kdl；修改后重新 switch。
{
  config,
  pkgs,
  ...
}: let
  dms = "${config.programs.dank-material-shell.package}/bin/dms";
  ghostty = "${pkgs.ghostty}/bin/ghostty";
  kitty = "${pkgs.kitty}/bin/kitty";
in {
  xdg.configFile."niri/config.kdl".text = ''
    // Niri + DMS 入门配置。完整键位见 doc/NIRI.md。
    spawn-at-startup "${dms}" "run"

    prefer-no-csd

    input {
        keyboard {
            xkb {
                layout "us"
            }
            numlock
        }

        touchpad {
            tap
            natural-scroll
            dwt
        }

        mouse {
            accel-profile "adaptive"
        }
    }

    output "eDP-1" {
        scale 1.25
    }

    layout {
        gaps 12
        center-focused-column "on-overflow"

        preset-column-widths {
            proportion 0.33333
            proportion 0.5
            proportion 0.66667
        }

        default-column-width { proportion 0.5; }

        focus-ring {
            width 2
            active-color "#7fc8ff"
            inactive-color "#505050"
        }

        border {
            off
            width 2
            active-color "#7fc8ff"
            inactive-color "#303030"
        }
    }

    environment {
        NIXOS_OZONE_WL "1"
    }

    binds {
        // 用户要求的默认快捷键
        Mod+Return { spawn "${ghostty}"; }
        Mod+Shift+Return { spawn "${kitty}"; }
        Mod+D { spawn "${dms}" "ipc" "call" "spotlight" "toggle"; }
        Mod+Space { spawn "${dms}" "ipc" "call" "spotlight" "toggle"; }

        // 会话基础操作
        Mod+Q repeat=false { close-window; }
        Alt+F4 repeat=false { close-window; }
        Mod+Shift+Slash { show-hotkey-overlay; }
        Mod+Shift+E { quit; }

        // Overview：Win+O
        Mod+O { toggle-overview; }

        // 窗口/列操作
        Mod+Left { focus-column-left; }
        Mod+Right { focus-column-right; }
        Mod+Up { focus-window-up; }
        Mod+Down { focus-window-down; }
        Mod+H { focus-column-left; }
        Mod+L { focus-column-right; }
        Mod+K { focus-window-up; }
        Mod+J { focus-window-down; }

        Mod+Ctrl+Left { move-column-left; }
        Mod+Ctrl+Right { move-column-right; }
        Mod+Ctrl+Up { move-window-up; }
        Mod+Ctrl+Down { move-window-down; }
        Mod+Ctrl+H { move-column-left; }
        Mod+Ctrl+L { move-column-right; }
        Mod+Ctrl+K { move-window-up; }
        Mod+Ctrl+J { move-window-down; }

        Mod+F { maximize-column; }
        Mod+Shift+F { fullscreen-window; }
        Mod+V { toggle-window-floating; }
        Mod+W { toggle-column-tabbed-display; }
        Mod+R { switch-preset-column-width; }
        Mod+Shift+R { switch-preset-column-width-back; }
        Mod+C { center-column; }

        // 工作区
        Mod+1 { focus-workspace 1; }
        Mod+2 { focus-workspace 2; }
        Mod+3 { focus-workspace 3; }
        Mod+4 { focus-workspace 4; }
        Mod+5 { focus-workspace 5; }
        Mod+6 { focus-workspace 6; }
        Mod+7 { focus-workspace 7; }
        Mod+8 { focus-workspace 8; }
        Mod+9 { focus-workspace 9; }
        Mod+Ctrl+1 { move-column-to-workspace 1; }
        Mod+Ctrl+2 { move-column-to-workspace 2; }
        Mod+Ctrl+3 { move-column-to-workspace 3; }
        Mod+Ctrl+4 { move-column-to-workspace 4; }
        Mod+Ctrl+5 { move-column-to-workspace 5; }
        Mod+Ctrl+6 { move-column-to-workspace 6; }
        Mod+Ctrl+7 { move-column-to-workspace 7; }
        Mod+Ctrl+8 { move-column-to-workspace 8; }
        Mod+Ctrl+9 { move-column-to-workspace 9; }

        Mod+Page_Down { focus-workspace-down; }
        Mod+Page_Up { focus-workspace-up; }
        Mod+Ctrl+Page_Down { move-column-to-workspace-down; }
        Mod+Ctrl+Page_Up { move-column-to-workspace-up; }
        Mod+WheelScrollDown cooldown-ms=150 { focus-workspace-down; }
        Mod+WheelScrollUp cooldown-ms=150 { focus-workspace-up; }
        Mod+Ctrl+WheelScrollDown cooldown-ms=150 { move-column-to-workspace-down; }
        Mod+Ctrl+WheelScrollUp cooldown-ms=150 { move-column-to-workspace-up; }

        // DMS 常用入口
        Mod+X { spawn "${dms}" "ipc" "call" "powermenu" "toggle"; }
        Mod+N { spawn "${dms}" "ipc" "call" "notifications" "toggle"; }
        Mod+Alt+V { spawn "${dms}" "ipc" "call" "clipboard" "toggle"; }
        Super+Alt+L { spawn "${dms}" "ipc" "call" "lock" "lock"; }

        // 截图与输入
        Print { screenshot; }
        Ctrl+Print { screenshot-screen; }
        Alt+Print { screenshot-window; }
        Mod+Escape allow-inhibiting=false { toggle-keyboard-shortcuts-inhibit; }

        // 音量/亮度由 niri 直接调用系统工具
        XF86AudioRaiseVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1+" "-l" "1.0"; }
        XF86AudioLowerVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1-"; }
        XF86AudioMute allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
        XF86AudioMicMute allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"; }
    }
  '';
}
