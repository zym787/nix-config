# Hyprland 尝鲜配置：只提供最小可用键位，主会话仍是 niri。
{
  config,
  pkgs,
  ...
}: let
  dms = "${config.programs.dank-material-shell.package}/bin/dms";
  ghostty = "${pkgs.ghostty}/bin/ghostty";
  kitty = "${pkgs.kitty}/bin/kitty";
in {
  xdg.configFile."hypr/hyprland.conf".text = ''
    monitor=,preferred,auto,1
    exec-once = ${dms} run

    $mod = SUPER

    bind = $mod, Return, exec, ${ghostty}
    bind = $mod SHIFT, Return, exec, ${kitty}
    bind = $mod, D, exec, ${dms} ipc call spotlight toggle
    bind = $mod, Q, killactive,
    bind = $mod, M, exit,
    bind = $mod, V, togglefloating,
    bind = $mod, F, fullscreen, 0
    bind = $mod SHIFT, F, fullscreen, 1

    bind = $mod, left, movefocus, l
    bind = $mod, right, movefocus, r
    bind = $mod, up, movefocus, u
    bind = $mod, down, movefocus, d
    bind = $mod SHIFT, left, movewindow, l
    bind = $mod SHIFT, right, movewindow, r
    bind = $mod SHIFT, up, movewindow, u
    bind = $mod SHIFT, down, movewindow, d

    bind = $mod, 1, workspace, 1
    bind = $mod, 2, workspace, 2
    bind = $mod, 3, workspace, 3
    bind = $mod, 4, workspace, 4
    bind = $mod, 5, workspace, 5
    bind = $mod SHIFT, 1, movetoworkspace, 1
    bind = $mod SHIFT, 2, movetoworkspace, 2
    bind = $mod SHIFT, 3, movetoworkspace, 3
    bind = $mod SHIFT, 4, movetoworkspace, 4
    bind = $mod SHIFT, 5, movetoworkspace, 5

    bind = $mod, X, exec, ${dms} ipc call powermenu toggle
    bind = $mod, N, exec, ${dms} ipc call notifications toggle
    bind = $mod ALT, V, exec, ${dms} ipc call clipboard toggle
  '';
}
